
return {

	-- Change the currently active sequence
	tabActiveSeq = function(dir)
		data.active = wrapNum(data.active + dir, 1, #data.seq)
	end,

	-- Insert a number ofticks at the end of a sequence
	growSeq = function(seq, num, undo)

		for i = 1, num do
			table.insert(data.seq[seq].tick, {})
		end

		-- Build undo tables
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"shrinkSeq", seq, num}, -- Undo command
			{"growSeq", seq, num} -- Redo command
		)

	end,
	
	-- Remove a number of ticks from the end of a sequence
	shrinkSeq = function(seq, num, undo)

		for i = 1, num do
			table.remove(data.seq[seq].tick, #data.seq[seq].tick)
		end

		-- Build undo tables
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"growSeq", seq, num}, -- Undo command
			{"shrinkSeq", seq, num} -- Redo command
		)

	end,

	-- Insert a given chunk of ticks and notes, in a given sequence, at a given point
	insertTicks = function(seq, tick, addticks, undo)

		local top = tick + (addticks - 1)
		local oldsize = #data.seq[seq].tick

		-- Add ticks to the top of the sequence
		growSeq(seq, addticks, undo)

		-- If there are any ticks to the right of the old top-tick, adjust their notes' positions
		if top < oldsize then
			local sidenotes = getNotes(seq, top + 1, #data.seq[seq].tick, _, _)
			if #sidenotes > 0 then
				moveNotes(seq, sidenotes, addticks, _, undo)
			end
		end

	end,

	-- Remove a given chunk of ticks and notes, in a given sequence, at a given point
	removeTicks = function(seq, tick, remticks, undo)

		local top = tick + (remticks - 1)

		-- Get notes from the removal area, and remove them, into undo
		local notes = getNotes(seq, tick, top, _, _)
		if #notes > 0 then
			removeNotes(seq, notes, undo)
		end

		-- If there are any ticks to the right, adjust their notes' positions
		if top < #data.seq[seq].tick then
			local sidenotes = getNotes(seq, top + 1, #data.seq[seq].tick, _, _)
			if #sidenotes > 0 then
				moveNotes(seq, sidenotes, remticks * -1, _, undo)
			end
		end

		-- Remove ticks from the now-empty top of the sequence
		shrinkSeq(seq, remticks, undo)

	end,

	-- Insert a number of ticks based on data.spacing, at the current position
	insertSpacingTicks = function(undo)

		insertTicks(data.active, data.tp, data.spacing, undo)

	end,

	-- Remove a number of ticks based on data.spacing, at the current position
	removeSpacingTicks = function(undo)

		local num = clampNum(data.spacing, 0, #data.seq[data.active].tick - data.tp)

		removeTicks(data.active, data.tp, num, undo)

	end,

	-- Add a new sequence to the sequence-table at the current seq-pointer
	addSequence = function(seq, undo)

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
		normalizePointers()

		-- Build undo tables
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"removeSequence", seq}, -- Undo command
			{"addSequence", seq} -- Redo command
		)

	end,

	-- Remove a sequence from the sequence-table at the current active-sequence pointer
	removeSequence = function(seq, undo)

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
		elseif data.active == #data.seq then -- If the highest sequence is being removed, and is active, then move the activity pointer downward
			data.active = data.active - 1
		end

		-- Gather all notes from the sequence, set them to false, and remove them
		local removenotes = getNotes(seq, 1, #data.seq[seq].tick, _, _)
		if #removenotes > 0 then
			removenotes = notesToRemove(removenotes)
			setNotes(seq, removenotes, ((undo == nil) and true) or undo)
		end

		-- Remove the sequence from the seqs-table
		table.remove(data.seq, seq)
		print("removeSequence: removed sequence from position " .. seq)

		-- Build undo tables
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"addSequence", seq}, -- Undo command
			{"removeSequence", seq} -- Redo command
		)

	end,

	-- Add a new sequence at the active sequence-location
	addActiveSequence = function(undo)
		addSequence(data.active, undo)
	end,

	-- Remove the currently active sequence, with proper undo-wrapping
	removeActiveSequence = function(undo)
		removeSequence(data.active, undo)
	end,

}