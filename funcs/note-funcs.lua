
return {

	-- Return true on a note overlap, or false otherwise
	checkNoteOverlap = function(n1, n2, durbool)

		durbool = durbool or false

		-- If either of the notes are in a setNotes format, reformat a copy for comparison
		if (n1[1] == 'remove') or (n1[1] == 'insert') then n1 = deepCopy(n1[2]) end
		if (n2[1] == 'remove') or (n2[1] == 'insert') then n2 = deepCopy(n2[2]) end

		-- If notes have the same channel and pitch...
		if (n1[4] == n2[4]) and (n1[5] == n2[5]) then

			-- If one note's duration overlaps the other, return true, else false
			local n1c = n1[2] + ((durbool and n1[3]) or 1) - 1
			local n2c = n2[2] + ((durbool and n2[3]) or 1) - 1
			return collisonCheck(n1[2], 0, n1c, 0, n2[2], 0, n2c, 0)

		end

		-- Return false for all cases where channel and pitch don't match
		return false

	end,

	-- Reformats a group of notes as a series of setNotes commands
	notesToSetType = function(notes, kind)

		notes = deepCopy(notes)
		
		if (kind ~= 'insert') and (kind ~= 'remove') then
			kind = 'insert'
		end

		for k, v in pairs(notes) do
			if type(v[2]) == 'table' then
				notes[k][1] = kind
			else
				notes[k] = {kind, v}
			end
		end

		return notes

	end,

	-- Get the notes from a given slice of a sequence, optionally bounded to a channel
	getNotes = function(p, tbot, ttop, nbot, ntop, chan)

		-- Set parameters to default if any are empty
		tbot = tbot or 1
		ttop = ttop or D.seq[p].total
		nbot = nbot or D.bounds.np[1]
		ntop = ntop or D.bounds.np[2]
		chan = chan or false

		-- Compensate for erroneous bounds
		if ttop < tbot then ttop = tbot end
		if ntop < nbot then ntop = nbot end

		-- Grab all notes within the given range, bounded to a single channel if applicble,
		-- and put them into a notes-table.
		local tindexes, nindexes = {}, {}
		for t = tbot, ttop do
			table.insert(tindexes, t)
		end
		for n = nbot, ntop do
			table.insert(nindexes, n)
		end
		local notes = getContents(D.seq[p].tick, {tindexes, "note", chan or pairs, nindexes})

		return notes

	end,

	-- Insert a given table of note values into a sequence
	setNotes = function(p, notes, undo)

		-- Make duplicates of the notes, to prevent reference bugs
		notes = deepCopy(notes)

		-- If no notes were given, abort function
		if #notes == 0 then
			return nil
		end

		local undonotes = {}
		local redonotes = {}

		local removenotes = {}
		local addnotes = {}

		local ticks = D.seq[p].total

		-- Find all overlapping notes, and all to-be-removed notes
		for i = #notes, 1, -1 do

			local kind, n = unpack(notes[i])

			-- If an already-existing note matches the incoming note...
			local sn = getIndex(D.seq[p].tick, {n[2] + 1, "note", n[4], n[5]})
			if sn then

				-- If the incoming setNote command is for removal, put old note into remove-table.
				-- Else, put old note into remove-table, and new note into add-table.
				if kind == 'remove' then
					table.insert(removenotes, sn)
				else
					table.insert(removenotes, sn)
					table.remove(notes, i)
					table.insert(addnotes, n)
				end

			end

		end

		-- Shift remaining incoming notes into their tables
		for k, v in pairs(notes) do
			if v[1] == 'insert' then
				table.insert(addnotes, v[2])
			end
		end

		-- Bound addnotes' note durations to the end of the sequence
		for k, v in pairs(addnotes) do
			if (v[2] + v[3] - 1) > ticks then
				v[3] = ticks - v[2]
			end
		end

		-- Remove all removenotes, cull sparse tables, and shape undo tables
		for k, v in pairs(removenotes) do
			local rnote = getIndex(D.seq[p].tick, {v[2] + 1, "note", v[4], v[5]})
			if rnote then
				seqUnsetCascade(p, 'note', rnote)
				table.insert(undonotes, {'insert', rnote})
				table.insert(redonotes, {'remove', rnote})
			end
		end

		-- Add all addnotes while building sparse tables, and shape undo tables accordingly
		for k, v in pairs(addnotes) do
			buildTable(D.seq[p].tick, {v[2] + 1, "note", v[4], v[5]}, v)
			table.insert(undonotes, {'remove', deepCopy(v)})
			table.insert(redonotes, {'insert', deepCopy(v)})
		end

		-- Build undo tables
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"setNotes", p, undonotes}, -- Undo command
			{"setNotes", p, redonotes} -- Redo command
		)

	end,

	-- Insert a note, with the current note-var settings
	insertNote = function(dist, undo)

		local n = {}

		-- If the note/tick pointers don't exist, get temporary values
		local tempnp = D.np or 0
		local temptp = D.tp or 1

		-- If Entry-Quantize is active, snap the insert-point to the nearest factor-tick
		if D.entryquant then
			temptp = wrapNum(temptp + getSnapDistance(temptp, D.factors[D.fp]) + 1, 1, D.seq[D.active].total)
		end

		-- If Cmd Mode isn't active...
		if D.cmdmode ~= "cmd" then

			-- If a distance-from-C isn't given, set it to the note-pointer position
			dist = dist or (tempnp % 12)

			-- Get the note-pointer position, modulated by dist-offset
			local npoffset = dist + (tempnp - (tempnp % 12))
			local adjnote = clampNum(npoffset, D.bounds.np)

			n = {
				'insert', -- setNotes command-name
				{
					'note', -- MIDI.lua item command
					temptp - 1, -- 0-indexed tick start-time
					D.dur, -- Duration (ticks)
					D.chan, -- Channel
					adjnote, -- Pitch + piano key dist
					D.velo, -- Velocity
				},
			}

			-- Send the note to the MIDI-over-UDP listener, on the user-defined port
			sendMidiMessage(n[2])

		end

		-- If recording is off, then abort function
		if not D.recording then
			return nil
		end

		if D.cmdmode == "gen" then -- If in Generator Mode, generate a note-sequence

			generateSeqNotes(D.active, dist, undo)

		elseif D.cmdmode == "entry" then -- If in Entry Mode, enter a note

			setNotes(D.active, {n}, undo)
			moveTickPointer(1) -- Move ahead by one spacing unit

		else -- Else, we're in Cmd Mode, so generate a non-note command

			local c = {
				D.cmdtypes[D.cmdtype][3],
				temptp - 1,
				D.chan,
				D.cmdbyte1,
			}

			-- For 2-byte commands, add the second Cmd-byte
			if (c[1] == 'key_after_touch')
			or (c[1] == 'control_change')
			then

				c[5] = D.cmdbyte2

			-- For pitch-bend commands, sum the two byte commands
			elseif c[1] == 'pitch_wheel_change' then

				c[4] = (c[4] * 128) + D.cmdbyte2

			end

			setCmd(D.active, {'insert', D.cmdp, c}, undo)

		end

	end,

	-- Delete the note at the current pointer position
	deleteNote = function(undo)

		local delnotes = {}

		-- If Cmd Mode is active, delete the active Non-Note
		if D.cmdmode == "cmd" then

			-- If the command-pointer corresponds to a cmd on the active tick,
			-- create a "remove" cmd, and send that cmd to setCmd.
			if getIndex(D.seq[D.active].tick, {D.tp, "cmd", D.cmdp}) then
				setCmd(D.active, {'remove', D.cmdp}, undo)
				moveTickPointer(1) -- Move tick-pointer by 1 spacing unit
			end

		else -- Else, delete the active note

			-- If any notes are selected, slate them for deletion
			if next(D.seldat) ~= nil then
				delnotes = getContents(D.seldat, {pairs, pairs, pairs})
			else -- Else, if no notes are selected, slate the current pointer-pos's note for deletion
				delnotes = getNotes(D.active, D.tp, D.tp, D.np, D.np, D.chan)
			end

			-- If any matching notes were found, remove them
			if #delnotes > 0 then
				delnotes = notesToSetType(delnotes, 'remove')
				setNotes(D.active, delnotes, undo)
				moveTickPointer(1) -- Move tick-pointer by 1 spacing unit
			end

		end

	end,

	-- Delete all notes in the active tick
	deleteTickNotes = function(undo)

		-- If Cmd Mode is active, delete all non-note commands within the tick
		if D.cmdmode == "cmd" then

			local delcmds = getCmds(D.active, D.tp, D.tp, _, 'remove')
			delcmds = cmdsToSetType(delcmds, 'remove')

			-- If any matching cmds were found, send them through setCmd individually
			if #delcmds > 0 then
				for k, v in pairs(delcmds) do
					setCmd(D.active, v, undo)
				end
				moveTickPointer(1) -- Move tick-pointer by 1 spacing unit
			end

		else -- Else, delete all notes on the tick

			local delnotes = getNotes(D.active, D.tp, D.tp, _, _, D.chan)
			delnotes = notesToSetType(delnotes, 'remove')

			-- If any matching notes were found, send them through removeNotes
			if #delnotes > 0 then
				setNotes(D.active, delnotes, undo)
				moveTickPointer(1) -- Move tick-pointer by 1 spacing unit
			end

		end

	end,

	-- Delete all notes in the active pitch
	deletePitchNotes = function(undo)

		local delnotes = getNotes(D.active, _, _, D.np, D.np, D.chan)
		delnotes = notesToSetType(delnotes, 'remove')

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			setNotes(D.active, delnotes, undo)
		end

	end,

	-- Delete all notes in the active beat
	deleteBeatNotes = function(undo)

		-- Find the beginning and end of the current beat
		local ltick = D.tp
		while wrapNum(ltick, 1, D.tpq * 4) ~= 1 do
			ltick = ltick - 1
		end
		local rtick = clampNum((ltick + (D.tpq * 4)) - 1, 1, D.seq[D.active].total)

		-- If Cmd Mode is active, delete all non-note commands within the beat
		if D.cmdmode == "cmd" then

			local delcmds = getCmds(D.active, ltick, rtick, 'remove')

			-- If any matching cmds were found, send them through setCmd individually
			if #delcmds > 0 then
				for k, v in pairs(delcmds) do
					setCmd(D.active, v, undo)
				end
			end

		else -- Else, delete all notes in the beat

			local delnotes = getNotes(D.active, ltick, rtick, _, _, D.chan)
			delnotes = notesToSetType(delnotes, 'remove')

			-- If any matching notes were found, send them through removeNotes
			if #delnotes > 0 then
				setNotes(D.active, delnotes, undo)
			end

		end

	end,

}