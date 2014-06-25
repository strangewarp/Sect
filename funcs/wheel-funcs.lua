
return {

	-- Directly call anonymizeKeys for data.scales
	anonymizeScaleKeys = function()
		data.scales = anonymizeKeys(data.scales)
	end,

	-- Assign a consonance rating to each given scale
	buildConsonanceRatings = function()

		-- For every k-species...
		for k, v in pairs(data.scales) do

			data.scales[k].con = math.huge
			data.scales[k].dis = 0
			data.scales[k].avg = 0
			data.scales[k].median = 0

			local medianlist = {}
			local kavg = 0

			-- For every scale in a given k-species...
			for sk, s in pairs(v.s) do

				local gaps, adjs = {}, {}
				local adjs = {}
				local adjacent, adjdifftotal, gapdifftotal, gapavg = 0, 0, 0, 0

				-- Get the number of note-adjacent notes
				for n in s.bin:gmatch("1+") do
					local nlen = n:len()
					table.insert(adjs, nlen)
					if nlen > 1 then
						adjacent = adjacent + (nlen ^ nlen)
					end
				end

				-- Modify adjacency penalty based on ordered note-group spacing
				local adjalt = adjs[1] or 0
				if #adjs > 1 then
					for i = 1, #adjs + 1 do
						local w = wrapNum(i, 1, #adjs)
						if adjs[w] ~= adjalt then
							adjdifftotal = adjdifftotal + math.abs(adjalt - adjs[w])
							adjalt = adjs[w]
						end
					end
				end

				-- Get the number of gaps, and their size, and add it to the gap average
				for g in s.bin:gmatch("0+") do
					local glen = g:len()
					table.insert(gaps, glen)
					gapavg = gapavg + glen
				end

				-- Modify gap bonus based on ordered gap-group spacing
				local gapalt = gaps[1] or 0
				if #gaps > 1 then
					for i = 1, #gaps + 1 do
						local w = wrapNum(i, 1, #gaps)
						if gaps[w] ~= gapalt then
							gapdifftotal = gapdifftotal + math.abs(gapalt - gaps[w])
							gapalt = gaps[w]
						end
					end
				end

				-- Calculate the consonance value (lower number = more consonant)
				local conso = ((gapavg + gapdifftotal) / #gaps) + ((adjacent - adjdifftotal) / k)

				-- Add consonance-value to average and median values
				kavg = kavg + conso
				table.insert(medianlist, conso)

				-- Test consonance-value against most-consonant and most-dissonant vals
				data.scales[k].con = math.min(data.scales[k].con, conso)
				data.scales[k].dis = math.max(data.scales[k].dis, conso)

				-- Save consonance-data into the scale-table
				data.scales[k].s[sk].gaps = gaps
				data.scales[k].s[sk].adjs = adjs
				data.scales[k].s[sk].conso = conso

			end

			-- Calculate the k-species' average and median consonance vals
			data.scales[k].avg = kavg / #v.s
			data.scales[k].median = medianlist[math.max(1, roundNum(#medianlist, 0))]

			-- Sort each k-species' scale-table by scale-consonance
			table.sort(data.scales[k].s, function(a, b) return a.conso < b.conso end)

		end

	end,

	-- Calculate each scale's interval spectrum, and add it to each scale-table
	buildIntervalSpectrum = function()

		-- For every given scale...
		for k, s in pairs(data.scales) do

			data.scales[k].ints = {}

			-- For every possible interval size within the scale...
			for i = 1, 12 do

				data.scales[k].ints[i] = 0

				-- Rotate a scale by the interval size, to match against
				local r = rotateScale(s, i - 1)

				-- For every interval presence, increase the corresponding interval's index
				for ii = 1, 12 do
					if (s.notes[ii] == 1)
					and (s.notes[ii] == r.notes[ii])
					then
						data.scales[k].ints[i] = data.scales[k].ints[i] + 1
					end
				end

			end

		end

	end,

	-- Build a tree of all possible scale positions	
	buildScales = function(tree, height)

		-- If no tree is supplied, start from an origin point (0 and 1)
		tree = tree or {
			["0"] = {
				notes = {0}, -- List of notes in scale
				bin = "0", -- Binary string that corresponds to note-list
			},
			["1"] = {
				notes = {1},
				bin = "1",
			},
		}

		height = height or 1

		local out = {}

		-- For every element in the tree, add a 0 and 1 branch
		for k, v in pairs(tree) do
			local b1, b2 = deepCopy(v), deepCopy(v)
			table.insert(b1.notes, 0)
			table.insert(b2.notes, 1)
			b1.bin = b1.bin .. "0"
			b2.bin = b2.bin .. "1"
			out[b1.bin] = b1
			out[b2.bin] = b2
		end

		height = height + 1

		-- If the tree height is less than the contents of an octave, keep adding branches
		if height < 12 then
			out = buildScales(out, height)
		end

		return out

	end,

	-- Function-call for buildScales that acts directly upon the current data.scales
	buildDataScales = function()
		data.scales = buildScales()
	end,

	-- Build all fully cyclic combinatoric wheels
	buildWheels = function()

		local wheels = {}

		-- For every k-species of scales...
		for k, _ in pairs(data.scales) do

			-- Limit wheel size to 7 notes, to quash exponential data requirements
			if k > 7 then
				do break end
			end

			-- Generate initial pointers
			local pointers = {}
			for p = 1, k do
				pointers[p] = p
			end

			-- Build a sub-table that corresponds to each k-species
			wheels[k] = {}

			-- Get the notes' number of possible permuations
			local factorial = getFactorial(k)

			for i = 1, factorial do

				-- Put the new wheel into the wheels table
				table.insert(wheels[k], deepCopy(pointers))

				-- Rotate pointers until arriving at a position with no duplicates
				repeat
					for p = #pointers, 1, -1 do
						pointers[p] = wrapNum(pointers[p] + 1, 1, k)
						if pointers[p] > 1 then
							do break end
						end
					end
				until not duplicateCheck(pointers)

			end

		end

		data.wheels = wheels

	end,

	-- Compare two scales, and return a difference value based on two-way mismatches
	getScaleDifference = function(s, s2)

		local c, c2 = 0, 0

		for k, v in pairs(s) do
			if (v == 1) and (s2[k] == 0) then
				c = c + 1
			end
			if (v == 0) and (s2[k] == 1) then
				c2 = c2 + 1
			end
		end

		local diff = math.min(c, c2)

		return diff

	end,

	-- Index data.scales by their binary note-presence identities
	indexScalesByBin = function()

		for k, v in pairs(data.scales) do
			data.scales[k].s = {}
			for sk, s in pairs(v.s) do
				data.scales[k].s[s.bin] = v
			end
		end

	end,

	-- Index a given table of scales by how many notes they contain
	indexScalesByNoteQuantity = function()

		local out = {}
		for i = 0, 12 do
			out[i] = {s = {}}
		end

		for k, v in pairs(data.scales) do
			table.insert(out[v.ints[1]].s, v)
		end

		data.scales = out

	end,

	-- Remove scales that are empty
	purgeEmptyScales = function()
		table.remove(data.scales, 0)
	end,

	-- Remove scales that are the same combinatoric k-species as other scales
	purgeIdenticalScales = function()

		-- For every scale...
		for i = #data.scales - 1, 1, -1 do

			-- For each possible position of a given scale...
			for p = 1, 11 do

				-- Rotate the scale to that position
				local rotated = rotateScale(data.scales[i], p)

				-- If any scales match the rotated scale, remove them
				for c = i + 1, #data.scales do
					if rotated.bin == data.scales[c].bin then
						table.remove(data.scales, c)
						break
					end
				end

			end

		end

	end,

	-- Rotate a scale-table by a given amount
	rotateScale = function(scale, pos)

		if pos == 0 then
			return scale
		end

		local out = deepCopy(scale)
		out.notes = {}
		out.bin = ""

		-- Rotate scale's notes
		for k, v in pairs(scale.notes) do
			out.notes[wrapNum(k + pos, 1, 12)] = v
		end

		-- Match binary string to new note positions
		for k, v in ipairs(out.notes) do
			out.bin = out.bin .. v
		end

		return out

	end,

	-- Rotate all data.scales so that their first note is a filled position
	rotateScalesToFilledPosition = function()

		for k, v in pairs(data.scales) do

			local count = 0
			while (
				not (
					(data.scales[k].notes[1] == 1)
					and (data.scales[k].notes[12] == 0)
				)
			)
			and (count < 12)
			do
				data.scales[k] = rotateScale(data.scales[k], 1)
				count = count + 1
			end

		end

	end,

}
