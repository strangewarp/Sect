
return {
	
	-- Modify the selected notes by a given amount
	modSelectedNotes = function(byte, dist, undo)
		local seldup = deepopy(data.seldat)
		for k, v in pairs(seldup) do
			seldup[k] = {v, byte, dist}
		end
		modNotes(data.active, seldup, undo)
	end,

	-- Modify a collection of various notes, according to their given mod-commands
	modNotes = function(p, ntab, undo)

		local snotes = {}

		-- For every note, in order, add the mod-command's results to the snotes table
		for nk, ntab in ipairs(ntab) do

			local n, byte, dist = unpack(ntab)

			-- If the note exists in the given sequence...
			if getIndex(data.seq[p].tick[n[2] + 1], {"note", n[4], n[5]}) then

				-- Build a new note via the modByte command
				local modnote = modByte(p, deepCopy(n), byte, dist)

				-- Add commands to the snotes table, to remove old note and insert new note
				table.insert(snotes, {'remove', n})
				table.insert(snotes, {'insert', modnote})

				-- If the mod-note matches a selected note, replace selnote with a copy of mod-note
				for k, v in pairs(data.seldat) do
					if strictCompare(v, n) then
						data.seldat[k] = deepCopy(modnote)
						break
					end
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

		-- Apply the offset-distance to the given byte of the note
		n[bk] = n[bk] + dist

		-- Wrap the changed byte-value to its proper boundaries
		if byte == "tick" then
			n[bk] = wrapNum(n[bk], 0, #data.seq[p].tick - 1)
		else
			n[bk] = wrapNum(n[bk], data.bounds[byte])
		end

		return n

	end,

}