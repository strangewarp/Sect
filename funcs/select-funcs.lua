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
				x = data.seq[data.active].total,
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

			local ntab
			if cmd == "chan" then -- If chan-command, select notes from active channel only
				ntab = getNotes(data.active, data.sel.l, data.sel.r, data.sel.b, data.sel.t, data.chan)
			else -- Else, select all notes
				ntab = getNotes(data.active, data.sel.l, data.sel.r, data.sel.b, data.sel.t, _)
			end

			local seltab = getContents(data.seldat, {pairs, pairs, pairs})

			ntab = tableCombine(ntab, seltab)
			ntab = removeDuplicates(ntab)

			populateSelTable(ntab)

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
				if not getIndex(data.seq[data.active].tick, {n[2] + 1, 'note', n[4], n[5]}) then
					copyUnsetCascade('seldat', n)
				end
			end

		end

	end,

	-- Copy the currently selected chunk of notes and ticks
	copySelection = function(add)

		-- If there is no selection window, use tick-pointer for offset
		local offpoint = data.sel.l or data.tp

		-- If this isn't an additive copy, clear the copy-table
		if not add then
			data.copydat = {}
		end

		-- Get the contents of the selection-table
		local selitems = getContents(data.seldat, {pairs, pairs, pairs})

		-- Put the select-table's contents into the copy-table
		for _, n in pairs(selitems) do
			buildTable(data.copydat, {n[2] + 1, n[4], n[5]}, deepCopy(n))
		end

		-- If any notes have been copied, get a pointer-offset value
		if #data.copydat > 0 then

			-- Search for lowest tick, and create an offset value based on it
			local offset = offpoint
			for _, n in pairs(selitems) do
				local newoff = data.tp - (n[2] + 1)
				offset = math.max(offset, newoff)
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
		remnotes = notesToSetType(remnotes, 'remove')

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
				(paste[i][2] + data.tp) - data.copyoffset,
				0,
				data.seq[data.active].total - 1
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

		local ticks = data.seq[data.active].total
		local tleft = math.huge
		local tright = -math.huge
		local iter = 1

		-- Flatten the copy-table into a paste-table
		local paste = getContents(data.copydat, {pairs, pairs, pairs})
		local pasteout = {}

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
				table.insert(pasteout, #pasteout + 1, deepCopy(v))
				pasteout[#pasteout][2] = wrapNum(
					(v[2] + data.tp + ((iter - 1) * size)) - data.copyoffset,
					0,
					ticks - 1
				)
			end

			print("ping! " .. #pasteout)--debugging

			iter = iter + 1

		end

		-- Format the paste-table into setNotes commands
		for k, v in pairs(pasteout) do
			pasteout[k] = {'insert', v}
		end

		-- Add the paste-notes to current seq, and create an undo command
		setNotes(data.active, pasteout, undo)

	end,

	-- Paste text from the system's clipboard as a series of MIDI notes
	pasteFromText = function(kind, undo)

		local cdata = love.system.getClipboardText()

		-- If nothing is in the system's clipboard, abort function
		if #cdata == 0 then
			return nil
		end

		-- Replace all non-letter characters with spaces
		cdata = cdata:gsub("%A+", " ")

		-- Trim incoming text-data to a sane amount (500 characters or less)
		if #cdata > 500 then
			cdata = cdata:sub(1, 500)
		end

		local bot = data.np
		local top = clampNum(data.np + data.dur, data.bounds.np)

		local notes = {}

		if kind == "poly" then
			local k = 0
			for v in cdata:gmatch("%g+") do
				print("ping!")--debugging
				k = k + 1
				for i = 1, #v do
					local byte = v:byte(i)
					local n = {
						"note",
						wrapNum((data.tp - 1) + (data.spacing * (k - 1)), 0, data.seq[data.active].total - 1),
						math.max(data.spacing, 1),
						data.chan,
						wrapNum(byte, bot, top),
						data.velo,
					}
					table.insert(notes, {'insert', n})
				end
			end
		else
			for i = 1, #cdata do
				if cdata:sub(i, i) ~= " " then
					local byte = cdata:byte(i)
					local n = {
						"note",
						wrapNum((data.tp - 1) + (data.spacing * (i - 1)), 0, data.seq[data.active].total - 1),
						math.max(data.spacing, 1),
						data.chan,
						wrapNum(byte, bot, top),
						data.velo,
					}
					table.insert(notes, {'insert', n})
				end
			end
		end

		setNotes(data.active, notes, undo)

	end,

}