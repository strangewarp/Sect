
return {
	
	-- Modify the selected notes by a given amount
	modSelectedNotes = function(byte, dist, undo)
		local seldup = getContents(data.seldat, {pairs, pairs, pairs})
		for k, v in pairs(seldup) do
			seldup[k] = {v, byte, dist}
		end
		modNotes(data.active, seldup, true, true, undo)
	end,

	-- Modify a collection of various cmds, according to their given mod-commands
	modCmds = function(p, cmds, multiply, undo)

		-- Get the given commands' positions in the given sequence, and remove them
		for ck, ctab in ripairs(cmds) do
			local c, key, byte, dist = unpack(ctab)
			if getIndex(data.seq[p].tick, {c[2] + 1, "cmd", c[4], key}) then
				setCmd(p, {'remove', key, c}, undo)
			else
				table.remove(cmds, ck)
			end
		end

		-- Take the given commands, modify their position, and put them on unclaimed keys
		for ck, ctab in pairs(cmds) do
			local c, key, byte, dist = unpack(ctab)
			local m = modByte(p, deepCopy(c), byte, dist, multiply)
			local newcheck = getIndex(data.seq[p].tick, {m[2] + 1, "cmd"})
			local newkey = (newcheck and (#newcheck + 1)) or 1
			cmds[ck] = {'insert', newkey, m}
		end

		setCmds(p, cmds, undo)

	end,

	-- Modify a collection of various notes, according to their given mod-commands
	modNotes = function(p, ntab, isselect, multiply, undo)

		local snotes = {}

		-- For every note, in order, add the mod-command's results to the snotes table
		for nk, ntab in ipairs(ntab) do

			local n, byte, dist = unpack(ntab)

			-- If the note exists in the given sequence...
			if getIndex(data.seq[p].tick, {n[2] + 1, "note", n[4], n[5]}) then

				-- Build a new note via the modByte command
				local m = modByte(p, deepCopy(n), byte, dist, multiply)

				-- Add commands to the snotes table, to remove old note and insert new note
				table.insert(snotes, {'remove', n})
				table.insert(snotes, {'insert', m})

				-- Unset the note's old selection-data entry, and build a new entry reflecting its changes
				if isselect then
					copyUnsetCascade('seldat', n)
					buildTable(data.seldat, {m[2] + 1, m[4], m[5]}, m)
				end

			end

		end

		-- Call setNotes for all tabbed modifications
		setNotes(p, snotes, undo)

	end,

	-- Take a note, modify a given byte within that note by a given amount, and return it
	modByte = function(p, note, byte, dist, multiply)

		-- If no default seq-pointer was given, set it to the active sequence,
		-- or to false if there is no active sequence.
		p = p or data.active

		-- Take a deepCopy of the note, to prevent sticky-reference bugs
		local n = deepCopy(note)

		-- If no seq-pointer was given, and no active seq exists, then return the copy of note.
		if not p then
			return n
		end

		-- If multiply-var exists and is true, multiply distance by data.spacing
		if multiply == true then
			dist = dist * math.max(1, data.spacing)
		end

		-- Get the byte-key that corresponds to the byte-command
		local bk = data.notebytes[byte]

		-- Change the byte-value, and wrap it to its proper boundaries
		if byte == "tp" then
			n[bk] = wrapNum(n[bk] + dist, 0, data.seq[p].total - 1)
		elseif byte == "dur" then
			n[bk] = clampNum(n[bk] + dist, 1, data.seq[p].total - n[2])
		else
			n[bk] = wrapNum(n[bk] + dist, data.bounds[byte])
		end

		return n

	end,

	-- Stretch all selected items or all seq items, by a given stretch value
	dynamicStretch = function(undo)

		-- Get the amount by which every note should be stretched (spacing divided by duration)
		local amt = math.max(1, data.spacing) / data.dur

		-- If the stretch ratio is 1/1, it would do nothing, so abort function
		if amt == 1 then
			return nil
		end

		local furthest = 0
		local cmds = {}

		-- Get the currently-selected notes
		local oldnotes = getContents(data.seldat, {pairs, pairs, pairs})
		local newnotes = deepCopy(oldnotes)

		-- If any notes are selected...
		if #oldnotes > 0 then

			-- Clear the selection-table
			data.seldat = {}

			-- For every previously-selected note...
			for k, v in pairs(oldnotes) do

				-- Get the new start-tick, rounded off
				local newstart = roundNum((v[2] + 1) * amt) - 1

				-- Change the newnote's start and duration values
				newnotes[k][2] = newstart - 1
				newnotes[k][3] = math.max(1, roundNum(v[3] * amt))

				-- Check the note against the furthest-val, for possible seq expansion
				furthest = math.max(furthest, newnotes[k][2] + newnotes[k][3])

				-- Build a new sparse index in seldat for the adjusted note, thus keeping it selected
				buildTable(data.seldat, {newstart, v[4], v[5]}, newnotes[k])

			end

		else -- Else, if no notes are selected...

			-- Get all notes from within the active sequence
			oldnotes = getContents(data.seq[data.active].tick, {pairs, 'note', pairs, pairs})
			newnotes = deepCopy(oldnotes)

			-- Get all non-note commands from within the active sequence
			cmds = getCmds(data.active, _, _, 'modify')

			-- Adjust every command's start-tick based on the stretch amount,
			-- and check their positions against the furthest-value.
			for k, v in pairs(cmds) do
				local adjtick = v[3][2] + 1
				local newstart = roundNum(adjtick * amt)
				cmds[k] = {v[3], v[2], 2, newstart - adjtick}
				furthest = math.max(furthest, newstart)
			end

			-- Adjust every note's start-tick and duration based on the stretch amount,
			-- and check their positions against the furthest-value.
			for k, v in pairs(oldnotes) do
				local newstart = roundNum((v[2] + 1) * amt) - 1
				newnotes[k][2] = newstart
				newnotes[k][3] = math.max(1, roundNum(v[3] * amt))
				furthest = math.max(furthest, newstart + (newnotes[k][3] - 1))
			end

		end

		-- If the furthest-stretched note is greater than the sequence-length,
		-- expand the sequence to compensate.
		if furthest > data.seq[data.active].total then
			growSeq(data.active, furthest - data.seq[data.active].total, undo)
		end

		-- If any cmds were grabbed, send their modified values to modCmds
		if #cmds > 0 then
			modCmds(data.active, cmds, false, undo)
		end

		-- Send the stretched note-values to setNotes in two batches
		local remove = notesToSetType(oldnotes, 'remove')
		local insert = notesToSetType(newnotes, 'insert')
		setNotes(data.active, remove, undo)
		setNotes(data.active, insert, undo)

	end,

	-- Humanize the volumes of the currently selected notes
	humanizeNotes = function(undo)

		-- If no notes are selected, abort function
		if next(data.seldat) == nil then
			return nil
		end

		-- Get a flattened table of all selected notes
		local notes = getContents(data.seldat, {pairs, pairs, pairs})

		-- If no notes are selected, abort function
		if #notes == 0 then
			return nil
		end

		-- For every applicable note...
		for k, v in pairs(notes) do

			-- Change its velocity randomly, bounded by data.velo value
			local rand = math.random(0, data.velo)
			local newvelo = clampNum(v[6] + (roundNum(data.velo / 2) - rand), data.bounds.velo)
			notes[k][6] = newvelo

			-- Update selected notes with their new velocities
			data.seldat[v[2] + 1][v[4]][v[5]] = deepCopy(notes[k])

			-- Convert modified notes into setNotes commands
			notes[k] = {'insert', notes[k]}

		end

		-- Use setNotes to replace the seq-notes with corresponding selection-tab notes
		setNotes(data.active, notes, undo)

	end,

	-- Quantize the tick-positions of the currently selected notes, based on current spacing
	quantizeNotes = function(undo)

		-- If no notes are selected, abort function
		if next(data.seldat) == nil then
			return nil
		end

		-- If spacing is too slim for quantization to have any effect, abort function
		if data.spacing < 2 then
			return nil
		end

		local modtab = {}

		local ticks = data.seq[data.active].total

		local selnotes = getContents(data.seldat, {pairs, pairs, pairs})

		-- For every currently-selected note, prioritizing the most recently selected first...
		for k, v in ripairs(selnotes) do

			-- Get the note's left and right distances from the spacing value
			local ldist = -1 * wrapNum(v[2], 0, data.spacing - 1)
			local rdist = ldist + data.spacing
			local shift = ldist
			if rdist < math.abs(ldist) then
				shift = rdist
			end

			-- Build the note's section of the movement-command table
			table.insert(modtab, {v, "tp", shift})

		end

		-- Send the movement-command tables to modNotes
		modNotes(data.active, modtab, true, false, undo)

	end,

}