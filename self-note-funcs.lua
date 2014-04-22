
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
					table.insert(outnotes, v)
				end
			end
		end

		return outnotes

	end,

	-- Move a given table of notes in a given sequence by a given direction
	moveNotes = function(data, p, notes, tdir, ndir, undo)

		-- Prevent modifications to the undo table's original referent
		undo = deepCopy(undo)

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

		-- Remove old notes and add new notes, chaining this into the undo tables
		data:removeNotes(p, notes, undo)
		undo[2] = true
		data:addNotes(p, nt, undo)

	end,

	-- Insert a given table of timestamped notes into a given sequence
	addNotes = function(data, p, notes, undo)

		-- Prevent modifications to the undo table's original referent
		undo = deepCopy(undo)

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

		-- If the sequence isn't long enough, extend its ticks
		if maxpos > #data.seq[p].tick then
			local addpoint = #data.seq[p].tick + 1
			local amt = maxpos - #data.seq[p].tick
			data:addTicks(p, addpoint, amt, undo)
			undo[2] = true
		end

		for k, v in ipairs(notes) do -- For every incoming note...

			-- Check all notes in the tick against this note, and remove note-collisions, adding them to the collide-table
			for notenum, n in ipairs(data.seq[p].tick[v.tick]) do
				if (
					(v.note[1] == 'note')
					and (n.note[1] == 'note')
					and (v.note[5] == n.note[5])
				)
				or (
					(v.note[1] ~= 'note')
					and (n.note[1] ~= 'note')
					and (v.note[1] == n.note[1])
					and (v.note[4] == n.note[4])
				)
				then
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
		data:addMetaUndoTask("removeNotes", p, undonotes, undo)
		undo[2] = true

		if #collidenotes > 0 then -- If any colliding notes were removed, add them back, but only after removing the notes that were just added
			data:addMetaUndoTask("addNotes", p, collidenotes, undo)
		end

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

		local delnotes = data:getNotes(data.active, data.tp, data.tp, data.np, data.np)

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			data:removeNotes(data.active, delnotes, undo)
		end

	end,

	-- Delete all notes in the active tick
	deleteTickNotes = function(data, undo)

		local delnotes = data:getNotes(data.active, data.tp, data.tp, _, _)

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			data:removeNotes(data.active, delnotes, undo)
		end

	end,

	-- Delete all notes in the active pitch
	deletePitchNotes = function(data, undo)

		local delnotes = {}
		local delnotes = data:getNotes(data.active, _, _, data.np, data.np)

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			data:removeNotes(data.active, delnotes, undo)
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

		-- If any matching notes were found, send them through removeNotes
		if #delnotes > 0 then
			data:removeNotes(data.active, delnotes, undo)
		end

	end,

}
