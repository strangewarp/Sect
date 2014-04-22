return {
	
	-- Add tasks to either the undo or redo table, depending on context
	addMetaUndoTask = function(data, ...)

		-- Put the list of arguments into a table, and copy them,
		-- to prevent any modifying of original values.
		local t = deepCopy({...})

		-- Get contents of undo-command table
		local suppress, collect, newcmd = unpack(t[#t])

		-- If undo-suppression is not invoked on this function call...
		if not suppress then

			-- If a task is being added to the undo stack via new commands,
			-- empty the newly irrelevant tasks from the redo table,
			-- set the do-command target table to the undo-tab,
			-- and set the newcmd flag to false for storage.
			if newcmd then
				data.redo = {}
				data.dotarget = "undo"
				t[#t][3] = false
			end

			-- If this function is to be collected in the latest do-entry...
			if collect then

				-- Create an empty table on top of the do-stack if none are there
				if #data[data.dotarget] == 0 then
					table.insert(data[data.dotarget], {})
				end

				table.insert(data[data.dotarget][#data[data.dotarget]], t)

			else -- If the func-args represent a new do-entry, insert them as one
				table.insert(data[data.dotarget], {t})
			end

			-- If there are more undo states than max-undo-states,
			-- remove the most distant undo item.
			if #data.undo > data.maxundo then
				table.remove(data.undo, 1)
			end

		end

	end,

	-- Traverse one step within data.undo or data.redo table,
	-- and execute the step's table of functions.
	traverseUndo = function(data, dotype)

		if #data[dotype] > 0 then -- If the do-table isn't empty...

			-- Set the do-target to the opposite stack from the do-command
			data.dotarget = ((dotype == "redo") and "undo") or "redo"

			-- Remove a single step-table from either the undo or redo table
			local funcs = table.remove(data[dotype])

			-- Call all functions in the do-step, in the do-type's order
			local order = dotype == "redo"
			for i = (order and 1) or #funcs,
				(order and #funcs) or 1,
				(order and 1) or -1
			do
				data:executeObjectFunction(unpack(funcs[i]))
				print("traverseUndo: performed " .. dotype .. " function " .. funcs[i][1] .. "!")
			end

		else
			print("traverseUndo: do-stack was empty!")
		end

	end,

}