return {

	-- Toggle select-mode boundaries, which are dragged by the pointers
	toggleSelect = function(data, cmd)

		if cmd == "clear" then -- Clear selection-tables

			data.movedat = {}
			data.seltop = {
				x = false,
				y = false,
			}

			data.selbot = {
				x = false,
				y = false,
			}

			print("toggleSelect: cleared selection positions!")

		elseif cmd == "top" then -- Set top selection-pointer

			data.seltop = {
				x = math.min(data.tp, data.selbot.x or data.tp),
				y = math.max(data.np, data.selbot.y or data.np),
			}

			data.selbot = {
				x = math.max(data.tp, data.selbot.x or data.tp),
				y = math.min(data.np, data.selbot.y or data.np),
			}

			print("toggleSelect: set top select position!")

		elseif cmd == "bottom" then -- Set bottom selection-pointer

			data.selbot = {
				x = math.max(data.tp, data.seltop.x or data.tp),
				y = math.min(data.np, data.seltop.y or data.np),
			}

			data.seltop = {
				x = math.min(data.tp, data.seltop.x or data.tp),
				y = math.max(data.np, data.seltop.y or data.np),
			}

			print("toggleSelect: set bottom select position!")

		end

		-- Update the select area, based on current select-pointers
		data.sel = {
			l = (data.seltop.x ~= false) and math.min(data.seltop.x, data.selbot.x),
			r = (data.seltop.x ~= false) and math.max(data.seltop.x, data.selbot.x),
			t = (data.seltop.x ~= false) and math.max(data.seltop.y, data.selbot.y),
			b = (data.seltop.x ~= false) and math.min(data.seltop.y, data.selbot.y),
		}

	end,

	-- Copy the currently selected chunk of notes and ticks
	copySelection = function(data, add)

		-- If nothing is selected, select the active tick/note
		if not data.sel.l then
			data:toggleSelect()
		end

		-- Get duplicates of the selected notes
		local n = deepCopy(
			data:getNotes(
				data.active,
				data.sel.l, data.sel.r,
				data.sel.b, data.sel.t
			)
		)

		-- Reduce tick values relative to the left selection-pointer's position
		for i = 1, #n do
			n[i].tick = n[i].tick - (data.sel.l - 1)
			n[i].note[2] = n[i].tick - 1
		end

		if add then -- On additive copy...

			local newdat = {}

			-- If any incoming notes overlap with notes in the copy-table,
			-- replace those copy-table notes with the incoming notes.
			for k, v in pairs(data.copydat) do

				local onote = deepCopy(v)

				for i = #n, 1, -1 do
					if checkNoteOverlap(n, v, true) then
						onote = table.remove(n, i)
						break
					end
				end

				table.insert(newdat, onote)

			end

			-- Put remaining incoming notes into the combined copy-table
			for k, v in pairs(n) do
				table.insert(newdat, v)
			end

			n = newdat

		end

		-- Put the copied notes into the copy-table
		data.copydat = n

	end,

	-- Cut the currently selected chunk of notes and ticks
	cutSelection = function(data, add, undo)

		-- If nothing is selected, select the active tick/note
		if not data.sel.l then
			data:toggleSelect("top")
		end

		-- Copy the selection like a normal copy command
		data:copySelection(relative, add)

		-- Remove the copied notes from the seq, adding an undo command
		data:removeNotes(data.active, deepCopy(data.copydat), undo)

	end,

	-- Paste the selection-table's contents at the current pointer position
	pasteSelection = function(data, undo)

		-- Duplicate the copy-table, to prevent reference bugs
		local ptab = deepCopy(data.copydat)

		-- Adjust the contents of the paste-table relative to the tick-pointer
		for i = 1, #ptab do
			ptab[i].tick = wrapNum(
				ptab[i].tick + (data.tp - 1),
				1, #data.seq[data.active].tick
			)
			ptab[i].note[2] = ptab[i].tick - 1
		end

		-- Add the paste-notes to current seq, and create an undo command
		data:addNotes(data.active, ptab, undo)

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