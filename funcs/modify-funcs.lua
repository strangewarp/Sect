
return {
	
	-- Modify the selected notes by a given amount
	modSelectedNotes = function(byte, dist, undo)
		local seldup = getContents(data.seldat, {pairs, pairs, pairs})
		for k, v in pairs(seldup) do
			seldup[k] = {v, byte, dist}
		end
		modNotes(data.active, seldup, true, undo)
	end,

	-- Modify a collection of various notes, according to their given mod-commands
	modNotes = function(p, ntab, isselect, undo)

		local snotes = {}

		-- For every note, in order, add the mod-command's results to the snotes table
		for nk, ntab in ipairs(ntab) do

			local n, byte, dist = unpack(ntab)

			-- If the note exists in the given sequence...
			if getIndex(data.seq[p].tick[n[2] + 1], {"note", n[4], n[5]}) then

				-- Build a new note via the modByte command
				local m = modByte(p, deepCopy(n), byte, dist)

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
	modByte = function(p, note, byte, dist)

		-- If no default seq-pointer was given, set it to the active sequence,
		-- or to false if there is no active sequence.
		p = p or data.active

		-- Take a deepCopy of the note, to prevent reference bugs
		local n = deepCopy(note)

		-- If no seq-pointer was given, and no active seq exists, then return the copy of note.
		if not p then
			return n
		end

		-- Get the byte-key that corresponds to the byte-command
		local bk = data.notebytes[byte]

		-- Change the byte-value, and wrap it to its proper boundaries
		if byte == "tp" then
			n[bk] = wrapNum(n[bk] + (dist * math.max(1, data.spacing)), 0, #data.seq[p].tick - 1)
		elseif byte == "dur" then
			n[bk] = clampNum(n[bk] + (dist * math.max(1, data.spacing)), 1, #data.seq[p].tick - n[2])
		else
			n[bk] = wrapNum(n[bk] + dist, data.bounds[byte])
		end

		return n

	end,

}