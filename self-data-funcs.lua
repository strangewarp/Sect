return {
	
	-- Insert a given table of timestamped notes into a given sequence
	addNotes = function(data, p, notes, undo)

		local undonotes = {}
		local collidenotes = {}
		local maxpos = 1
		local oldlen = #data.seq[p].tick

		-- Convert naked single-note-tables into the proper table format for the iterators
		if (notes.tick ~= nil) and (notes.note ~= nil) then
			notes = {notes}
		end

		-- Find the largest position-index among the inserted notes
		for k, v in pairs(notes) do
			if v.tick > maxpos then
				maxpos = v.tick
			end
		end

		-- If the sequence isn't long enough, extend its data-table
		if maxpos > #data.seq[p].tick then
			data:extendSeqTable(p, maxpos, 1, undo) -- This will cascade into setting a corresponding undo-state automatically, mind
			undo[2] = true
		end

		for k, v in ipairs(notes) do -- For every incoming note...

			-- Check all notes in the tick against this note, and remove note-collisions, adding them to the collide-table
			for notenum, n in ipairs(data.seq[p].tick[v.tick]) do
				if crossCompare(v.note, n.note) then
					table.insert(collidenotes, deepCopy(n))
					table.remove(data.seq[p].tick[v.tick], notenum)
					print("addNotes: removed colliding note: " .. table.concat(collidenotes[#collidenotes].note, " "))
					break
				end
			end

			-- Insert notes into the sequence-table, and insert corresponding removal-data into a temp undo-notes-table
			local vout = deepCopy(v)
			table.insert(data.seq[p].tick[v.tick], vout)
			table.insert(undonotes, vout)
			print("addNotes: added note: " .. table.concat(vout.note, " "))

		end

		-- Create and store undo-table data that is a reversal of what this function has done
		if #collidenotes > 0 then -- If any colliding notes were removed, add them back, but only after removing the notes that were just added
			data:addMetaUndoTask("addNotes", p, collidenotes, undo)
			undo[2] = true
		end
		data:addMetaUndoTask("removeNotes", p, undonotes, undo)

	end,

	-- Remove a series of timestamped, order-stamped notes from a given sequence
	removeNotes = function(data, p, notes, undo)

		local undonotes = {}

		-- Convert naked single-note-tables into the proper table format for the iterator
		if (notes.tick ~= nil) and (notes.note ~= nil) then
			notes = {notes}
		end

		-- Remove matching notes from the sequence-table, and insert corresponding addition-data into a temporary undo-table
		for k, v in ipairs(notes) do
			for notenum, n in pairs(data.seq[p].tick[v.tick]) do
				if crossCompare(n.note, v.note) then
					local oldnote = table.remove(data.seq[p].tick[v.tick], notenum)
					table.insert(undonotes, oldnote)
					print("removeNotes: removed note (" .. table.concat(oldnote.note, " ") .. ") at tick (" .. oldnote.tick .. ")")
					break
				end
			end
		end

		-- Create and store undo-table data that is a reversal of what this function has done
		data:addMetaUndoTask("addNotes", p, undonotes, undo)

	end,

	-- Insert the current note, with the current note-var settings
	insertNote = function(data, undo)

		-- If no sequences are loaded, abort function
		if data.active == false then
			print("insertNote: warning: no active sequence!")
			return nil
		end

		local n = {
			tick = data.tp, -- 1-indexed tick start-time
			note = {
				'note', -- MIDI.lua item command
				data.tp - 1, -- 0-indexed tick start-time
				data.dur, -- Duration (ticks)
				data.chan, -- Channel
				data.np, -- Pitch
				data.velo, -- Velocity
			},
		}

		data:addNotes(data.active, {n}, undo)

	end,

	-- Delete the note at the current pointer position
	deleteNote = function(data, undo)

		local delnotes = {}

		-- Search for items whose Y-axis bytes match the note-pointer
		for k, v in pairs(data.seq[data.active].tick[data.tp]) do
			if ((v.note[1] == "note") and (v.note[5] == data.np))
			or ((v.note[1] ~= "note") and (v.note[4] == data.np))
			then
				table.insert(delnotes, v)
			end
		end

		if #delnotes > 0 then
			data:removeNotes(data.active, delnotes, undo)
		end

	end,

	-- Delete all notes in the active tick
	deleteTickNotes = function(data, undo)

		local delnotes = {}
		for k, v in pairs(data.seq[data.active].tick[data.tp]) do
			table.insert(delnotes, v)
		end

		if #delnotes > 0 then
			data:removeNotes(data.active, delnotes, undo)
		end

	end,

	-- Delete all notes in the active beat
	deleteBeatNotes = function(data, undo)

		local delnotes = {}

		-- Find the beginning and end of the current beat
		local ltick = data.tp
		while wrapNum(ltick, 1, data.tpq * 4) ~= 1 do
			ltick = ltick - 1
		end
		local rtick = math.min(#data.seq[data.active].tick, (ltick + (data.tpq * 4)) - 1)

		-- Gather all notes from the beat, and put them in a delete-table
		for i = ltick, rtick do
			for k, v in pairs(data.seq[data.active].tick[i]) do
				table.insert(delnotes, v)
			end
		end

		if #delnotes > 0 then
			data:removeNotes(data.active, delnotes, undo)
		end

		data:normalizePointers()

	end,

	-- Add a new sequence to the sequence-table at the current seq-pointer
	addSequence = function(data, seq, undo)

		local newseq = deepCopy(data.baseseq)

		-- Add dummy-ticks to the sequence, to prevent errors
		for i = 1, data.tpq * 4 do
			newseq.tick[i] = {}
		end

		-- If no sequences exist, set the active pointer and insert-point to 1
		if data.active == false then
			data.active = 1
			seq = 1
		end

		-- Insert the new sequence
		table.insert(data.seq, seq, newseq)
		print("addSequence: added new sequence at position " .. seq)

		-- Normalize all pointers
		data:normalizePointers()

		-- Create and store undo-table data that is a reversal of what this function has done
		data:addMetaUndoTask("removeSequence", seq, undo)

	end,

	-- Remove a sequence from the sequence-table at the current active-sequence pointer
	removeSequence = function(data, seq, undo)

		local undonotes = {}

		-- If the seq-pointer is false or nil, or outside of the loaded sequences, then abort function
		if not seq then
			print("removeSequence: could not remove sequence: invalid seq pointer!")
			return nil
		elseif seq > #data.seq then
			print("removeSequence: could not remove sequence: sequence pointer outside of loaded seqs!")
			return nil
		end

		if #data.seq == 1 then -- If only one sequence remains, set the active pointer to false, to signify that none exist
			data.active = false
		elseif (seq == data.active) and (seq == #data.seq) then -- If the highest sequence is being removed, and is active, then move the activity pointer downward
			data.active = data.active - 1
		end

		-- Gather all notes from the sequence into an undo-table
		for ticknum, tick in ipairs(data.seq[seq].tick) do
			for notenum, note in pairs(tick) do
				table.insert(undonotes, note)
			end
		end

		-- Remove the sequence from the seqs-table
		table.remove(data.seq, seq)
		print("removeSequence: removed sequence from position " .. seq)

		-- Create and store undo-table data that is a reversal of what this function has done
		data:addMetaUndoTask("addSequence", seq, undo)
		data:addMetaUndoTask("addNotes", oldpoint, undonotes, {true, true, undo[3]})

	end,

	-- Add a new sequence at the active sequence-location
	addActiveSequence = function(data, undo)
		data:addSequence(data.active, undo)
	end,

	-- Remove the currently active sequence
	removeActiveSequence = function(data, undo)
		data:removeSequence(data.active, undo)
	end,

	-- Clear all notes and events from within a sequence
	clearSequence = function(data, p, undo)

		local notes = {}

		-- Gather all notes in the sequence
		for i = 1, #data.seq[p].tick do
			for k, v in ipairs(data.seq[p].tick[i]) do
				table.insert(notes, {note = v.note, tick = i})
			end
		end

		-- Send the table of gathered notes to removeNotes, passing down undo responsibility
		data:removeNotes(p, notes, undo)

	end,

	-- Extend a table's size to a given numeric index, by adding empty tick-tables to either its beginning or its end
	extendSeqTable = function(data, p, length, side, undo)

		local oldlen = #data.seq[p]

		-- Insert new tick-tables up to the new limit
		while #data.seq[p] < length do
			local insertpoint = ((side == 1) and (#data.seq[p] + 1)) or 1
			table.insert(data.seq[p], insertpoint, {})
		end

		print("extendSeqTable: extended sequence " .. p .. " from " .. oldlen .. " to " .. #data.seq[p])

		-- Create and store undo-table data that is a reversal of what this function has done
		data:addMetaUndoTask("shrinkSeqTable", p, oldlen, side, undo)

	end,

	-- Reduce a table's size to a given numeric index, by removing tick-tables from either its beginning or its end
	shrinkSeqTable = function(data, p, length, side, undo)

		local undonotes = {}
		local oldlen = #data.seq[p]

		local icount = 1
		-- Iterate through all ticks that are to be removed, on a given side of the table
		while #data.seq[p] > length do

			-- Set the removal point, and infer the pre-removal index number
			local removepoint = ((side == 1) and #data.seq[p]) or 1
			local oldindex = ((side == 1) and removepoint) or icount

			-- Put all to-be-removed notes into the undonotes table, and remove the tick tables that lay beyond the new length
			if next(data.seq[p][removepoint]) ~= nil then
				for k, v in ipairs(data.seq[p][removepoint]) do
					table.insert(undonotes, {note = v.note, tick = oldindex})
				end
				table.remove(data.seq[p], removepoint)
			end

			icount = icount + 1

		end

		print("shrinkSeqTable: shrank sequence " .. p .. " from " .. oldlen .. " to " .. #data.seq[p])

		-- Create and store undo-table data that is a reversal of what this function has done
		data:addMetaUndoTask("extendSeqTable", p, oldlen, side, undo)
		data:addMetaUndoTask("addNotes", p, undonotes, {true, true, undo[3]})

	end,

	-- Shift a sequence into an adjacent position
	shiftSequence = function(data, p, direction, undo)



	end,

}