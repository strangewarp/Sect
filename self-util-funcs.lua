return {
	
	-- Execute an object function, after receiving data in the format:
	-- Object, "funcName", arg1, arg2, ..., argN
	executeObjectFunction = function(obj, argtab)

		-- Make a copy, so table.remove doesn't modify the original data
		local dup = deepCopy(argtab)

		-- Get the func-name, and call it in obj namespace with all of its args
		local fname = table.remove(dup, 1)
		obj[fname](obj, unpack(dup))

	end,

}