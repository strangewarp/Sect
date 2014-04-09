return {
	
	-- Execute an object function, after receiving data in the format:
	-- Object, "funcName", arg1, arg2, ..., argN
	executeObjectFunction = function(data, ...)

		local t = {...}

		-- Get the func-name, and call it in data namespace with all of its args
		local fname = table.remove(t, 1)
		data[fname](data, unpack(t))

	end,

}