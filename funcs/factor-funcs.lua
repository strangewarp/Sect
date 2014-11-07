
return {

	-- Get all factors that fall within the current ticks-per-beat value
	getBeatFactors = function()

		local oldfactors = deepCopy(data.factors)

		data.factors = getFactors(data.tpq * 4)

		-- If the new factors are different from the oldfactors, set the factor-index to 1
		if not strictCompare(oldfactors, data.factors) then
			data.fp = #data.factors
		end

	end,
	
	-- Get a table of all factors of a given integer
	getFactors = function(n)

		local factors = {}

		for i = 1, math.sqrt(n) do

			local rem = n % i
		
			if rem == 0 then
				local pair = n / i
				table.insert(factors, i)
				if i ~= pair then
					table.insert(factors, pair)
				end
			end

		end
		
		table.sort(factors)

		return factors

	end,

	-- Shift the factor-pointer by a given amount
	shiftFactorKey = function(dist)
		data.fp = wrapNum(data.fp + dist, 1, #data.factors)
	end,

}
