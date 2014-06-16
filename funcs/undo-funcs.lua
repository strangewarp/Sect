return {
	
	-- Add an undo step to the undo stack,
	-- comprised of an undo-direction and redo-direction command.
	addUndoStep = function(suppress, u, r)

		-- If undo-suppression is not invoked on this function call...
		if not suppress then

			-- If a task is being added to the undo stack via new commands,
			-- empty the newly irrelevant redo-tasks.
			if #data.redo > 0 then
				data.redo = {}
			end

			local composite = {
				true, -- Suppress flag
				u, -- Incoming undo command
				r, -- Incoming redo command
			}

			-- Put the command-pair, and flags, atop the undo-stack
			table.insert(data.undo, composite)

			-- If there are more undo states than max-undo-states,
			-- remove the most distant command pair.
			if #data.undo > data.maxundo then
				table.remove(data.undo, 1)
			end

		end

	end,

	-- Traverse one step within data.undo or data.redo table,
	-- and execute the step's table of functions.
	traverseUndo = function(back)

		-- Get the target stack names, based on the command type
		local stack = (back and "undo") or "redo"
		local otherstack = (back and "redo") or "undo"

		-- If the do-stack is empty, do nothing
		if #data[stack] == 0 then

			print("traverseUndo: \"" .. stack .. "\" stack was empty!")
			return nil

		else -- If the do-command is valid...

			-- Get a single command-table from the do-stack,
			-- and place it into the other-do-stack.
			local ctab = table.remove(data[stack])
			table.insert(data[otherstack], ctab)

			-- Unpack the do-command table
			local flags, undo, redo = unpack(ctab)

			-- If undo, get the undo command, else get the redo command
			local cmd = (back and undo) or redo

			-- Execute the function, with its attendant args
			executeFunction(unpack(cmd))
			print("traverseUndo: performed function: " .. cmd[1] .. "! (" .. stack .. ")")

		end

	end,

}