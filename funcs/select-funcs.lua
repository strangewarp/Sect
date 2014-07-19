return {

	-- Index the note-and-tick locations of all selected notes
	selectionDataToIndexes = function()

		data.selindex = {}
		for k, v in pairs(data.seldat) do
			data.selindex[v.tick] = data.selindex[v.tick] or {}
			data.selindex[v.tick][v.note[data.acceptmidi[v.note[1]][1]]] = true
		end

	end,

	-- Toggle select-mode boundaries, which are dragged by the pointers
	toggleSelect = function(cmd, tick, note)

		tick = tick or data.tp
		note = note or data.np

		if cmd == "clear" then -- Clear selection-tables, but leave selnotes alone

			data.seltop = {
				x = false,
				y = false,
			}

			data.selbot = {
				x = false,
				y = false,
			}

		elseif cmd == "top" then -- Set top selection-pointer

			data.seltop = {
				x = math.min(tick, data.selbot.x or tick),
				y = math.max(note, data.selbot.y or note),
			}

			data.selbot = {
				x = math.max(tick, data.selbot.x or tick),
				y = math.min(note, data.selbot.y or note),
			}

		elseif cmd == "bottom" then -- Set bottom selection-pointer

			data.selbot = {
				x = math.max(tick, data.seltop.x or tick),
				y = math.min(note, data.seltop.y or note),
			}

			data.seltop = {
				x = math.min(tick, data.seltop.x or tick),
				y = math.max(note, data.seltop.y or note),
			}

		elseif cmd == "all" then -- Select all

			data.selbot = {
				x = #data.seq[data.active].tick,
				y = data.bounds.np[1],
			}

			data.seltop = {
				x = 1,
				y = data.bounds.np[2],
			}

		end

		-- Update the select area, based on current select-pointers
		data.sel = {
			l = (data.seltop.x ~= false) and math.min(data.seltop.x, data.selbot.x),
			r = (data.seltop.x ~= false) and math.max(data.seltop.x, data.selbot.x),
			t = (data.seltop.x ~= false) and math.max(data.seltop.y, data.selbot.y),
			b = (data.seltop.x ~= false) and math.min(data.seltop.y, data.selbot.y),
		}

		-- Merge selected notes into selection-memory table
		if cmd ~= "clear" then
			local n = getNotes(data.active, data.sel.l, data.sel.r, data.sel.b, data.sel.t)
			data.seldat = tableCombine(n, data.seldat, false)
			data.seldat = removeDuplicates(data.seldat)
		end

		selectionDataToIndexes()

		-- If all notes were just selected, remove the selection-area
		if cmd == "all" then
			toggleSelect("clear")
		end

	end,

	-- Clear the select-table
	clearSelectMemory = function()

		-- Clear the currently on-screen selection
		toggleSelect("clear")

		-- If something is selected, remove all non-selected notes from seldat
		if data.sel.l ~= false then

			-- Get a table of all currently-selected notes
			local n = getNotes(data.active, data.sel.l, data.sel.r, data.sel.b, data.sel.t)

			-- Match all seldat notes against the subset of selected notes
			for i = #data.seldat, 1, -1 do

				local keep = false

				-- If a match is found, earmark the note as a keeper
				for k, v in pairs(n) do
					if checkNoteOverlap(data.seldat[i], v) then
						table.remove(n, k)
						keep = true
						break
					end
				end

				-- If the note is outside the selected-notes, remove it
				if not keep then
					table.remove(data.seldat, i)
				end

			end

		else -- If nothing is selected, clear the selection table
			data.seldat = {}
		end

		selectionDataToIndexes()

	end,

	-- Remove notes that no longer exist from the select-table
	removeOldSelectItems = function()

		for i = #data.seldat, 1, -1 do

			local n = data.seldat[i]
			local r = 0

			-- If the corresponding tick doesn't exist anymore, remove the entry
			if data.seq[data.active].tick[n.tick] == nil then

				table.remove(data.seldat, i)
				r = r + 1

			else -- If the corresponding tick still exists...

				local match = false

				-- For every note in the seldat item's tick,
				-- if there's a note overlap, replace selnote entry with seq entry.
				for k, v in pairs(data.seq[data.active].tick[n.tick]) do
					if checkNoteOverlap(n, v) then
						data.seldat[i] = deepCopy(v)
						match = true
						break
					end
				end

				-- If no matching notes were found, remove the seldat entry
				if not match then
					table.remove(data.seldat, i)
					r = r + 1
				end

			end

			-- Skip downwards by the number of entries removed
			i = i - r

		end

	end,

	-- Copy the currently selected chunk of notes and ticks
	copySelection = function(add)

		-- Get duplicates of the notes in selection-memory
		local n = deepCopy(data.seldat)

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
	cutSelection = function(add, undo)

		-- Copy the selected notes
		copySelection(add)

		-- Remove the selected notes from the seq
		setNotes(data.active, notesToRemove(deepCopy(data.seldat)), undo)

	end,

	-- Paste the selection-table's contents at the current pointer position
	pasteSelection = function(undo)

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
		setNotes(data.active, ptab, undo)

	end,

	-- Modify the selected notes
	modNotes = function(cmd, dist, undo)

		local notes = {}
		if #data.seldat == 0 then
			notes = getNotes(data.active, data.tp, data.tp, data.np, data.np)
		else
			notes = deepCopy(data.seldat)
		end

		-- If no notes were received, abort function
		if #notes == 0 then
			print("modNotes: no notes were sent to this function!")
			return nil
		end

		local modtypes = {
			tp = 2,
			dur = 3,
			chan = 4,
			np = 5,
			velo = 6,
		}

		-- If the command type is unknown, abort function
		if modtypes[cmd] == nil then
			print(cmd)
			print("modNotes: warning: received unknown command type!")
			return nil
		end

		local oldnotes = {}
		local newnotes = {}
		local index = modtypes[cmd]

		-- For all incoming notes...
		for k, v in pairs(notes) do

			-- Only move note-commands
			if v.note[1] == 'note' then

				local temp = deepCopy(v)
				local changed = false

				-- Shift the temp-values
				if data.bounds[cmd] then
					temp.note[index] = wrapNum(temp.note[index] + dist, data.bounds[cmd])
					changed = true
				elseif index == 2 then
					temp.tick = wrapNum(
						temp.tick + (dist * data.spacing),
						1,
						#data.seq[data.active].tick
					)
					temp.note[2] = temp.tick - 1
					changed = true
				end

				-- If duration was changed, keep it from overlapping sequence length
				if index == 3 then
					temp.note[index] = clampNum(
						temp.note[index],
						1,
						#data.seq[data.active].tick - temp.note[2]
					)
				end

				-- If the modification resulted in a change,
				-- add the notes to the update-tables
				if changed then
					table.insert(oldnotes, v)
					table.insert(newnotes, temp)
				end

			end

		end

		-- Turn the old notes into removal-commands
		oldnotes = notesToRemove(oldnotes)

		-- Remove the old notes, and add the modified notes
		setNotes(data.active, oldnotes, undo)
		setNotes(data.active, newnotes, undo)

		-- Replace the selection-table with the newly-positioned notes
		data.seldat = newnotes

	end,

}