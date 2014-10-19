
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
		ttop = ttop or #data.seq[p].tick
		nbot = nbot or data.bounds.np[1]
		ntop = ntop or data.bounds.np[2]
		chan = chan or false

		-- Compensate for erroneous bounds
		if ttop < tbot then ttop = tbot end
		if ntop < nbot then ntop = nbot end

		-- Grab all notes within the given range, bounded to a single channel if applicble,
		-- and put them into a notes-table.
		local tindexes = {}
		for t = tbot, ttop do
			table.insert(tindexes, t)
		end
		local notes = getContents(
			data.seq[p].tick,
			{tindexes, "note", chan or pairs, pairs}
		)

		-- Exclude notes that fall outside the note-range
		for i = #notes, 1, -1 do
			if not rangeCheck(notes[i][5], nbot, ntop) then
				table.remove(notes, i)
			end
		end

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

		local ticks = #data.seq[p].tick

		-- Find all overlapping notes, and all to-be-removed notes
		for i = #notes, 1, -1 do

			local n = notes[i]

			-- Get all notes from within the comparison-note's tick-channel pair
			local sn = getContents(
				data.seq[p].tick,
				{n[2][2] + 1, "note", n[2][4], pairs}
			)

			-- For every note that matches the comparison-note's tick and channel...
			for k, v in pairs(sn) do

				-- If the incoming setNote command is for removal,
				-- and it matches the old note, then put old note into remove-table.
				-- Else if the new note matches the old note, and Cmd Mode is inactive,
				-- put old note into remove-table, and new note into add-table.
				if (n[1] == 'remove') and checkNoteOverlap(n[2], sn) then
					table.insert(removenotes, sn)
					break
				elseif (data.cmdmode ~= "cmd") and checkNoteOverlap(n, sn) then
					table.insert(removenotes, sn)
					local anote = table.remove(notes, i)
					table.insert(addnotes, anote[2])
					break
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
			local t = v[2] + 1
			if getIndex(data.seq[p].tick, {t, "note", v[4], v[5]}) then
				local rnote = table.remove(data.seq[p].tick[t].note[v[4]], v[5])
				dismantleTable(
					data.seq[p].tick[t].note,
					{v[4], v[5]}
				)
				table.insert(undonotes, {'insert', rnote})
				table.insert(redonotes, {'remove', rnote})
			end
		end

		-- Add all addnotes while building sparse tables, and shape undo tables accordingly
		for k, v in pairs(addnotes) do
			buildTable(data.seq[p].tick[v[2] + 1], {"note", v[4], v[5]}, v)
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
		local tempnp = data.np or 0
		local temptp = data.tp or 1

		-- If Cmd Mode isn't active...
		if data.cmdmode ~= "cmd" then

			-- If a distance-from-C isn't given, set it to the note-pointer position
			dist = dist or (tempnp % 12)

			-- Get the note-pointer position, modulated by dist-offset
			local npoffset = dist + (tempnp - (tempnp % 12))
			local adjnote = clampNum(npoffset, data.bounds.np)

			n = {
				'insert', -- setNotes command-name
				{
					'note', -- MIDI.lua item command
					temptp - 1, -- 0-indexed tick start-time
					data.dur, -- Duration (ticks)
					data.chan, -- Channel
					adjnote, -- Pitch + piano key dist
					data.velo, -- Velocity
				},
			}

			-- Send the note to the MIDI-over-UDP listener, on the user-defined port
			sendMidiMessage(n[2])

		end

		-- If recording is off, then abort function
		if not data.recording then
			return nil
		end

		if data.cmdmode == "gen" then -- If in Generator Mode, generate a note-sequence

			generateSeqNotes(data.active, dist, undo)

		elseif data.cmdmode == "entry" then -- If in Entry Mode, enter a note

			setNotes(data.active, {n}, undo)
			moveTickPointer(1) -- Move ahead by one spacing unit

		else -- Else, we're in Cmd Mode, so generate a non-note command

			local c = {
				data.cmdtypes[data.cmdtype][3],
				temptp - 1,
				data.chan,
				data.cmdbyte1,
			}

			-- For 2-byte commands, add the second Cmd-byte
			if (c[1] == 'key_after_touch')
			or (c[1] == 'control_change')
			then

				c[5] = data.cmdbyte2

			-- For pitch-bend commands, sum the two byte commands
			elseif c[1] == 'pitch_wheel_change' then

				c[4] = (c[4] * 128) + data.cmdbyte2

			end

			setCmd(data.active, {'insert', data.cmdp, c}, undo)

		end

	end,

	-- Delete the note at the current pointer position
	deleteNote = function(undo)

		local delnotes = {}

		-- If Cmd Mode is active, delete the active Non-Note
		if data.cmdmode == "cmd" then

			local t = data.seq[data.active].tick[data.tp]

			-- If the command-pointer corresponds to a cmd on the active tick,
			-- create a "remove" cmd, and send that cmd to setCmd.
			local cmdtab = getIndex(t, {data.chan, "cmd", data.cmdp})
			if cmdtab and (#t[data.chan].cmd >= data.cmdp) then
				setCmd(
					data.active,
					{'remove', data.cmdp, cmdtab},
					undo
				)
			end

		else -- Else, delete the active note

			-- If any notes are selected, slate them for deletion
			if #data.seldat > 0 then
				delnotes = notesToSetType(data.seldat, 'remove')
			else -- Else, if no notes are selected, slate the current pointer-pos's note for deletion
				delnotes = getNotes(data.active, data.tp, data.tp, data.np, data.np, data.chan)
				delnotes = notesToSetType(delnotes, 'remove')
			end

			-- If any matching notes were found, remove them
			if #delnotes > 0 then
				setNotes(data.active, delnotes, undo)
			end

		end

	end,

	-- Delete all notes in the active tick
	deleteTickNotes = function(undo)

		-- If Cmd Mode is active, delete all non-note commands within the tick
		if data.cmdmode == "cmd" then

			local delcmds = getCmds(data.active, data.tp, data.tp, _, 'remove')
			delcmds = cmdsToSetType(delcmds, 'remove')

			-- If any matching cmds were found, send them through setCmd individually
			if #delcmds > 0 then
				for k, v in pairs(delcmds) do
					setCmd(data.active, v, undo)
				end
			end

		else -- Else, delete all notes on the tick

			local delnotes = getNotes(data.active, data.tp, data.tp, _, _, data.chan)
			delnotes = notesToSetType(delnotes, 'remove')

			-- If any matching notes were found, send them through removeNotes
			if #delnotes > 0 then
				setNotes(data.active, delnotes, undo)
			end

		end

	end,

	-- Delete all notes in the active pitch
	deletePitchNotes = function(undo)

		local delnotes = getNotes(data.active, _, _, data.np, data.np, data.chan)
		delnotes = notesToSetType(delnotes, 'remove')

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			setNotes(data.active, delnotes, undo)
		end

	end,

	-- Delete all notes in the active beat
	deleteBeatNotes = function(undo)

		-- Find the beginning and end of the current beat
		local ltick = data.tp
		while wrapNum(ltick, 1, data.tpq * 4) ~= 1 do
			ltick = ltick - 1
		end
		local rtick = clampNum((ltick + (data.tpq * 4)) - 1, 1, #data.seq[data.active].tick)

		-- If Cmd Mode is active, delete all non-note commands within the beat
		if data.cmdmode == "cmd" then

			local delcmds = getCmds(data.active, ltick, rtick, _, 'remove')
			delcmds = cmdsToSetType(delcmds, 'remove')

			-- If any matching cmds were found, send them through setCmd individually
			if #delcmds > 0 then
				for k, v in pairs(delcmds) do
					setCmd(data.active, v, undo)
				end
			end

		else -- Else, delete all notes in the beat

			local delnotes = getNotes(data.active, ltick, rtick, _, _, data.chan)
			delnotes = notesToSetType(delnotes, 'remove')

			-- If any matching notes were found, send them through removeNotes
			if #delnotes > 0 then
				setNotes(data.active, delnotes, undo)
			end

		end

	end,

	-- Humanize the volumes of the currently selected notes
	humanizeNotes = function(undo)

		-- If no notes are selected, abort function
		if #data.seldat == 0 then
			return nil
		end

		-- For every currently-selected note...
		for k, v in pairs(data.seldat) do

			-- Change the velocities in the selection-table
			local rand = math.random(0, data.velo)
			local newvelo = clampNum(v[6] + (roundNum(data.velo / 2) - rand), data.bounds.velo)
			data.seldat[k][6] = newvelo

		end

		-- Convert copies of the selected notes into setNotes commands
		local selset = deepCopy(data.seldat)
		for k, v in pairs(selset) do
			selset[k] = {'insert', selset[k]}
		end

		-- Use setNotes to replace the seq-notes with corresponding selection-tab notes
		setNotes(data.active, data.seldat, undo)

	end,

	-- Quantize the tick-positions of the currently selected notes, based on current spacing
	quantizeNotes = function(undo)

		-- If no notes are selected, abort function
		if #data.seldat == 0 then
			return nil
		end

		-- If spacing is too slim for quantization to have any effect, abort function
		if data.spacing < 2 then
			return nil
		end

		local modtab = {}

		local ticks = #data.seq[data.active].tick 

		-- For every currently-selected note, prioritizing the most recently selected first...
		for k, v in ripairs(data.seldat) do

			-- Get the note's left and right distances from the spacing value
			local ldist = -1 * wrapNum(v[2], 0, data.spacing - 1)
			local rdist = ldist + data.spacing
			local shift = ldist
			if rdist < math.abs(ldist) then
				shift = rdist
			end

			-- Build the note's section of the movement-command table
			table.insert(modtab, {v, "tick", shift})

		end

		-- Send the movement-command tables to modNotes
		modNotes(data.active, modtab, undo)

	end,

}