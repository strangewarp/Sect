return {
	
	-- Add a keystroke to the keystroke-tracking table, check for matching commands, and call said commands
	addKeystroke = function(data, key, isrepeat)

		key = stripSidedness(key)

		-- If the new key is the same as a currently-pressed key, abort function
		for k, v in pairs(data.keys) do
			if v == key then
				return nil
			end
		end

		print(key) -- DEBUGGING

		-- If this isn't a key-repeat, add the key to the keypress table
		table.insert(data.keys, key)

		-- Seek out the command that matches currently-pressed keys
		local match = false
		for k, v in pairs(data.cmds) do
			if crossCompare(data.keys, v) then
				match = k
				break
			end
		end

		-- If no exact match was found, abort function
		if not match then
			return nil
		end

		-- Get the function that is linked to the keycommand, and invoke it
		if data.cmdfuncs[match] ~= nil then

			print("addKeystroke: received command '" .. match .. "'!")
			data:executeObjectFunction(unpack(data.cmdfuncs[match]))

			-- Toggle the drawing of a new frame
			data.update = true

		else
			print("addKeystroke error: command '" .. match .. "' does not have a referent in cmdfuncs table!")
		end

	end,

	-- Remove a key from the keystroke-tracking table
	removeKeystroke = function(data, key)

		key = stripSidedness(key)

		-- Remove the key from the currently-held-keys table
		for i = 1, #data.keys do
			if key == data.keys[i] then
				table.remove(data.keys, i)
				break
			end
		end

	end,

	-- Sort all key-command tables, to allow simple comparison
	sortKeyComboTables = function(data)
		for i = 1, #data.cmds do
			table.sort(data.cmds[i])
		end
	end,

}