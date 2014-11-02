
return {
	
	-- Modify a table of non-note commands to flag them for setCmds
	cmdsToSetType = function(cmds, kind)

		kind = kind or 'insert'

		for k, v in pairs(cmds) do
			v[1] = kind
		end

		return cmds

	end,

	-- Get the non-note commands from a given slice of a sequence, bounded to a channel
	getCmds = function(p, tbot, ttop, kind)

		-- Set parameters to default if any are empty
		tbot = tbot or 1
		ttop = ttop or data.seq[p].total
		kind = kind or 'insert'

		local cmds = {}

		-- Grab all cmds within the given range, and put them in the cmds-table
		for t = tbot, ttop do

			-- Grab all cmds within the tick.
			local ctab = getContents(data.seq[p].tick, {t, "cmd", pairs}, true)

			-- Format the cmd tables properly
			for k, v in pairs(ctab) do
				ctab[k] = {kind, v[1][#v[1]], v[2]}
			end

			-- Put this tick's cmds into the table that holds all ticks' cmds
			cmds = tableCombine(cmds, ctab)

		end

		return cmds

	end,

	-- Insert a given table of command values into a sequence
	setCmds = function(p, cmds, undo)
		for k, v in ripairs(cmds) do
			setCmd(p, v, undo)
		end
	end,

	-- Insert a given command value into a sequence
	setCmd = function(p, cmd, undo)

		-- Make a duplicate of the command, to prevent reference bugs
		local undocmd, redocmd = deepCopy(cmd), deepCopy(cmd)

		local ctick = cmd[3][2] + 1

		-- Check whether the index is already filled
		local filled = false
		if getIndex(data.seq[p].tick, {ctick, "cmd", cmd[2]}) then
			filled = true
		end

		-- If cmd is flagged for removal, remove it
		if cmd[1] == 'remove' then

			-- If channel index exists, remove the cmd
			if filled then
				seqUnsetCascade(p, 'cmd', cmd[3], cmd[2])
			else -- If channel index doesn't exist to remove from, abort function
				return nil
			end

			undocmd[1] = 'insert'

		else -- Else, insert cmd
			if filled then
				table.insert(data.seq[p].tick[ctick].cmd, cmd[2], cmd[3])
			else
				buildTable(data.seq[p].tick, {ctick, "cmd", cmd[2]}, cmd[3])
			end
			undocmd[1] = 'remove'
		end

		-- Build undo table
		addUndoStep(
			((undo == nil) and true) or undo, -- Suppress flag
			{"setCmd", p, undocmd}, -- Undo command
			{"setCmd", p, redocmd} -- Redo command
		)

	end,

}