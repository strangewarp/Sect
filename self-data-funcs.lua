return {

	-- Insert a number ofticks at the end of a sequence
	growSeq = function(data, seq, num, undo)

		for i = 1, num do
			table.insert(data.seq[seq].tick, {})
		end

		-- Build undo tables
		data:addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"shrinkSeq", seq, num}, -- Undo command
			{"growSeq", seq, num} -- Redo command
		)

	end,
	
	-- Remove a number of ticks from the end of a sequence
	shrinkSeq = function(data, seq, num, undo)

		for i = 1, num do
			table.remove(data.seq[seq].tick, #data.seq[seq].tick)
		end

		-- Build undo tables
		data:addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"growSeq", seq, num}, -- Undo command
			{"shrinkSeq", seq, num} -- Redo command
		)

	end,

	-- Insert a given chunk of ticks and notes, in a given sequence, at a given point
	addTicksAndNotes = function(data, seq, t, num, undo)

		-- Prevent modifications to the undo table's original referent
		undo = deepCopy(undo)

		local top = t + (num - 1)
		local oldsize = #data.seq[seq].tick

		-- Add ticks to the top of the sequence
		data:growSeq(seq, num, undo)
		undo[2] = true

		-- If there are any ticks to the right of the old top-tick, adjust their notes' positions
		if top < oldsize then
			local sidenotes = data:getNotes(seq, top + 1, #data.seq[seq].tick, _, _)
			data:moveNotes(seq, sidenotes, num, _, undo)
		end

	end,

	-- Remove a given chunk of ticks and notes, in a given sequence, at a given point
	removeTicksAndNotes = function(data, seq, t, num, undo)

		-- Prevent modifications to the undo table's original referent
		undo = deepCopy(undo)

		local top = t + (num - 1)

		-- Get notes from the removal area, to put into the undo table
		local notes = data:getNotes(seq, t, top, _, _)
		data:removeNotes(seq, notes, undo)
		undo[2] = true

		-- If there are any ticks to the right, adjust their notes' positions
		if top < #data.seq[seq].tick then
			local sidenotes = data:getNotes(seq, top + 1, #data.seq[seq].tick, _, _)
			data:moveNotes(seq, sidenotes, num * -1, _, undo)
		end

		-- Remove ticks from the top of the sequence
		data:shrinkSeq(seq, num, undo)

	end,

	-- Insert a number of ticks based on data.spacing, at the current position
	insertSpacingTicks = function(data, undo)

		data:addTicksAndNotes(data.active, data.tp, data.spacing, undo)

	end,

	-- Remove a number of ticks based on data.spacing, at the current position
	removeSpacingTicks = function(data, undo)

		local limit = #data.seq[data.active].tick - data.tp
		local num = clampNum(data.spacing, 0, limit)

		data:removeTicksAndNotes(data.active, data.tp, num, undo)

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

		-- Normalize all pointers
		data:normalizePointers()

		-- Build undo tables
		data:addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"removeSequence", seq}, -- Undo command
			{"addSequence", seq} -- Redo command
		)

	end,

	-- Remove a sequence from the sequence-table at the current active-sequence pointer
	removeSequence = function(data, seq, undo)

		local removenotes = {}

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

		-- Gather all notes from the sequence, set them to false, and remove them,
		-- creating a new undo-table entry in the process.
		local removenotes = data:getNotes(seq, 1, #data.seq[seq].tick, _, _)
		if #removenotes > 0 then
			removenotes = notesToRemove(removenotes)
			data:setNotes(seq, removenotes, ((undo == nil) and true) or undo)
		end

		-- Remove the sequence from the seqs-table
		table.remove(data.seq, seq)
		print("removeSequence: removed sequence from position " .. seq)

		-- Build undo tables
		data:addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"addSequence", seq}, -- Undo command
			{"removeSequence", seq} -- Redo command
		)

	end,

	-- Add a new sequence at the active sequence-location
	addActiveSequence = function(data, undo)
		data:addSequence(data.active, undo)
	end,

	-- Remove the currently active sequence, with proper undo-wrapping
	removeActiveSequence = function(data, undo)
		data:removeSequence(data.active, undo)
	end,

}