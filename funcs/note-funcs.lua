
return {

	-- Return true on a note overlap, or false otherwise
	checkNoteOverlap = function(n1, n2, durbool)

		durbool = durbool or false

		return (
			(n1.tick == n2.tick)
			and (
				( -- Note is removal-abstraction, and overlaps both pitch and tick
					noteRemoveCompare(n1, n2)
				)
				or ( -- Notes are note-type, and overlap in pitch, chan, and tick
					(n1.note[1] == 'note')
					and (n2.note[1] == 'note')
					and (n1.note[4] == n2.note[4])
					and (n1.note[5] == n2.note[5])
					and (
						(
							durbool -- Check for duration overlap
							and (
								rangeCheck(n1.note[5], n2.note[5], n2.note[5] + n2.note[3])
								or rangeCheck(n2.note[5], n1.note[5], n1.note[5] + n1.note[3])
							)
						)
						-- Check for initial-tick overlap only
						or (n1.note[5] == n2.note[5])
					)
				)
				or ( -- Notes are not note-type, and overlap in type, chan, and tick
					(n1.note[1] ~= 'note')
					and (n2.note[1] ~= 'note')
					and (n1.note[1] == n2.note[1])
					and (n1.note[3] == n2.note[3])
					and (n1.note[4] == n2.note[4])
				)
			)
		)

	end,

	-- Check whether a note-remove command matches a note, across note values
	noteRemoveCompare = function(n1, n2, iter)

		return (
			((iter == nil) and noteRemoveCompare(n2, n1, false))
			or (
				(n1.note[1] == 'remove')
				and (
					(n1.tick == n2.tick)
					and (
						(
							(n2.note[1] == 'note')
							and (n1.note[2] == n2.note[4])
							and (n1.note[3] == n2.note[5])
						) or (
							(n2.note[1] ~= 'note')
							and (n1.note[2] == n2.note[3])
							and (n1.note[3] == n2.note[4])
						)
					)
				)
			)
		)

	end,

	-- Flag a group of note-subtables for removal
	notesToRemove = function(notes)
		for k, v in pairs(notes) do
			notes[k].note = {'remove', v.note[4], v.note[5]}
		end
		return notes
	end,

	-- Modify a table of non-note commands to flag them for removal
	cmdsToRemove = function(cmds)
		for k, v in pairs(cmds) do
			v[1] = 'remove'
		end
		return cmds
	end,

	-- Get the non-note commands from a given slice of a sequence, bounded to a channel
	getCmds = function(p, tbot, ttop, chan, kind)

		-- Set parameters to default if any are empty
		tbot = tbot or 1
		ttop = ttop or #data.seq[p].tick
		chan = chan or false

		-- Choose the iterator type, based on whether the table will
		-- be inserted in order, or removed in order.
		local iter = 'ipairs'
		if kind == 'remove' then
			iter = 'ripairs'
		end

		local cmds = {}

		-- Grab all cmds within the given range, and put them in the cmds-table
		for t = tbot, ttop do
			for k, v in _G[iter](data.seq[p].tick[t]) do
				if v.note[1] ~= 'note' then

					-- If a channel was given, only grab cmd-keys from that channel,
					-- or if no channel was given, grab all cmd-keys.
					if (not chan) or (chan == data.chan) then
						table.insert(cmds, {'insert', k, deepCopy(v)})
						print(v.note[1])--debugging
					end

				end
			end
		end

		return cmds

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

		local notes = {}

		-- Grab all notes within the given range, and put them in notes-table
		for t = tbot, ttop do
			for k, v in pairs(data.seq[p].tick[t]) do
				if (v.note[1] == 'note') and rangeCheck(v.note[5], nbot, ntop) then

					-- If a channel was given, only grab notes that match that channel,
					-- or if no channel was given, just grab all notes.
					if (not chan)
					or ((chan == data.chan) and (v.note[4] == chan))
					then
						print("DYE: "..tostring(not chan).." "..tostring(chan==data.chan))--debugging
						table.insert(notes, deepCopy(v))
					end

				end
			end
		end

		return notes

	end,

	-- Insert a given command value into a sequence
	setCmd = function(p, cmd, undo)

		-- Make a duplicate of the command, to prevent reference bugs
		local undocmd, redocmd = deepCopy(cmd), deepCopy(cmd)

		-- Either insert or remove the cmd, depending on its flag
		if cmd[1] == 'remove' then
			table.remove(data.seq[p].tick[cmd[3].tick], cmd[2])
			undocmd[1] = 'insert'
		else
			table.insert(data.seq[p].tick[cmd[3].tick], cmd[2], cmd[3])
			undocmd[1] = 'remove'
		end

		-- Build undo table
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"setCmd", p, undocmd}, -- Undo command
			{"setCmd", p, redocmd} -- Redo command
		)

	end,

	-- Insert a given table of note values into a sequence
	setNotes = function(p, notes, undo)

		-- Make duplicates of the notes, to prevent reference bugs
		notes = deepCopy(notes)

		local undonotes = {}
		local redonotes = {}

		local removenotes = {}
		local addnotes = {}

		local ticks = #data.seq[p].tick

		-- Find all overlapping notes, and all to-be-removed notes
		for i = #notes, 1, -1 do

			local n = notes[i]

			-- Populate the removal-table
			for k, v in pairs(data.seq[p].tick[n.tick]) do

				-- If the incoming setNote command is for removal,
				-- and it matches the old note, then put old note into remove-table.
				-- Else if the new note matches the old note, and Cmd Mode is inactive,
				-- put old note into remove-table, and new note into add-table.
				if (n.note[1] == 'remove') and checkNoteOverlap(n, v) then
					table.insert(removenotes, deepCopy(v))
					break
				elseif (data.cmdmode ~= "cmd") and checkNoteOverlap(n, v) then
					table.insert(removenotes, deepCopy(v))
					table.insert(addnotes, table.remove(notes, i))
					break
				end

			end

		end

		-- Shift remaining incoming notes into their tables
		for k, v in pairs(notes) do
			if v.note[1] ~= 'remove' then
				table.insert(addnotes, deepCopy(v))
			end
		end

		-- Bound note duration to the end of the sequence
		for k, v in pairs(addnotes) do
			if (v.note[1] == 'note')
			and ((v.note[2] + v.note[3] - 1) > ticks)
			then
				v.note[3] = ticks - v.note[2]
			end
		end

		-- Remove all removenotes, and shape undo tables accordingly
		for k, v in pairs(removenotes) do
			for i = 1, #data.seq[p].tick[v.tick] do
				if checkNoteOverlap(v, data.seq[p].tick[v.tick][i]) then
					local rnote = table.remove(data.seq[p].tick[v.tick], i)
					table.insert(undonotes, rnote)
					table.insert(redonotes, {tick = v.tick, note = {'remove', v.note[4], v.note[5]}})
					break
				end
			end
		end

		-- Add all addnotes, and shape undo tables accordingly
		for k, v in pairs(addnotes) do
			table.insert(data.seq[p].tick[v.tick], deepCopy(v))
			table.insert(redonotes, deepCopy(v))
			table.insert(undonotes, {tick = v.tick, note = {'remove', v.note[4], v.note[5]}})
		end

		-- Build undo tables
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"setNotes", p, undonotes}, -- Undo command
			{"setNotes", p, redonotes} -- Redo command
		)

	end,

	-- Move a given table of notes in a given sequence by a given direction
	moveNotes = function(p, notes, tdir, ndir, undo)

		-- Make a duplicate of notes-table, to prevent reference bugs
		notes = deepCopy(notes)

		tdir = tdir or 0
		ndir = ndir or 0

		local nt = deepCopy(notes)

		-- Modify all copied notes' pitch and tick values by the given amounts
		for k, v in pairs(notes) do
			nt[k].tick = wrapNum(v.tick + tdir, 1, #data.seq[p].tick)
			nt[k].note[2] = nt[k].tick - 1
			if (v.note[1] == 'note') and rangeCheck(v.note[5], data.bounds.np) then
				nt[k].note[5] = wrapNum(v.note[5] + ndir, data.bounds.np)
			elseif (v.note[1] ~= 'note') and rangeCheck(v.note[4], data.bounds.np) then
				nt[k].note[4] = wrapNum(v.note[4] + ndir, data.bounds.np)
			end
		end

		notes = notesToRemove(notes)

		-- Remove old notes and add new notes, chaining this into the undo tables
		setNotes(p, notes, undo)
		setNotes(p, nt, undo)

	end,

	-- Insert a note, with the current note-var settings
	insertNote = function(dist, undo)

		local n = {}

		-- If the note/tick pointers don't exist, get temporary values
		local tempnp = data.np or 0
		local temptp = data.tp or 1

		if data.cmdmode ~= "cmd" then

			-- If a distance-from-C isn't given, set it to the note-pointer position
			dist = dist or (tempnp % 12)

			-- Get the note-pointer position, modulated by dist-offset
			local npoffset = dist + (tempnp - (tempnp % 12))
			local adjnote = clampNum(npoffset, data.bounds.np)

			n = {
				tick = temptp, -- 1-indexed tick start-time
				note = {
					'note', -- MIDI.lua item command
					temptp - 1, -- 0-indexed tick start-time
					data.dur, -- Duration (ticks)
					data.chan, -- Channel
					adjnote, -- Pitch + piano key dist
					data.velo, -- Velocity
				},
			}

			-- Send the note to the MIDI-over-UDP listener, on the user-defined port
			sendMidiMessage(n.note)

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

			n = {
				tick = temptp,
				note = {
					data.cmdtypes[data.cmdtype][3],
					temptp - 1,
					data.chan,
					data.cmdbyte1,
				},
			}

			-- For 2-byte commands, add the second Cmd-byte
			if (n.note[1] == 'key_after_touch')
			or (n.note[1] == 'control_change')
			then

				n.note[5] = data.cmdbyte2

			-- For pitch-bend commands, sum the two byte commands
			elseif n.note[1] == 'pitch_wheel_change' then

				n.note[4] = (n.note[4] * 128) + data.cmdbyte2

			end

			setCmd(data.active, {'insert', data.cmdp, n}, undo)

		end

	end,

	-- Delete the note at the current pointer position
	deleteNote = function(undo)

		local delnotes = {}

		-- If Cmd Mode is active, delete the active Non-Note
		if data.cmdmode == "cmd" then

			-- If the command-pointer corresponds to a cmd on the active tick,
			-- create a "remove" cmd, and send that cmd to setCmd.
			if #data.seq[data.active].tick[data.tp] >= data.cmdp then
				setCmd(
					data.active,
					{'remove', data.cmdp, data.seq[data.active].tick[data.tp][data.cmdp]},
					undo
				)
			end

		else -- Else, delete the active note

			-- If any notes are selected, slate them for deletion
			if #data.seldat > 0 then
				delnotes = notesToRemove(data.seldat)
			else -- Else, if no notes are selected, slate the current pointer-pos's note for deletion
				delnotes = getNotes(data.active, data.tp, data.tp, data.np, data.np, data.chan)
				delnotes = notesToRemove(delnotes)
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
			delcmds = cmdsToRemove(delcmds)

			-- If any matching cmds were found, send them through setCmd individually
			if #delcmds > 0 then
				for k, v in pairs(delcmds) do
					setCmd(data.active, v, undo)
				end
			end

		else -- Else, delete all notes on the tick

			local delnotes = getNotes(data.active, data.tp, data.tp, _, _, data.chan)
			delnotes = notesToRemove(delnotes)

			-- If any matching notes were found, send them through removeNotes
			if #delnotes > 0 then
				setNotes(data.active, delnotes, undo)
			end

		end

	end,

	-- Delete all notes in the active pitch
	deletePitchNotes = function(undo)

		local delnotes = getNotes(data.active, _, _, data.np, data.np, data.chan)
		delnotes = notesToRemove(delnotes)

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
			delcmds = cmdsToRemove(delcmds)

			-- If any matching cmds were found, send them through setCmd individually
			if #delcmds > 0 then
				for k, v in pairs(delcmds) do
					setCmd(data.active, v, undo)
				end
			end

		else -- Else, delete all notes in the beat

			local delnotes = getNotes(data.active, ltick, rtick, _, _, data.chan)
			delnotes = notesToRemove(delnotes)

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
			if v.note[1] == 'note' then
				local rand = math.random(0, data.velo)
				local newvelo = clampNum(v.note[6] + (roundNum(data.velo / 2) - rand), data.bounds.velo)
				data.seldat[k].note[6] = newvelo
			end

		end

		-- Use setNotes to replace the seq-notes with corresponding selection-tab notes
		setNotes(data.active, data.seldat, undo)

	end,

}