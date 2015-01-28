
return {

	-- Change the currently active sequence
	tabActiveSequence = function(dir)
		D.active = wrapNum(D.active + dir, 1, #D.seq)
	end,

	-- Set the total number of ticks in a sequence to a given amount,
	-- while erasing and generating undo-commands for any notes and cmds that might be present.
	setTicks = function(p, ticks, undo)

		local oldticks = D.seq[p].total

		-- If fewer ticks than old tick-total, check for note-and-cmd erasures
		if ticks < D.seq[p].total then
			local gleft = ticks + 1
			local remnotes = getNotes(p, gleft, D.seq[p].total, _, _)
			local remcmds = getCmds(p, gleft, D.seq[p].total, _, 'remove')
			remnotes = notesToSetType(remnotes, 'remove')
			setNotes(p, remnotes, undo)
			setCmds(p, remcmds, undo)
		end

		-- Change the tick-total amount to the given value
		D.seq[p].total = ticks

		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"setTicks", p, oldticks}, -- Undo command
			{"setTicks", p, ticks} -- Redo command
		)

	end,

	-- Insert a given chunk of ticks into a given sequence, at a given point
	insertTicks = function(seq, tick, addticks, undo)

		-- Add ticks to the top of the sequence
		local total = D.seq[seq].total + addticks
		setTicks(seq, total, undo)

		-- If there are any ticks to the right of the old top-tick, adjust their contents' positions
		local sidenotes = getNotes(seq, D.tp, D.seq[seq].total, _, _)
		local sidecmds = getCmds(seq, D.tp, D.seq[seq].total, _, 'modify')
		if (#sidenotes > 0) or (#sidecmds > 0) then
			for k, v in pairs(sidenotes) do
				sidenotes[k] = {v, 'tp', 1}
			end
			for k, v in pairs(sidecmds) do
				sidecmds[k] = {v[3], v[2], 'tp', 1}
			end
			modNotes(seq, sidenotes, false, true, undo)
			modCmds(seq, sidecmds, true, undo)
		end

	end,

	-- Remove a given chunk of ticks and notes, in a given sequence, at a given point
	removeTicks = function(seq, tick, remticks, undo)

		remticks = math.min(remticks, D.seq[seq].total - tick)

		local top = tick + (remticks - 1)

		-- Get commands from the removal area
		local notes = getNotes(seq, tick, top, _, _)
		local cmds = getCmds(seq, tick, top, _, 'remove')

		-- Remove note-commands
		if #notes > 0 then
			local rem = notesToSetType(notes, 'remove')
			setNotes(seq, rem, undo)
		end

		-- Remove non-note commands
		if #cmds > 0 then
			setCmds(seq, cmds, undo)
		end

		-- If there are any ticks to the right, adjust their contents' positions
		if top < D.seq[seq].total then

			-- Get commands from between the removal area and the end of the sequence
			local sidenotes = getNotes(seq, top + 1, D.seq[seq].total, _, _)
			local sidecmds = getCmds(seq, top + 1, D.seq[seq].total, _, 'modify')

			-- Move all note-commands
			if #sidenotes > 0 then
				for k, v in pairs(sidenotes) do
					sidenotes[k] = {v, 'tp', -1}
				end
				modNotes(seq, sidenotes, false, true, undo)
			end

			-- Move all non-note commands
			if #sidecmds > 0 then
				for k, v in pairs(sidecmds) do
					sidecmds[k] = {v[3], v[2], 'tp', -1}
				end
				modCmds(seq, sidecmds, true, undo)
			end

		end

		-- Remove ticks from the now-empty top of the sequence
		setTicks(seq, D.seq[seq].total - remticks, undo)

	end,

	-- Multiply the number of ticks in the active sequence by an amount equal to (duration/spacing)
	multiplyTicks = function(undo)
		local total = D.seq[D.active].total
		local newval = math.max(1, roundNum(total * (D.dur / math.max(1, D.spacing)), 0))
		if newval == total then
			return nil
		end
		setTicks(D.active, newval, undo)
	end,

	-- Insert a number of ticks based on D.spacing, at the current position
	insertSpacingTicks = function(undo)
		insertTicks(D.active, D.tp, D.spacing, undo)
	end,

	-- Remove a number of ticks based on D.spacing, at the current position
	removeSpacingTicks = function(undo)
		removeTicks(D.active, D.tp, D.spacing, undo)
	end,

	-- Add a new sequence to the sequence-table at the current seq-pointer
	addSequence = function(seq, undo)

		local newseq = deepCopy(D.baseseq)

		-- If no sequences exist, set the active pointer and insert-point to 1
		if D.active == false then
			D.active = 1
			seq = 1
		end

		-- Insert the new sequence
		table.insert(D.seq, seq, newseq)

		-- Build undo tables
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"removeSequence", seq}, -- Undo command
			{"addSequence", seq} -- Redo command
		)

		-- Add dummy-ticks to the sequence's tick-total, to prevent errors
		setTicks(seq, D.tpq * 4, undo)

		-- Normalize all pointers
		normalizePointers()

	end,

	-- Remove a sequence from the sequence-table at the current active-sequence pointer
	removeSequence = function(seq, undo)

		local removenotes = {}

		if #D.seq == 1 then -- If only one sequence remains, set the active pointer to false, to signify that none exist
			D.active = false
		elseif D.active == #D.seq then -- If the highest sequence is being removed, and is active, then move the activity pointer downward
			D.active = D.active - 1
		end

		-- If any notes are in the sequence, 
		local notes = getNotes(seq)
		if #notes > 0 then
			notes = notesToSetType(notes, 'remove')
			setNotes(seq, notes, undo)
		end

		-- Insert a dummy setTicks command for the current sequence-size, to build undo-tables properly
		setTicks(seq, D.seq[seq].total, undo)

		-- Remove the sequence from the seqs-table
		table.remove(D.seq, seq)

		-- Build undo tables
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"addSequence", seq}, -- Undo command
			{"removeSequence", seq} -- Redo command
		)

	end,

	-- Add a new sequence just after the active sequence-location
	addActiveSequence = function(undo)
		addSequence(D.active and (D.active + 1), undo)
	end,

	-- Remove the currently active sequence, with proper undo-wrapping
	removeActiveSequence = function(undo)
		removeSequence(D.active, undo)
	end,

	-- Switch the positions of two sequences
	switchSequences = function(k, k2, undo)

		D.seq[k], D.seq[k2] = deepCopy(D.seq[k2]), deepCopy(D.seq[k])

		-- Build undo tables
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"switchSequences", k2, k}, -- Undo command
			{"switchSequences", k, k2} -- Redo command
		)

	end,

	-- Move the active sequence in a given direction
	moveActiveSequence = function(dir, undo)

		-- If fewer than two sequences exist, abort function
		if #D.seq < 2 then
			return nil
		end

		-- Get the sequence in the intended direction, and insert it at current position
		local dupkey = wrapNum(D.active + dir, 1, #D.seq)

		-- Switch the active sequence with the directional sequence
		switchSequences(D.active, dupkey, undo)

		-- Move the pointer to the previously active sequence's new position
		D.active = dupkey

	end,

	-- Sanitize all data-structures
	sanitizeDataStructures = function()

		normalizePointers()
		removeOldSelectItems()
		getBeatFactors()

		-- If not loading, and either not in Play Mode or a command is being held, refresh GUI and canvas contents
		if (not D.loading) and ((not D.playing) or D.funcactive) then
			D.rebuild = true
		end

	end,

}
