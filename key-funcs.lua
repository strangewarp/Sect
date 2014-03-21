return {
	
	-- Strip left/right sidedness information from specific keys
	stripSidedness = function(key)

		for k, v in pairs(data.sidekeys) do
			if key == v then
				return key:sub(2)
			end
		end

		return key

	end,
	
}