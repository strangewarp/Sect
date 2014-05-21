
return {

	-- Get the notes from a given slice of the sequence
	getNotes = function(data, p, tbot, ttop, nbot, ntop)

		-- Set parameters to default if any are empty
		tbot = tbot or 1
		ttop = ttop or #data.seq[p].tick
		nbot = nbot or data.bounds.np[1]
		ntop = ntop or data.bounds.np[2]

		local outnotes = {}

		-- Grab all notes within the given range, and put them in outnotes-table
		for t = tbot, ttop do
			for k, v in pairs(data.seq[p].tick[t]) do
				if ((v.note[1] == 'note') and rangeCheck(v.note[5], nbot, ntop))
				or ((v.note[1] ~= 'note') and rangeCheck(v.note[4], nbot, ntop))
				then -- If the note is within note-range, grab it
					table.insert(outnotes, deepCopy(v))
				end
			end
		end

		return outnotes

	end,

	-- Insert a given table of note values into a sequence
	setNotes = function(data, p, notes, undo)

		-- Make duplicates of the notes, to prevent reference bugs
		notes = deepCopy(notes)

		local undonotes = {}
		local redonotes = {}

		local removenotes = {}
		local addnotes = {}

		-- Find all overlapping notes, and all to-be-removed notes
		for i = #notes, 1, -1 do

			local n = notes[i]

			-- Populate the removal-table
			for k, v in pairs(data.seq[p].tick[n.tick]) do

				-- If the incoming setNote command is for removal,
				-- and it matches the old note, then put old note into remove-table.
				-- Else if the new note matches the old note,
				-- put old note into remove-table, and new note into add-table.
				if (n.note[1] == 'remove') and checkNoteOverlap(n, v) then
					table.insert(removenotes, deepCopy(v))
					break
				elseif checkNoteOverlap(n, v) then
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

		-- Remove all removenotes, and shape undo tables accordingly
		for k, v in pairs(removenotes) do
			for i = 1, #data.seq[p].tick[v.tick] do
				if checkNoteOverlap(v, data.seq[p].tick[v.tick][i]) then
					local rnote = table.remove(data.seq[p].tick[v.tick], i)
					table.insert(undonotes, rnote)
					table.insert(redonotes, {tick = v.tick, note = {'remove', v.note[5]}})
					break
				end
			end
		end

		-- Add all addnotes, and shape undo tables accordingly
		for k, v in pairs(addnotes) do
			table.insert(data.seq[p].tick[v.tick], deepCopy(v))
			table.insert(redonotes, deepCopy(v))
			table.insert(undonotes, {tick = v.tick, note = {'remove', v.note[5]}})
		end

		-- Build undo tables
		data:addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"setNotes", p, undonotes}, -- Undo command
			{"setNotes", p, redonotes} -- Redo command
		)

	end,

	-- Move a given table of notes in a given sequence by a given direction
	moveNotes = function(data, p, notes, tdir, ndir, undo)

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
			print("DYE 1: " .. nt[k].tick .. " " .. nt[k].note[2] .. " " .. nt[k].note[5]) --DEBUGGING
		end

		notes = notesToRemove(notes)

		-- Remove old notes and add new notes, chaining this into the undo tables
		data:setNotes(p, notes, undo)
		data:setNotes(p, nt, undo)

	end,

	-- Insert a note, with the current note-var settings
	insertNote = function(data, dist, undo)

		-- If no sequences are loaded, abort function
		if data.active == false then
			print("insertNote: warning: no active sequence!")
			return nil
		end

		-- If a distance-from-C isn't given, set it to the note-pointer position
		dist = dist or (data.np % 12)

		-- Get the note-pointer position, modulated by dist-offset
		local npoffset = dist + (data.np - (data.np % 12))

		local n = {
			tick = data.tp, -- 1-indexed tick start-time
			note = {
				'note', -- MIDI.lua item command
				data.tp - 1, -- 0-indexed tick start-time
				data.dur, -- Duration (ticks)
				data.chan, -- Channel
				clampNum(npoffset, data.bounds.np), -- Pitch + piano key dist
				data.velo, -- Velocity
			},
		}

		data:setNotes(data.active, {n}, undo)

		data:moveTickPointer(1) -- Move ahead by one spacing unit

	end,

	-- Delete the note at the current pointer position
	deleteNote = function(data, undo)

		local delnotes = data:getNotes(data.active, data.tp, data.tp, data.np, data.np)
		delnotes = notesToRemove(delnotes)

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			data:setNotes(data.active, delnotes, undo)
		end

	end,

	-- Delete all notes in the active tick
	deleteTickNotes = function(data, undo)

		local delnotes = data:getNotes(data.active, data.tp, data.tp, _, _)
		delnotes = notesToRemove(delnotes)

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			data:setNotes(data.active, delnotes, undo)
		end

	end,

	-- Delete all notes in the active pitch
	deletePitchNotes = function(data, undo)

		local delnotes = data:getNotes(data.active, _, _, data.np, data.np)
		delnotes = notesToRemove(delnotes)

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			data:setNotes(data.active, delnotes, undo)
		end

	end,

	-- Delete all notes in the active beat
	deleteBeatNotes = function(data, undo)

		-- Find the beginning and end of the current beat
		local ltick = data.tp
		while wrapNum(ltick, 1, data.tpq * 4) ~= 1 do
			ltick = ltick - 1
		end
		local rtick = math.min(#data.seq[data.active].tick, (ltick + (data.tpq * 4)) - 1)

		local delnotes = data:getNotes(data.active, ltick, rtick, _, _)
		delnotes = notesToRemove(delnotes)

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			data:setNotes(data.active, delnotes, undo)
		end

	end,

}
