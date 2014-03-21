return {
	
	-- Add tasks to either the undo or redo table, depending on context
	addMetaUndoTask = function(data, ...)

		-- Put variable arguments into a table
		local t = {...}

		-- Get contents of undo-command table
		local suppress, collect, newcmd = unpack(t[#t])

		-- If undo-suppression is not invoked on this function call...
		if not suppress then

			-- Change the command's internal newcmd value to old/false
			t[#t][3] = false

			-- If this function is to be collected in the latest do-entry...
			if collect then

				-- Create an empty table on top of the do-stack if none are there
				if next(data[data.dotarget]) == nil then
					table.insert(data[data.dotarget], 1, {})
				end

				-- Add the incoming func-ts to the do-stack
				table.insert(data[data.dotarget][1], t)

			else -- If the func-args represent a new do-entry, insert them as one
				table.insert(data[data.dotarget], 1, {t})
			end

			-- If a task has been added to the undo stack via new commands,
			-- empty the newly irrelevant tasks from the redo table.
			if newcmd then
				data.redo = {}
			end

			-- If there are more undo states than max-undo-states,
			-- remove the most distant undo item.
			if #data.undo > data.maxundo then
				table.remove(data.undo, #data.undo)
			end

		end

	end,

	-- Traverse one step within data.undo or data.redo table,
	-- and execute the step's table of functions.
	traverseUndo = function(data, dotype)

		-- If there is neither an undo flag nor a redo flag, abort function
		if (dotype ~= "undo") and (dotype ~= "redo") then
			print("traverseUndo error: function was called with an invalid do-type!")
			return nil
		else -- Else, set the do-target to the opposite stack from the do-command
			data.dotarget = ((dotype == "redo") and "undo") or "redo"
		end

		if #data[dotype] > 0 then -- If the do-table isn't empty...

			-- Remove a single step-table from either the undo or redo table
			local funcs = table.remove(data[dotype], 1)

			-- Call all functions in the do-step, in order
			for k, v in ipairs(funcs) do
				data:executeObjectFunction(unpack(v))
				print("traverseUndo: performed " .. dotype .. " function " .. v[1] .. "!")
			end

		else
			print("traverseUndo: do-stack was empty!")
		end

	end,

}