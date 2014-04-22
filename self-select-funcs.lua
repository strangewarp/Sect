return {

		-- Grab all notes from the selection range
	getNotesFromSelection = function(data)

		-- If the selection range isn't active, return an empty table
		if not data.sel.l then
			print("getNotesFromSelection: warning: selection boundaries undefined!")
			return {}
		end

		local outnotes = {}

		local iterated = false
		local limit = #data.seq[data.active].tick
		local x = ((data.sel.l - 2) % limit) + 1

		while (x ~= data.sel.r) -- While x hasn't reached the right boundary...
		or (not iterated) -- Or the loop hasn't yet iterated once...
		do -- Grab the notes from within the selection
			x = (x % limit) + 1
			iterated = true
			for k, v in pairs(data.seq[data.active].tick[x]) do
				if rangeCheck(v.note[5], data.sel.b, data.sel.t) then
					table.insert(outnotes, deepCopy(v))
				end
			end
		end

		return outnotes

	end,

	-- Toggle select-mode boundaries, which are dragged by the pointers
	toggleSelect = function(data, cmd)

		-- Set selection-table target names
		local s1, s2 = "ls", "rs"

		if cmd == "clear" then -- Clear selection-tables and abort function
			data.movedat = {}
			data.ls = {x = false, y = false}
			data.rs = {x = false, y = false}
			data.sel = {
				l = false,
				r = false,
				t = false,
				b = false,
			}
			print("toggleSelect: cleared selection positions!")
			return nil
		elseif cmd == "left" then -- Prepare to set left selection-table
			print("toggleSelect: setting lefthand selection pointer")
		elseif cmd == "right" then -- Prepare to set right selection-table instead
			s1, s2 = s2, s1
			print("toggleSelect: setting righthand selection pointer")
		else -- If an unknown command was received, abort function
			print("toggleSelect: warning: received unknown cmd, \"" .. cmd .. "\"!")
			return nil
		end

		-- Set the selection-point specified by cmd
		data[s1] = {
			x = data.tp,
			y = data.np,
		}

		-- Set other selection-point similarly, if it doesn't already hold values
		data[s2] = {
			x = data[s2].x or data[s1].x,
			y = data[s2].y or data[s1].y,
		}

		-- Update concrete selection borders
		data.sel = {
			l = data.ls.x,
			r = data.rs.x,
			t = math.max(data.ls.y, data.rs.y),
			b = math.min(data.ls.y, data.rs.y),
		}

		print("toggleSelect: selection pointer positions:")
		print("left: x" .. data.ls.x .. ", y" .. data.ls.y)
		print("right: x" .. data.rs.x .. ", y" .. data.rs.y)

	end,

	-- Copy the currently selected chunk of notes and ticks
	copySelection = function(data, relative, add)

		-- If nothing is selected, abort function
		if not data.ls.x then
			print("copySelection: warning: nothing was selected!")
			return nil
		end

		-- If additive copy, grab the copy-tables. Else make new tables
		local concout = (add and deepCopy(copydat)) or {}
		local relout = (add and deepCopy(copyrel)) or {}

		local relxdist = 0
		local relydist = 0

		local iterated = false
		local limit = #data.seq[data.active].tick
		local tick = ((data.sel.l - 2) % limit) + 1
		
		while (tick ~= data.sel.r) -- While tick hasn't reached right boundary...
		or (not iterated) -- Or if the loop hasn't iterated at least once...
		do

			tick = (tick % limit) + 1
			iterated = true

			-- For every note in the vertical copy range...
			for notenum, note in pairs(data.seq[data.active].tick[tick]) do

				-- If the note falls within range, copy it
				if rangeCheck(note.note[5], data.sel.b, data.sel.t) then

					local concnote = deepCopy(note)
					local relnote = deepCopy(note)

					-- If copy-type is relative, shift copied notes' internal values
					-- relative to the selection's boundaries,
					-- and keep track of the relative-select-window's size
					if relative then

						relnote.tick = data.sel.l + (tick - data.sel.l)
						relnote.note[2] = relnote.tick - 1
						relnote.note[5] = data.sel.b + (note - data.sel.b)

						relxdist = math.max(relxdist, relnote.tick)
						relydist = math.max(relydist, relnote.note[5])

					end

					-- Match notes against other notes in the copy-tables,
					-- and overwrite any conflicts
					for k, v in pairs(concout) do
						if (v.note[5] == concnote.note[5])
						and (v.tick == concnote.tick)
						then
							table.remove(concout, k)
							break
						end
					end
					for k, v in pairs(relout) do
						if (v.note[5] == relnote.note[5])
						and (v.tick == relnote.tick)
						then
							table.remove(relout, k)
							break
						end
					end

					-- Put the notes into the outgoing copy-tables
					table.insert(concout, concnote)
					table.insert(relout, relnote)

				end

			end

		end

		if add then -- If this is an additive copy...

			-- Expand the concrete copy-area borders
			data.copy.l = math.min(data.copy.l, data.sel.l)
			data.copy.r = math.max(data.copy.r, data.sel.r)
			data.copy.t = math.max(data.copy.t, data.sel.t)
			data.copy.b = math.min(data.copy.b, data.sel.b)

			-- Expand the relative copy-area size
			data.copyrel.x = math.max(data.copyrel.x, relxdist)
			data.copyrel.y = math.max(data.copyrel.y, relydist)

		else -- If this is a non-additive copy...

			-- Set the absolute copy-range equal to the selection-range
			data.copy = deepCopy(data.sel)

			-- Set the relative copy range equal to the relative note-boundaries
			data.copyrel.x = relxdist
			data.copyrel.y = relydist

		end

		-- Save copied relative and absolute notes to the copy-data tables
		data.copydat = concout
		data.reldat = relout

	end,

	-- Cut the currently selected chunk of notes and ticks
	cutSelection = function(data, relative, add, undo)

		-- If nothing is selected, abort function
		if not data.sel.l then
			print("copySelection: warning: nothing was selected!")
			return nil
		end

		-- Copy the selection like a normal copy command
		data:copySelection(relative, add)

		-- Remove the copied notes from the seq,
		-- forming a chained undo during removal
		data:removeNotes(data.active, data.copydat, undo)

	end,

	-- Paste the selection-table's contents at the current pointer position
	pasteSelection = function(data, relative, undo)

		local outtab = {}
		local xbase = data.tp
		local ybase = (relative and data.np) or 0

		if relative then -- If relative-paste, add note-pointer to copied pitches
			outtab = deepCopy(data.reldat)
			for k, v in pairs(outtab) do
				outtab[k].note[5] = wrapNum(v.note[5] + ybase, data.bounds.np)
			end
		else -- If absolute-paste, convey the copied notes straightforwardly
			outtab = deepCopy(data.copydat)
		end

		data:addNotes(data.active, outtab, undo)

	end,

	-- Modify a given set of notes
	modNotes = function(data, cmd, notes, dist, undo)

		-- If no notes were received, abort function
		if #notes == 0 then
			print("modNotes: no notes were sent to this function!")
			return nil
		end

		local modtypes = {
			dur = 3,
			chan = 4,
			velo = 6,
		}

		-- If the command type is unknown, abort function
		if modtypes[name] == nil then
			print("modNotes: warning: received unknown command type!")
			return nil
		end

		local oldnotes = {}
		local newnotes = {}
		local index = modtypes[name]

		-- For all incoming notes...
		for k, v in pairs(notes) do

			-- If the note exists, modify it in the specified way
			for num, comp in pairs(data.seq[data.active].tick[v.tick]) do

				if orderedCompare(v.note, comp.note) then

					local temp = data.seq[data.active].tick[v.tick][num]
					local pos = modtypes[name]
					local r = data.bounds[name]

					-- For a given attribute, change its data
					temp.note[index] = temp.note[index] + dist
					temp.note[index] = r[1] and math.max(r[1], temp.note[index])
					temp.note[index] = r[2] and math.min(r[2], temp.note[index])

					-- If the modification resulted in a change,
					-- add the notes to the update-tables
					if not orderedCompare(temp.note, comp.note) then
						table.insert(oldnotes, comp)
						table.insert(newnotes, temp)
					end

					break

				end

			end

		end

		-- Remove the old notes
		data:removeNotes(data.active, oldnotes, undo)

		-- Add the modified notes, and collapse into the same undo command
		undo[2] = true
		data:addNotes(data.active, newnotes, undo)

	end,

	-- Modify all selected notes in a given manner
	modSelectedNotes = function(data, dist, undo)

		-- If there is no selection, set it to the pointer position;
		-- Grab notes regardless;
		-- If there was no selection, unset sel-pointer positions
		local notes = {}
		if not data.sel.l then
			data:toggleSelect("left")
			data:toggleSelect("right")
			notes = data:getNotesFromSelection()
			data:toggleSelect("clear")
		else
			notes = data:getNotesFromSelection()
		end

		-- Modify the notes within the select range
		data:modNotes(data.curcmd, notes, dist, undo)

	end,

	-- Move the movedat notes, or the selected notes,
	-- or the active note if nothing is selected, in that order of precedence.
	moveCopyNotes = function(data, xdist, ydist, undo)

		-- If the move-tab is empty, fill it from selection range
		if #data.movedat == 0 then
			data.movedat = data:getNotesFromSelection()
		end

		-- If the move-tab is STILL empty, abort function
		if #data.movedat == 0 then
			print("moveNotes: warning: no notes were selected or tabbed!")
			return nil
		end

		-- Clear the selection, leaving only the movedat-table uncleared
		data.ls = {x = false, y = false}
		data.rs = {x = false, y = false}
		data.sel = {
			l = false,
			r = false,
			t = false,
			b = false,
		}

		-- Remove the movedat notes from where they presently sit
		data:removeNotes(data.active, data.movedat, undo)
		undo[2] = true

		-- For every note that is tabled for movement...
		local limit = #data.seq[data.active].tick
		for i = 1, #data.movedat do

			-- Move all notes by the specified amount on the tick/note grid
			data.movedat[i].tick = wrapNum(data.movedat[i].tick + xdist, 1, limit)
			data.movedat[i].note[2] = data.movedat[i].tick - 1
			data.movedat[i].note[5] = wrapNum(data.movedat[i].note[5] + ydist, data.bounds.np)

			-- Find and remove notes that occupy the shift-adjusted spaces
			local collidenotes = {}
			for k, v in pairs(data.seq[data.active].tick[data.movedat[i].tick]) do
				if data.movedat[i].note[5] == v.note[5] then
					table.insert(collidenotes, v)
				end
			end
			if #collidenotes > 0 then
				data:removeNotes(data.active, collidenotes, undo)
			end

		end

		-- Set the undo to collect-mode, and add the notes in new positions
		data:addNotes(data.active, data.movedat, undo)

	end,

	-- Move all notes within the selection range
	moveSelectedNotes = function(data, xdist, ydist, undo)

		if not data.sel.l then -- If there is no selection, select pointer-position
			data:toggleSelect("left")
			data:toggleSelect("right")
			data:moveCopyNotes(xdist, ydist, undo)
			data:toggleSelect("clear")
		else -- If a selection exists, call moveNotes normally
			data:moveCopyNotes(xdist, ydist, undo)
		end

	end,

}