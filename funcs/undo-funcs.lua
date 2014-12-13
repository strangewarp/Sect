return {
	
	-- Add an undo-step and redo-step to the current do-block.
	addUndoStep = function(suppress, u, r)

		if not suppress then
			table.insert(D.dostack[D.undotarget].undo, 1, u)
			table.insert(D.dostack[D.undotarget].redo, r)
		end

	end,

	-- Add a new command-block template on top of the current undo position.
	addUndoBlock = function()

		-- Remove all command-blocks after the current undo-target point
		while #D.dostack > D.undotarget do
			table.remove(D.dostack)
		end

		-- Insert the template for the new command-block
		table.insert(D.dostack, {suppress = true, undo = {}, redo = {}})

		-- If size of dostack surpasses maxundo, remove the bottom element
		if #D.dostack > D.maxundo then
			table.remove(D.dostack, 1)
		end

		-- Set undo-target to top of do-stack
		D.undotarget = #D.dostack

	end,

	-- Traverse one step within D.undo or D.redo table,
	-- and execute the step's table of functions.
	traverseUndo = function(back)

		-- Get the target direction and stack names, based on the command type
		local stack = (back and "undo") or "redo"
		local target = D.undotarget + ((back and 0) or 1)
		local add = (back and -1) or 1

		-- If the target block of the do-stack is empty, abort function
		if D.dostack[target] == nil then

			print("traverseUndo: \"" .. stack .. "-" .. target .. "\" stack was empty!")
			return nil

		else -- Else, if the do-command is valid...

			-- Perform every command in the target do-block
			for k, v in ipairs(D.dostack[target][stack]) do
				executeFunction(unpack(v))
				print("traverseUndo: performed function: " .. v[1] .. "! (" .. stack .. ")")
			end

			D.undotarget = wrapNum(D.undotarget + add, 0, D.maxundo)

		end

	end,

}