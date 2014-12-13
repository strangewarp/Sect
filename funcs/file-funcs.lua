
return {

	-- Serialize a simple table of arbitrary depth (not metatable compatible)
	serializeTable = function(t, filename, f, height)

		height = height or 0

		if height == 0 then
			f, _ = love.filesystem.newFile(filename)
			f:open('w')
			f:write("\r\nreturn {\r\n")
		end

		height = height + 1

		for k, v in pairs(t) do

			local tabs = string.rep("\t", height)

			if type(k) == "number" then
				--f:write(tabs .. "[" .. k .. "] = ")
				f:write(tabs)
			else
				f:write(tabs .. "[\"" .. k .. "\"] = ")
			end

			if type(v) == "table" then
				f:write("{\r\n")
				serializeTable(v, filename, f, height)
				f:write(tabs .. "},\r\n")
			elseif type(v) == "string" then
				f:write("\"" .. v .. "\",\r\n")
			else
				f:write(tostring(v) .. ",\r\n")
			end

		end

		if height == 1 then
			f:write("}\r\n")
			f:close()
		end

	end,

	-- Load the scale and wheel files
	loadScalesAndWheels = function()
		D.scales = require('scales')
		D.wheels = require('wheels')
	end,

	-- Save the scale and wheel tables
	saveScalesAndWheels = function()
		serializeTable(D.scales, "scales.lua")
		serializeTable(D.wheels, "wheels.lua")
	end,

	-- Load the current active savefile in the hotseats list
	loadFile = function(filename, add, undo)

		-- If the save-directory doesn't exist, abort function
		if not D.saveok then
			return nil
		end

		-- If no filename was given, use the current hotseat filename
		if not filename then
			filename = D.hotseats[D.activeseat]
		end

		local bpm, tpq = false, false
		local undotasks = {}

		local saveloc = D.savepath .. filename .. ".mid"
		print("loadFile: Now loading: " .. saveloc)

		-- Try to open the MIDI file
		local midifile = io.open(saveloc, 'r')
		if midifile == nil then
			print("loadFile error: file does not exist!")
			return nil
		end
		local rawmidi = midifile:read('*all')
		midifile:close()

		-- If this isn't an additive-load, unset all currently existing seqs
		if add == false then
			while D.active do
				removeActiveSequence(undo)
			end
		end

		-- Get the score, stats, and TPQ
		local score = MIDI.midi2score(rawmidi)
		local stats = MIDI.score2stats(score)
		tpq = table.remove(score, 1)

		-- Set the active-sequence pointer to the new seq's location
		D.active = ((D.active ~= false) and (D.active + 1)) or 1

		-- Read every track in the MIDI file's score table
		for tracknum, track in ipairs(score) do

			local newnotes, newcmds = {}, {}
			local cmdcount = {}
			local endpoint = 0
			local inseq = D.active + (tracknum - 1)

			-- Add a sequence in the new insert-position, and send an undo-task accordingly
			addSequence(inseq, undo)

			-- Get new sequence's default length
			local newseqlen = D.seq[inseq].total

			-- Read every note in a given track, and prepare known commands for insertion
			for k, v in pairs(track) do

				-- Receive known commands, and change endpoint in incoming-notes accordingly
				if v[1] == 'end_track' then
					print("loadFile: End track: " .. v[2])
				elseif v[1] == 'track_name' then
					print("loadFile: Track name: " .. v[3])
				elseif v[1] == 'text_event' then
					print("loadFile: Text-event: " .. v[3])
				elseif v[1] == 'set_tempo' then
					bpm = 60000000 / v[3]
				elseif D.acceptmidi[v[1]] then
					if v[1] == 'note' then -- Extend note by tick + dur
						endpoint = math.max(endpoint, v[2] + v[3])
						table.insert(newnotes, {'insert', v})
					else
						cmdcount[v[2]] = (cmdcount[v[2]] and (cmdcount[v[2]] + 1)) or 1
						table.insert(newcmds, {'insert', cmdcount[v[2]], v})
						print(cmdcount[v[2]])--debugging
					end
				else
					print("loadFile: Discarded unsupported command: " .. v[1])
				end

				-- Get the position of the last tick in the sequence,
				-- which ought to be represented by a text_event,
				-- which itself is an automatic replacement for end_track.
				endpoint = math.max(endpoint, v[2])

			end

			-- If default seq length is less than endpoint, insert ticks
			if newseqlen < endpoint then
				insertTicks(inseq, newseqlen, endpoint - newseqlen, undo)
			end

			-- Insert all known commands into the new sequence
			setNotes(inseq, newnotes, undo)
			newcmds = cmdsToSetType(newcmds, 'insert')
			setCmds(inseq, newcmds, undo)

			print("loadFile: loaded track " .. tracknum .. " into sequence " .. inseq .. " :: " .. D.seq[inseq].total .. " ticks")

		end

		-- Set global BPM and TPQ to latest BPM/TPQ values
		D.bpm = roundNum(bpm, 0)
		D.tpq = tpq

		-- Move to the first note in the first loaded sequence
		D.tp = 1
		D.np = D.bounds.np[2]
		local checkpoint = getNotes(D.active, D.tp, D.tp, D.np, D.np)
		if #checkpoint == 0 then
			moveTickPointerByNote(1)
		end

		print("loadFile: loaded MIDI file \"" .. D.hotseats[D.activeseat] .. "\"!")

		-- If in Saveload Mode, untoggle said mode
		if D.cmdmode == "saveload" then
			toggleSaveLoad()
		end

		-- Update the hotseats list with the filename
		updateHotseats(filename)

	end,

	-- Save to the current active hotseat location
	saveFile = function(filename)

		-- If the save-directory doesn't exist, abort function
		if not D.saveok then
			return nil
		end

		-- If no filename was given, use the current hotseat filename
		if not filename then
			filename = D.hotseats[D.activeseat]
		end

		local score = {}

		-- Get save location
		local shortname = filename .. ".mid"
		local saveloc = D.savepath .. shortname
		print("saveFile: Now saving: " .. saveloc)

		-- For every sequence, translate it to a valid score track
		for tracknum, track in ipairs(D.seq) do

			-- Copy over all notes and cmds to the score-track-table
			local cmdtrack = getContents(track, {'tick', pairs, 'cmd', pairs})
			local notetrack = getContents(track, {'tick', pairs, 'note', pairs, pairs})
			score[tracknum] = tableCombine(cmdtrack, notetrack)

			-- Insert an end_track command, so MIDI.lua knows how long the sequence is.
			table.insert(score[tracknum], {'end_track', track.total})

			print("saveFile: copied sequence " .. tracknum .. " to save-table. " .. #score[tracknum] .. " items!")

		end

		-- Insert tempo information in the first track,
		-- and the TPQ value in the first score-table entry, as per MIDI.lua spec.
		local outbpm = 60000000 / D.bpm
		table.insert(score, 1, D.tpq)
		table.insert(score[2], 1, {'time_signature', 0, 4, 4, D.tpq, 8})
		table.insert(score[2], 2, {'set_tempo', 0, outbpm})
		print("saveFile: BPM " .. D.bpm .. " :: TPQ " .. D.tpq .. " :: uSPQ " .. outbpm)

		-- Save the score into a MIDI file within the savefolder
		local midifile = io.open(saveloc, 'w')
		if midifile == nil then
			D.savepopup = true
			D.savedegrade = 90
			D.savemsg = "Could not save file! Filename contains invalid characters!"
			return nil
		end
		midifile:write(MIDI.score2midi(score))
		midifile:close()

		-- Toggle the rendering-flag, and set rendering info, for a visual save confirmation
		D.savepopup = true
		D.savedegrade = 90
		D.savemsg = "Saved " .. (#score - 1) .. " track" .. (((#score ~= 2) and "s") or "") .. " to file: " .. shortname

		print("saveFile: saved " .. (#score - 1) .. " sequences to file \"" .. saveloc .. "\"!")

		-- If in Saveload Mode, untoggle said mode
		if D.cmdmode == "saveload" then
			toggleSaveLoad()
		end

		-- Update the hotseats list with the filename
		updateHotseats(filename)

	end,

	-- Update the hotseats list with a new filename
	updateHotseats = function(name)

		local limit = #D.hotseats

		for k, v in pairs(D.hotseats) do
			if v == name then
				table.remove(D.hotseats, k)
				break
			end
		end

		table.insert(D.hotseats, 1, name)

		while #D.hotseats > limit do
			table.remove(D.hotseats, limit + 1)
		end

		D.activeseat = 1

	end,

	-- Load a file with a user-entered string from Saveload Mode
	loadSLStringFile = function(add, undo)
		if D.savestring:len() > 0 then
			loadFile(D.savestring, add, undo)
		end
	end,

	-- Save a file with a user-entered string from Saveload Mode
	saveSLStringFile = function()
		if D.savestring:len() > 0 then
			saveFile(D.savestring)
		end
	end,

	-- Add a text-character to the savefile-string in Saveload Mode
	addSaveChar = function(t)

		local slen = #D.savestring
		local left = ((D.sfsp > 0) and D.savestring:sub(1, D.sfsp)) or ""
		local right = ((D.sfsp < slen) and D.savestring:sub(D.sfsp + 1, slen)) or ""

		D.savestring = left .. t .. right

		D.sfsp = math.min(D.sfsp + 1, #D.savestring)

		checkUserSaveFile()

	end,

	-- Remove a text-character from the savefile-string in Saveload Mode
	removeSaveChar = function(offset)

		local rpoint = D.sfsp + offset + 1

		if offset > 0 then
			rpoint = rpoint - 1
		end

		local slen = #D.savestring

		local left = ((rpoint > 1) and D.savestring:sub(1, rpoint - 1)) or ""
		local right = ((rpoint < slen) and D.savestring:sub(rpoint + 1, slen)) or ""

		D.savestring = left .. right

		if slen > #D.savestring then
			D.sfsp = rpoint - 1
		end

		checkUserSaveFile()

	end,

	-- Move the savefile-string pointer location
	moveSavePointer = function(dir)
		D.sfsp = wrapNum(D.sfsp + dir, 0, D.savestring:len())
	end,

	-- Check the file-validity of the current savestring entry
	checkUserSaveFile = function()

		if D.savestring:len() == 0 then
			D.savevalid = false
		end

		local d = io.open(D.savepath)

		local f = io.open(D.savepath .. D.savestring .. ".mid", 'r')
		if f == nil then
			D.savevalid = false
		else
			D.savevalid = true
			f:close()
		end

	end,

	-- Check the path-validity of the current savestring entry
	checkUserSavePath = function()

		if D.savepath:sub(-1) ~= "/" then
			D.savepath = D.savepath .. "/"
		end

		-- Check whether the savepath exists by opening a dummy file.
		-- If savepath doesn't exist, disable saving.
		-- Else, if savepath exists, enable saving, and delete dummy file.
		local savetestfile = D.savepath .. "sect_filepath_test.txt"
		local pathf = io.open(savetestfile, "w")
		if pathf == nil then
			D.saveok = false
		else
			D.saveok = true
			pathf:close()
			os.remove(savetestfile)
		end

	end,

	-- Set the current savepath to a user-entered string, from Saveload Mode,
	-- and update and save all preferences.
	setUserSavePath = function()

		-- If savestring is empty, abort function
		if #D.savestring == 0 then
			return nil
		end

		D.savepath = D.savestring
		prefs.savepath = D.savestring

		D.savestring = ""

		checkUserSavePath()

		D.savepopup = true
		D.savedegrade = 90
		D.savemsg = "Savepath set! Folder exists!"
		if not D.saveok then
			D.savemsg = "Savepath set! Warning: Folder does not exist!"
		end

		serializeTable(prefs, "userprefs.lua")

	end,

}
