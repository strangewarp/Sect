return {
	
	-- Load the current active savefile in the hotseats list
	loadFile = function(data, undo)

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

			-- Set the new insert-point
			local inpoint = data.active + (tracknum - 1)

			local outtab = {}

			data:addSequence(inpoint, undo) -- Add a sequence in the new insert-position, and send an undo-task accordingly
			undo[2] = true -- After the first undo-task, chain all subsequent undo-tasks into the same step

			-- Read every note in a given track, and insert them into the corresponding new sequence
			for k, v in pairs(track) do

				local newnotes = {}

				if v[1] == "end_track" then
					data:extendSeqTable(inpoint, v[2] + 1, 1, undo)
				elseif v[1] == "track_name" then
					print("loadFile: Track name: " .. v[3])
				elseif data.acceptmidi[v[1]] then
					data:extendSeqTable(inpoint, v[2] + 1, 1, undo)
					table.insert(newnotes, {tick = v[2] + 1, note = v})
				else
					print("loadFile: Discarded unsupported command: " .. v[1])
				end

				data:addNotes(inpoint, newnotes, {true, undo[2], undo[3]})

			end

			print("loadFile: loaded track " .. tracknum .. " into sequence " .. inpoint .. " :: " .. #data.seq[inpoint].tick .. " ticks")

		end

		print("loadFile: loaded MIDI file \"" .. data.hotseats[data.activeseat] .. "\"!")

	end,

	-- Save to the current active hotseat location
	saveFile = function(data)

		-- Get save location
		local saveloc = data.savepath .. data.hotseats[data.activeseat] .. ".mid"
		print("saveFile: Now saving: " .. saveloc)

		local score = {}

		-- For every sequence, translate it to a valid score track
		for tracknum, track in ipairs(data.seq) do
			score[tracknum] = { {'end_track', #track - 1}, } -- For a given track, insert an accurate end_track command
			for tick, notes in pairs(track) do -- Copy over all notes to the score-track-table
				for k, v in pairs(notes) do
					table.insert(score[tracknum], v.note)
				end
			end
			print("saveFile: copied sequence " .. tracknum .. " to save-table!")
		end

		-- Insert tempo information in the first track, and the TPQ value in the first score-table entry, as per MIDI.lua spec
		local outbpm = 60000000 / data.bpm
		table.insert(score[1], 1, {'set_tempo', 0, outbpm})
		table.insert(score[1], 2, {'time_signature', 0, 4, 4, data.tpq, 8})
		table.insert(score, 1, data.tpq)
		print("saveFile: BPM " .. outbpm .. " :: TPQ " .. data.tpq)

		-- Save the score into a MIDI file within the savefolder
		local midifile = assert(io.open(saveloc, 'w'))
		midifile:write(MIDI.score2midi(score))
		midifile:close()

		print("saveFile: saved " .. (#score - 1) .. " sequences to file \"" .. saveloc .. "\"!")

	end,

}