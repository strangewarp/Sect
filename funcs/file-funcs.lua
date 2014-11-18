
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
				f:write(tabs .. "[" .. k .. "] = ")
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
				f:write(v .. ",\r\n")
			end

		end

		if height == 1 then
			f:write("}\r\n")
			f:close()
		end

	end,

	-- Load the scale and wheel files
	loadScalesAndWheels = function()
		data.scales = require('scales')
		data.wheels = require('wheels')
	end,

	-- Save the scale and wheel tables
	saveScalesAndWheels = function()
		serializeTable(data.scales, "scales.lua")
		serializeTable(data.wheels, "wheels.lua")
	end,

	-- Load the current active savefile in the hotseats list
	loadFile = function(filename, add, undo)

		-- If the save-directory doesn't exist, abort function
		if not data.saveok then
			return nil
		end

		-- If no filename was given, use the current hotseat filename
		if not filename then
			filename = data.hotseats[data.activeseat]
		end

		local bpm, tpq = false, false
		local undotasks = {}

		local saveloc = data.savepath .. filename .. ".mid"
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
			while data.active do
				removeActiveSequence(undo)
			end
		end

		-- Get the score, stats, and TPQ
		local score = MIDI.midi2score(rawmidi)
		local stats = MIDI.score2stats(score)
		tpq = table.remove(score, 1)

		-- Set the active-sequence pointer to the new seq's location
		data.active = ((data.active ~= false) and (data.active + 1)) or 1

		-- Read every track in the MIDI file's score table
		for tracknum, track in ipairs(score) do

			local newnotes, newcmds = {}, {}
			local cmdcount = {}
			local endpoint = 0
			local inseq = data.active + (tracknum - 1)

			-- Add a sequence in the new insert-position, and send an undo-task accordingly
			addSequence(inseq, undo)

			-- Get new sequence's default length
			local newseqlen = data.seq[inseq].total

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
				elseif data.acceptmidi[v[1]] then
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

			print("loadFile: loaded track " .. tracknum .. " into sequence " .. inseq .. " :: " .. data.seq[inseq].total .. " ticks")

		end

		-- Set global BPM and TPQ to latest BPM/TPQ values
		data.bpm = roundNum(bpm, 0)
		data.tpq = tpq

		-- Move to the first note in the first loaded sequence
		data.tp = 1
		data.np = data.bounds.np[2]
		local checkpoint = getNotes(data.active, data.tp, data.tp, data.np, data.np)
		if #checkpoint == 0 then
			moveTickPointerByNote(1)
		end

		print("loadFile: loaded MIDI file \"" .. data.hotseats[data.activeseat] .. "\"!")

		-- If in Saveload Mode, untoggle said mode
		if data.cmdmode == "saveload" then
			toggleSaveLoad()
		end

		-- Update the hotseats list with the filename
		updateHotseats(filename)

	end,

	-- Save to the current active hotseat location
	saveFile = function(filename)

		-- If the save-directory doesn't exist, abort function
		if not data.saveok then
			return nil
		end

		-- If no filename was given, use the current hotseat filename
		if not filename then
			filename = data.hotseats[data.activeseat]
		end

		local score = {}

		-- Get save location
		local shortname = filename .. ".mid"
		local saveloc = data.savepath .. shortname
		print("saveFile: Now saving: " .. saveloc)

		-- For every sequence, translate it to a valid score track
		for tracknum, track in ipairs(data.seq) do

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
		local outbpm = 60000000 / data.bpm
		table.insert(score, 1, data.tpq)
		table.insert(score[2], 1, {'time_signature', 0, 4, 4, data.tpq, 8})
		table.insert(score[2], 2, {'set_tempo', 0, outbpm})
		print("saveFile: BPM " .. data.bpm .. " :: TPQ " .. data.tpq .. " :: uSPQ " .. outbpm)

		-- Save the score into a MIDI file within the savefolder
		local midifile = io.open(saveloc, 'w')
		if midifile == nil then
			data.savepopup = true
			data.savedegrade = 90
			data.savemsg = "Could not save file! Filename contains invalid characters!"
			return nil
		end
		midifile:write(MIDI.score2midi(score))
		midifile:close()

		-- Toggle the rendering-flag, and set rendering info, for a visual save confirmation
		data.savepopup = true
		data.savedegrade = 90
		data.savemsg = "Saved " .. (#score - 1) .. " track" .. (((#score ~= 2) and "s") or "") .. " to file: " .. shortname

		print("saveFile: saved " .. (#score - 1) .. " sequences to file \"" .. saveloc .. "\"!")

		-- If in Saveload Mode, untoggle said mode
		if data.cmdmode == "saveload" then
			toggleSaveLoad()
		end

		-- Update the hotseats list with the filename
		updateHotseats(filename)

	end,

	-- Update the hotseats list with a new filename
	updateHotseats = function(name)

		local limit = #data.hotseats

		for k, v in pairs(data.hotseats) do
			if v == name then
				table.remove(data.hotseats, k)
				break
			end
		end

		table.insert(data.hotseats, 1, name)

		while #data.hotseats > limit do
			table.remove(data.hotseats, limit + 1)
		end

	end,

	-- Load a file with a user-entered string from Saveload Mode
	loadSLStringFile = function(undo)
		if data.savestring:len() > 0 then
			loadFile(data.savestring, add, undo)
		end
	end,

	-- Save a file with a user-entered string from Saveload Mode
	saveSLStringFile = function()
		if data.savestring:len() > 0 then
			saveFile(data.savestring)
		end
	end,

	-- Add a text-character to the savefile-string in Saveload Mode
	addSaveChar = function(t)

		local slen = #data.savestring
		local left = ((data.sfsp > 0) and data.savestring:sub(1, data.sfsp)) or ""
		local right = ((data.sfsp < slen) and data.savestring:sub(data.sfsp + 1, slen)) or ""

		data.savestring = left .. t .. right

		data.sfsp = math.min(data.sfsp + 1, #data.savestring)

		checkUserSaveEntry()

	end,

	-- Remove a text-character from the savefile-string in Saveload Mode
	removeSaveChar = function(offset)

		local rpoint = data.sfsp + offset + 1

		if offset > 0 then
			rpoint = rpoint - 1
		end

		local slen = #data.savestring

		local left = ((rpoint > 1) and data.savestring:sub(1, rpoint - 1)) or ""
		local right = ((rpoint < slen) and data.savestring:sub(rpoint + 1, slen)) or ""

		data.savestring = left .. right

		if slen > #data.savestring then
			data.sfsp = rpoint - 1
		end

		checkUserSaveEntry()

	end,

	-- Move the savefile-string pointer location
	moveSavePointer = function(dir)
		data.sfsp = wrapNum(data.sfsp + dir, 0, data.savestring:len())
	end,

	-- Check the validity of the current savestring entry
	checkUserSaveEntry = function()

		if data.savestring:len() == 0 then
			data.savevalid = false
		end

		local f = io.open(data.savepath .. data.savestring .. ".mid", 'r')
		if f == nil then
			data.savevalid = false
		else
			data.savevalid = true
			f:close()
		end

	end,

}
