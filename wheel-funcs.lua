
return {

	-- Generate all musical combinatoric data (called once on startup)
	generateCombinatorics = function()

		data.scales = buildScales()
		data.scales = purgeIdenticalScales(data.scales)
		data.scales = addIntervalSpectrum(data.scales)
		data.scales = addConsonanceRatings(data.scales)

		data.scales = indexByNoteQuantity(data.scales)

		for k, v in pairs(data.scales[7]) do -- DEBUGGING
			print("SCALE " .. v.bin .. ": ")
			print(v.conso)
			print(" ")
		end -- DEBUGGING

		data.wheels = buildWheels(data.scales)

	end,

	-- Assign a consonance rating to each given scale
	addConsonanceRatings = function(scales)

		for k, v in pairs(scales) do

			local avg, avgdiv = 0, 0
			local compare = deepCopy(v.ints)

			-- Get the ideal consonance value
			local ideal = 12 / v.ints[1]

			-- Collapse the latter half of the intervals into the equivalent former half
			for i = 8, 12 do
				local adj = (12 - i) + 1
				compare[adj] = compare[adj] + compare[i]
			end

			-- Increase the average, and average-divisor, by integer-spectrum values
			for i = 1, 6 do
				avgdiv = avgdiv + compare[i]
				avg = avg + (i * compare[i])
			end

			-- Set the scale's consonance-value to the difference between
			-- the scale's average consonance and the ideal consonance-value.
			scales[k].conso = math.abs(ideal - (avg / avgdiv))

		end

		return scales

	end,

	-- Calculate each scale's interval spectrum, and add it to each scale-table
	addIntervalSpectrum = function(scales)

		-- For every given scale...
		for k, s in pairs(scales) do

			scales[k].ints = {}

			-- For every possible interval size within the scale...
			for i = 1, 12 do

				scales[k].ints[i] = 0

				-- Rotate a scale by the interval size, to match against
				local r = rotateScale(s, i - 1)

				-- For every interval presence, increase the corresponding interval's index
				for ii = 1, 12 do
					if (s.notes[ii] == 1)
					and (s.notes[ii] == r.notes[ii])
					then
						scales[k].ints[i] = scales[k].ints[i] + 1
					end
				end

			end

		end

		return scales

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

	-- Build all fully cyclic combinatoric wheels
	buildWheels = function(scales)

		local wheels = {}

		-- For every scale (indexed by numer of notes)...
		for k, v in pairs(scales) do

			wheels[k] = {}

			for sk, s in pairs(v) do

				local links, positions = {}, {}

				-- Build a wheel template, using each note-presence as a node
				for nk, n in pairs(s.notes) do
					if n == 1 then
						links[nk] = {i = nk, o = nk}
						table.insert(positions, nk)
					end
				end

				-- TODO: CONNECT WHEEL INDEXES



			end

		end

		return wheels

	end,

	-- Index a given table of scales by how many notes they contain
	indexByNoteQuantity = function(scales)

		local out = {}
		for i = 0, 12 do
			out[i] = {}
		end

		for k, v in pairs(scales) do
			table.insert(out[v.ints[1]], v)
		end

		return out

	end,

	-- Remove scales that are the same combinatoric k-species as other scales
	purgeIdenticalScales = function(scales)

		local i = 1
		while i < #scales do

			local s = scales[i]

			-- For each possible position of the given scale...
			for p = 1, 11 do

				local rotated = rotateScale(s, p)

				-- If any scales match the rotated scale, remove them
				for k, v in pairs(scales) do
					if rotated.bin == v.bin then
						print("REMOVE") -- DEBUGGING
						table.remove(scales, k)
						break
					end
				end

			end

			i = i + 1

		end

		return scales

	end,

	-- Rotate a scale-table by a given amount
	rotateScale = function(scale, pos)

		local out = {
			notes = {},
			bin = "",
		}

		-- Rotate scale's notes
		for k, v in pairs(scale.notes) do
			out.notes[((k + pos - 1) % 12) + 1] = v
		end

		-- Match binary string to new note positions
		for k, v in ipairs(out.notes) do
			out.bin = out.bin .. v
		end

		--print(out.bin) -- DEBUGGING

		return out

	end,


}
