return {
	
	-- Add an undo step to the undo stack,
	-- comprised of an undo-direction and redo-direction command.
	addUndoStep = function(data, suppress, u, r)

		-- If undo-suppression is not invoked on this function call...
		if not suppress then

			-- If a task is being added to the undo stack via new commands,
			-- empty the newly irrelevant redo-tasks.
			if data.dopointer <= #data.dostack then
				for i = #data.dostack, data.dopointer - 1, -1 do
					table.remove(data.dostack, i)
				end
			end

			local composite = {
				true, -- Suppress flag
				u, -- Incoming undo command
				r, -- Incoming redo command
			}

			-- Put the command-pair, and flags, atop the undo-stack
			table.insert(data.dostack, composite)

			-- If there are more undo states than max-undo-states,
			-- remove the most distant command pair.
			if #data.dostack > data.maxundo then
				table.remove(data.dostack, 1)
			end

			-- Set the dopointer at the top of the dostack
			data.dopointer = #data.dostack + 1

		end

	end,

	-- Traverse one step within data.undo or data.redo table,
	-- and execute the step's table of functions.
	traverseUndo = function(data, back)

		-- If a limit was reached, do nothing
		if (back and (data.dopointer <= 1))
		or ((not back) and (data.dopointer == (#data.dostack + 1)))
		then

			print("traverseUndo: reached " .. ((back and "lower") or "upper") .. " limit!")
			return nil

		elseif #data.dostack == 0 then -- If do-stack is empty, do nothing

			print("traverseUndo: do-stack was empty!")
			return nil

		else -- If the do-command is valid...

			-- Move the do-target pointer back before undo
			data.dopointer = data.dopointer + ((back and -1) or 0)

			-- Get a single command-pair from the do-stack
			local flags, undo, redo = unpack(deepCopy(data.dostack[data.dopointer]))

			-- If undo, get the undo command, else get the redo command
			local cmd = (back and undo) or redo

			-- Execute the function, with its attendant args
			data:executeObjectFunction(unpack(cmd))
			print("traverseUndo: performed function: " .. cmd[1] .. "! (" .. data.dopointer .. ")")

			-- Move the do-target pointer forward after redo
			data.dopointer = data.dopointer + ((back and 0) or 1)

		end

	end,

}