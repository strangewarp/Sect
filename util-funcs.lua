return {
	
	-- Bound a number between low and high values.
	-- If either of the values is false, then that side is unbounded.
	-- If the number is false, it defaults to low, or if low is false, high.
	clampNum = function(num, low, high)

		-- If the bounds were in a table, format them correctly
		if type(low) == "table" then
			low, high = unpack(low)
		end

		num = (num or low) or high
		num = math.max(num, low or num)
		num = math.min(num, high or num)

		return num

	end,

	-- Check whether two values match, or whether they are matching tables.
	crossCheck = function(i, i2)
		return (
			((type(i) ~= "table") and (i == i2))
			or (
				(type(i) == "table")
				and (type(i2) == "table")
				and crossCompare(i, i2)
			)
		)
	end,

	-- Compare the contents of two tables of arbitrary depth,
	-- with arbitrarily ordered values,
	-- and return true only on an exact value-for-value match.
	crossCompare = function(t, t2)

		-- If the tables are not the same length, then they aren't a match,
		-- so return false
		if #t ~= #t2 then
			return false
		end

		local dup, dup2 = deepCopy(t), deepCopy(t2)
		local multiples = {}

		-- While the first comparison-table is still populated...
		while #dup > 0 do

			local found = false
			local count = 0
			local tempdup = false
			local item = table.remove(dup, 1)

			-- If the item matches any cached multiples, then remove the multiple,
			-- and set the found-state to true.
			for k, v in pairs(multiples) do
				if crossCheck(item, v) then
					table.remove(multiples, k)
					found = true
					break
				end
			end

			-- If the item didn't match any cached multiples...
			if not found then

				local delindexes = {}

				-- Check the item against the second comparison-table,
				-- adding every match to "tempdup" and "count", to track multiples,
				-- and adding every matching item's index to "delindexes".
				for k, v in pairs(dup2) do
					if crossCheck(item, v) then
						tempdup = v
						table.insert(delindexes, k)
						found = true
						count = count + 1
					end
				end

				-- Remove all matching indexes from the second comparison-table.
				table.sort(delindexes, function (a, b) return a > b end)
				for k, v in ipairs(delindexes) do
					table.remove(dup2, v)
				end

			end

			-- If the item still wasn't found, then the tables aren't a value-match,
			-- so return false.
			if not found then
				return false
			end

			-- If the item matched multiple values,
			-- add each extra value to the multiples table.
			while count > 1 do
				table.insert(multiples, tempdup)
				count = count - 1
			end

		end

		return true

	end,

	-- Recursively copy all sub-tables and sub-items,
	-- when copying from one table to another.
	-- Invoke as: newtable = deepCopy(oldtable)
	deepCopy = function(t, t2)

		t2 = t2 or {}

		for k, v in pairs(t) do
			if type(v) ~= "table" then
				t2[k] = v
			else
				local temp = {}
				deepCopy(v, temp)
				t2[k] = temp
			end
		end
		
		return t2
		
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

	-- Compare two flat, ordered tables, and return true on exact match.
	orderedCompare = function(t, t2)

		-- If the tables are not the same length, then they aren't a match,
		-- so return false
		if #t ~= #t2 then
			return false
		end

		-- If all table items don't exactly match, return false
		for k, v in pairs(t) do
			if (t2[k] == nil)
				or (
					(type(v) == "table")
					and (type(t2[k]) == "table")
					and (not orderedCompare(v, t2[k]))
				)
				or ((type(v) ~= "table") and (v ~= t2[k]))
			then
				return false
			end
		end

		return true

	end,

	-- Check whether a value falls within a particular range,
	-- and return true or false.
	rangeCheck = function(val, low, high)

		if high < low then
			low, high = high, low
		end

		if (val >= low)
		and (val <= high)
		then
			return true
		end
		
		return false

	end,

	-- Round number num, at decimal place dec.
	roundNum = function(num, dec)
		local mult = 10 ^ dec
		return math.floor((num * mult) + 0.5) / mult
	end,

	-- Move a given table of functions into a different namespace.
	tableToNewContext = function(tab, context)
		for k, v in pairs(tab) do
			context[k] = v
		end
	end,

	-- Wrap a number to a given range.
	-- Usage note: top itself does not wrap. top+1 does wrap.
	-- Usage note: arg 2 can be either the bottom of the range, or a range table.
	wrapNum = function(n, a, b)

		-- If the range was in a table, format it correctly
		if type(a) == "table" then
			a, b = unpack(a)
		end

		-- Return the wrapped number
		return ((n - a) % ((b + 1) - a)) + a

	end,

}