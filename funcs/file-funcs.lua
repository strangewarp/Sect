
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
	loadFile = function(undo)

		local bpm, tpq = false, false
		local undotasks = {}

		local saveloc = data.savepath .. data.hotseats[data.activeseat] .. ".mid"
		print("loadFile: Now loading: " .. saveloc)

		-- Try to open the MIDI file
		local midifile = io.open(saveloc, 'r')
		if midifile == nil then
			print("loadFile error: file does not exist!")
			return nil
		end
		local rawmidi = midifile:read('*all')
		midifile:close()

		-- Get the score, stats, and TPQ
		local score = MIDI.midi2score(rawmidi)
		local stats = MIDI.score2stats(score)
		tpq = table.remove(score, 1)

		data.active = ((data.active ~= false) and (data.active + 1)) or 1

		-- Read every track in the MIDI file's score table
		for tracknum, track in ipairs(score) do

			local newnotes = {}
			local endpoint = 0
			local inseq = data.active + (tracknum - 1)

			-- Add a sequence in the new insert-position, and send an undo-task accordingly
			addSequence(inseq, undo)

			-- Get new sequence's default length
			local newseqlen = #data.seq[inseq].tick

			-- Read every note in a given track, and prepare known commands for insertion
			for k, v in pairs(track) do

				-- Receive known commands, and change endpoint in incoming-notes accordingly
				if v[1] == "end_track" then
					endpoint = v[2]
				elseif v[1] == "track_name" then
					print("loadFile: Track name: " .. v[3])
				elseif v[1] == "set_tempo" then
					bpm = 60000000 / v[3]
				elseif data.acceptmidi[v[1]] then
					print("dur " .. v[3]) -- DEBUGGING
					endpoint = math.max(endpoint, v[2])
					table.insert(newnotes, {tick = v[2] + 1, note = v})
				else
					print("loadFile: Discarded unsupported command: " .. v[1])
				end

			end

			-- Shift endpoint from 0-indexing to 1-indexing
			endpoint = endpoint + 1

			-- If default seq length is less than endpoint, insert ticks
			if newseqlen < endpoint then
				insertTicks(inseq, newseqlen, endpoint - newseqlen, undo)
			end

			-- Insert all known commands into the new sequence
			setNotes(inseq, newnotes, undo)

			print("loadFile: loaded track " .. tracknum .. " into sequence " .. inseq .. " :: " .. #data.seq[inseq].tick .. " ticks")

		end

		-- Set global BPM and TPQ to latest BPM/TPQ values
		data.bpm = bpm
		data.tpq = tpq

		print("loadFile: loaded MIDI file \"" .. data.hotseats[data.activeseat] .. "\"!")

	end,

	-- Save to the current active hotseat location
	saveFile = function()

		local score = {}

		-- Get save location
		local saveloc = data.savepath .. data.hotseats[data.activeseat] .. ".mid"
		print("saveFile: Now saving: " .. saveloc)

		-- For every sequence, translate it to a valid score track
		for tracknum, track in ipairs(data.seq) do
			score[tracknum] = { {'end_track', #track.tick - 1}, } -- For a given track, insert an accurate end_track command
			for tick, notes in pairs(track.tick) do -- Copy over all notes to the score-track-table
				for k, v in pairs(notes) do
					table.insert(score[tracknum], v.note)
				end
			end
			print("saveFile: copied sequence " .. tracknum .. " to save-table!")
		end

		-- Insert tempo information in the first track,
		-- and the TPQ value in the first score-table entry, as per MIDI.lua spec.
		local outbpm = 60000000 / data.bpm
		table.insert(score, 1, data.tpq)
		table.insert(score[2], 1, {'time_signature', 0, 4, 4, data.tpq, 8})
		table.insert(score[2], 2, {'set_tempo', 0, outbpm})
		print("saveFile: BPM " .. data.bpm .. " :: TPQ " .. data.tpq .. " :: uSPQ " .. outbpm)

		-- Save the score into a MIDI file within the savefolder
		local midifile = assert(io.open(saveloc, 'w'))
		midifile:write(MIDI.score2midi(score))
		midifile:close()

		print("saveFile: saved " .. (#score - 1) .. " sequences to file \"" .. saveloc .. "\"!")

	end,

}
