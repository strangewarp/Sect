return {

	-- Toggle select-mode boundaries, which are dragged by the pointers
	toggleSelect = function(cmd, tick, note)

		tick = tick or D.tp
		note = note or D.np

		if cmd == "clear" then -- Clear selection-tables, but leave selnotes alone

			D.seltop = {
				x = false,
				y = false,
			}

			D.selbot = {
				x = false,
				y = false,
			}

		elseif cmd == "top" then -- Set top selection-pointer

			D.seltop = {
				x = math.min(tick, D.selbot.x or tick),
				y = math.max(note, D.selbot.y or note),
			}

			D.selbot = {
				x = math.max(tick, D.selbot.x or tick),
				y = math.min(note, D.selbot.y or note),
			}

		elseif cmd == "bottom" then -- Set bottom selection-pointer

			D.selbot = {
				x = math.max(tick, D.seltop.x or tick),
				y = math.min(note, D.seltop.y or note),
			}

			D.seltop = {
				x = math.min(tick, D.seltop.x or tick),
				y = math.max(note, D.seltop.y or note),
			}

		elseif cmd == "all" then -- Select all

			D.selbot = {
				x = D.seq[D.active].total,
				y = D.bounds.np[1],
			}

			D.seltop = {
				x = 1,
				y = D.bounds.np[2],
			}

		end

		-- Update the select area, based on current select-pointers
		D.sel = {
			l = (D.seltop.x ~= false) and math.min(D.seltop.x, D.selbot.x),
			r = (D.seltop.x ~= false) and math.max(D.seltop.x, D.selbot.x),
			t = (D.seltop.x ~= false) and math.max(D.seltop.y, D.selbot.y),
			b = (D.seltop.x ~= false) and math.min(D.seltop.y, D.selbot.y),
		}

		-- Merge selected notes from the active seq's active channel into selection-memory table
		if cmd ~= "clear" then

			local ntab
			if cmd == "chan" then -- If chan-command, select notes from active channel only
				ntab = getNotes(D.active, D.sel.l, D.sel.r, D.sel.b, D.sel.t, D.chan)
			else -- Else, select all notes
				ntab = getNotes(D.active, D.sel.l, D.sel.r, D.sel.b, D.sel.t, _)
			end

			local seltab = getContents(D.seldat, {pairs, pairs, pairs})

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

		D.seldat = {}

		if (not n) or (#n == 0) then
			return nil
		end

		for k, v in pairs(n) do
			buildTable(D.seldat, {v[2] + 1, v[4], v[5]}, v)
		end

	end,

	-- Clear the select-table
	clearSelectMemory = function()

		-- Clear the currently on-screen selection
		toggleSelect("clear")

		-- Clear all selected notes
		D.seldat = {}

		local n = {}

		-- If a select-range still exists, get the notes fro within it
		if D.sel.l ~= false then
			n = getNotes(D.active, D.sel.l, D.sel.r, D.sel.b, D.sel.t)
		end

		populateSelTable(n)

	end,

	-- Remove notes that no longer exist from the select-table
	removeOldSelectItems = function()

		if not D.active then
			D.seldat = {}
		else

			local selnotes = getContents(D.seldat, {pairs, pairs, pairs})

			for nk, n in ripairs(selnotes) do
				if not getIndex(D.seq[D.active].tick, {n[2] + 1, 'note', n[4], n[5]}) then
					copyUnsetCascade('seldat', n)
				end
			end

		end

	end,

	-- Copy the currently selected chunk of notes and ticks
	copySelection = function()

		-- Reset the copy-offset value
		D.copyoffset = 0

		-- If there is no selection window, use tick-pointer for offset
		local offpoint = D.sel.l or D.tp

		-- Copy the select-table's contents into the copy-table, and get their flattened contents
		D.copydat = deepCopy(D.seldat)
		local selitems = getContents(D.seldat, {pairs, pairs, pairs})

		-- Put the select-table's contents into the copy-table, with an offset based on tick-pointer position
		if next(D.copydat) ~= nil then
			local tleft = math.huge
			for _, n in pairs(selitems) do
				tleft = math.min(tleft, n[2])
			end
			D.copyoffset = D.tp - 1
		end

	end,

	-- Cut the currently selected chunk of notes and ticks
	cutSelection = function(undo)

		-- Copy the selected notes
		copySelection()

		-- Put select-notes into a flat table, flagged for removal
		local remnotes = getContents(D.seldat, {pairs, pairs, pairs})
		remnotes = notesToSetType(remnotes, 'remove')

		-- Remove the selected notes from the seq
		setNotes(D.active, remnotes, undo)

		-- Empty out the select-table, since its corresponding notes have been removed
		D.seldat = {}

	end,

	-- Paste the copy-table's contents at the current pointer position
	pasteSelection = function(undo)

		-- Flatten the copy-table into a paste-table
		local paste = getContents(D.copydat, {pairs, pairs, pairs})

		-- Adjust the contents of the paste-table relative to the tick-pointer, using the offset
		for i = 1, #paste do
			paste[i][2] = wrapNum(
				(D.tp - 1) + (paste[i][2] - D.copyoffset),
				0,
				D.seq[D.active].total - 1
			)
			paste[i] = {'insert', paste[i]} -- Format each paste-note-table into a setNotes command
		end

		-- Add the paste-notes to current seq, and create an undo command
		setNotes(D.active, paste, undo)

	end,

	-- Paste the selection-table's contents, repeating them across the entire seq
	pasteRepeating = function(undo)

		-- If there are no copied notes, abort function
		if next(D.copydat) == nil then
			return nil
		end

		local ticks = D.seq[D.active].total
		local size = -math.huge
		local iter = 1

		-- Flatten the copy-table into a paste-table
		local paste = getContents(D.copydat, {pairs, pairs, pairs})
		local pasteout = {}

		-- For every flattened paste-note, get the copy-chunk's furthest rightward boundary
		for _, n in pairs(paste) do
			local testsize = (n[2] - D.copyoffset) + n[3]
			if size < testsize then
				size = testsize
			end
		end

		-- While the repeating-paste hasn't fully looped around the sequence,
		-- continue pasting the contents of the copydat table at increasing offsets.
		local oldtp = D.tp
		while (iter * size) <= ticks do
			pasteSelection(undo)
			D.tp = D.tp + size
			iter = iter + 1
		end
		D.tp = oldtp

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

		local bot = D.np
		local top = clampNum(D.np + D.dur, D.bounds.np)

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
						wrapNum((D.tp - 1) + (D.spacing * (k - 1)), 0, D.seq[D.active].total - 1),
						math.max(D.spacing, 1),
						D.chan,
						wrapNum(byte, bot, top),
						D.velo,
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
						wrapNum((D.tp - 1) + (D.spacing * (i - 1)), 0, D.seq[D.active].total - 1),
						math.max(D.spacing, 1),
						D.chan,
						wrapNum(byte, bot, top),
						D.velo,
					}
					table.insert(notes, {'insert', n})
				end
			end
		end

		setNotes(D.active, notes, undo)

	end,

}