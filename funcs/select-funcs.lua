return {

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

		-- Merge selected notes from the active seq's active channel into selection-memory table
		if cmd ~= "clear" then

			local n
			if cmd == "chan" then -- If chan-command, select notes from active channel only
				n = getNotes(data.active, data.sel.l, data.sel.r, data.sel.b, data.sel.t, data.chan)
			else -- Else, select all notes
				n = getNotes(data.active, data.sel.l, data.sel.r, data.sel.b, data.sel.t, _)
			end

			populateSelTable(n)

		end

		-- If all notes were just selected, remove the selection-area
		if cmd == "all" then
			toggleSelect("clear")
		end

	end,

	-- Shunt a table of unordered notes into seldat ordering
	populateSelTable = function(n)

		data.seldat = {}

		if (not n) or (#n == 0) then
			return nil
		end

		for k, v in pairs(n) do
			buildTable(data.seldat, {v[2] + 1, v[4], v[5]}, v)
		end

	end,

	-- Clear the select-table
	clearSelectMemory = function()

		-- Clear the currently on-screen selection
		toggleSelect("clear")

		-- Clear all selected notes
		data.seldat = {}

		local n = {}

		-- If a select-range still exists, get the notes fro within it
		if data.sel.l ~= false then
			n = getNotes(data.active, data.sel.l, data.sel.r, data.sel.b, data.sel.t)
		end

		populateSelTable(n)

	end,

	-- Remove notes that no longer exist from the select-table
	removeOldSelectItems = function()

		if not data.active then
			data.seldat = {}
		else

			local selnotes = getContents(data.seldat, {pairs, pairs, pairs})

			for nk, n in ripairs(selnotes) do
				local exists = getIndex(data.seq[data.active].tick, {n[2] + 1, 'note', n[4], n[5]})
				if not exists then
					copyUnsetCascade('seldat', n)
				end
			end

		end

	end,

	-- Copy the currently selected chunk of notes and ticks
	copySelection = function(add)

		-- Get duplicates of the notes in selection-memory
		local s = deepCopy(data.seldat)

		-- If there is no selection window, use tick-pointer for offset
		local offpoint = data.sel.l or data.tp

		-- If this isn't an additive copy, clear the copy-table
		if not add then
			data.copydat = {}
		end

		-- Put the select-table's contents into the copy-table
		for tk, t in pairs(s) do
			for ck, c in pairs(t) do
				for nk, n in pairs(c) do
					buildTable(data.copydat, {tk, ck, nk}, deepCopy(n))
				end
			end
		end

		-- If any notes have been copied, get a pointer-offset value
		if #data.copydat > 0 then

			-- Search for lowest tick, and create an offset value based on it
			local offset = offpoint
			local contents = getContents(s, {pairs, pairs, pairs})
			for _, n in pairs(contents) do
				local newoff = n[2] - data.tp
				offset = math.min(offset, newoff)
			end

			-- Set the copy-table's corresponding offset value
			data.copyoffset = offset

		else -- Else, if copy-tab is empty, set copy-pointer-offset to 0
			data.copyoffset = 0
		end

	end,

	-- Cut the currently selected chunk of notes and ticks
	cutSelection = function(add, undo)

		-- Copy the selected notes
		copySelection(add)

		-- Put select-notes into a flat table, flagged for removal
		local remnotes = getContents(data.seldat, {pairs, pairs, pairs})
		for k, v in pairs(remnotes) do
			remnotes[k] = {'remove', v}
		end

		-- Remove the selected notes from the seq
		setNotes(data.active, remnotes, undo)

		-- Empty out the select-table, since its corresponding notes have been removed
		data.seldat = {}

	end,

	-- Paste the copy-table's contents at the current pointer position
	pasteSelection = function(undo)

		-- Flatten the copy-table into a paste-table
		local paste = getContents(data.copydat, {pairs, pairs, pairs})

		-- Adjust the contents of the paste-table relative to the tick-pointer, using the offset
		for i = 1, #paste do
			paste[i][2] = wrapNum(
				paste[i][2] + data.tp + data.copyoffset,
				0,
				#data.seq[data.active].tick - 1
			)
		end

		-- Format the paste-table into setNotes commands
		for k, v in pairs(paste) do
			paste[k] = {'insert', v}
		end

		-- Add the paste-notes to current seq, and create an undo command
		setNotes(data.active, paste, undo)

	end,

	-- Paste the selection-table's contents, repeating them across the entire seq
	pasteRepeating = function(undo)

		-- If there are no copied notes, abort function
		if #data.copydat == 0 then
			return nil
		end

		local ticks = #data.seq[data.active].tick
		local tleft = math.huge
		local tright = -math.huge
		local iter = 1

		-- Flatten the copy-table into a paste-table
		local paste = getContents(data.copydat, {pairs, pairs, pairs})

		-- For every flattened paste-note...
		for _, n in pairs(paste) do

			-- Get the copy-chunk's furthest left and right bounds
			local testright = n[2] + n[3]
			if tleft > n[2] then
				tleft = n[2]
			end
			if tright < testright then
				tright = testright
			end

		end

		-- Get the copydat range's total size
		local size = tright + math.abs(tleft)

		-- While the repeating-paste hasn't fully looped around the sequence,
		-- continue pasting the contents of the copydat table at increasing offsets.
		while (iter * size) <= ticks do

			-- Adjust the contents of the paste-table relative to the tick-pointer,
			-- increasing the paste-chunk multiplier on each iteration.
			for k, v in pairs(paste) do
				paste[k][2] = wrapNum(
					v + data.tp + ((iter - 1) * size),
					0, ticks - 1
				)
			end

			iter = iter + 1

		end

		-- Format the paste-table into setNotes commands
		for k, v in pairs(paste) do
			paste[k] = {'insert', v}
		end

		-- Add the paste-notes to current seq, and create an undo command
		setNotes(data.active, paste, undo)

	end,

}