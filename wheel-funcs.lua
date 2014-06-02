
return {

	-- Generate all musical combinatoric data (called once on startup)
	generateCombinatorics = function()

		data.scales = buildScales()
		data.scales = anonymizeKeys(data.scales)
		data.scales = purgeIdenticalScales(data.scales)
		data.scales = rotateToFilledPosition(data.scales)

		data.scales = addIntervalSpectrum(data.scales)

		data.scales = indexByNoteQuantity(data.scales)

		data.scales = addConsonanceRatings(data.scales)

		local i = 7 -- DEBUGGING
		print(" ")
		print("testing k-species: " .. i)
		print("scales: " .. #data.scales[i].s)
		print(" ")
		print("most consonant: " .. data.scales[i].con)
		print("most dissonant: " .. data.scales[i].dis)
		print("average consonance: " .. data.scales[i].avg)
		print("median consonance: " .. data.scales[i].median)
		print(" ")
		for k, v in ipairs(data.scales[i].s) do -- DEBUGGING
			print(".....SCALE: " .. v.bin)
			print("..clusters: " .. table.concat(v.adjs, " "))
			print("......gaps: " .. table.concat(v.gaps, " "))
			print("consonance: " .. v.conso)
			print(" ")
		end -- DEBUGGING

		data.wheels = buildWheels(data.scales)

		data.scales = indexByBin(data.scales)

	end,

	-- Assign a consonance rating to each given scale
	addConsonanceRatings = function(t)

		-- For every k-species...
		for k, v in pairs(t) do

			t[k].con = math.huge
			t[k].dis = 0
			t[k].avg = 0
			t[k].median = 0

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
				t[k].con = math.min(t[k].con, conso)
				t[k].dis = math.max(t[k].dis, conso)

				-- Save consonance-data into the scale-table
				t[k].s[sk].gaps = gaps
				t[k].s[sk].adjs = adjs
				t[k].s[sk].conso = conso

			end

			-- Calculate the k-species' average and median consonance vals
			t[k].avg = kavg / #v.s
			t[k].median = medianlist[math.max(1, roundNum(#medianlist, 0))]

			-- Sort each k-species' scale-table by scale-consonance
			table.sort(t[k].s, function(a, b) return a.conso < b.conso end)

		end

		return t

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
	buildWheels = function(t)

		local wheels = {}

		-- For every k-species of scales...
		for k, _ in pairs(t) do

			-- Limit wheel size to 8 notes, to quash exponential data requirements
			if k > 8 then
				do break end
			end

			wheels[k] = {}

			local pointers = {}

			-- Generate initial pointers
			for p = 1, k do
				pointers[p] = p
			end

			-- Get the notes' number of possible permuations
			local factorial = getFactorial(k)

			for i = 1, factorial do

				-- Index each wheel by a string of its decimal numbers
				local dec = ""
				for kk, vv in ipairs(pointers) do
					dec = dec .. vv
				end
				wheels[k][dec] = {}

				-- Build a new wheel out of the rotated pointers
				for p = 1, #pointers do

					local p2 = wrapNum(p + 1, 1, #pointers)

					-- Populate the current wheel
					if wheels[k][dec][p] == nil then
						wheels[k][dec][p] = {
							n = pointers[p],
							i = 0,
							o = pointers[p2],
						}
					else
						wheels[k][dec][p].o = pointers[p2]
					end

					-- Populate the current adjacent wheel
					if wheels[k][dec][p2] == nil then
						wheels[k][dec][p2] = {
							n = pointers[p2],
							i = pointers[p],
							o = 0,
						}
					else
						wheels[k][dec][p2].i = pointers[p]
					end

				end

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

		return wheels

	end,

	-- Index a scale by its binary note-presence identity
	indexByBin = function(t)

		local out = deepCopy(t)

		for k, v in pairs(t) do
			out[k].s = {}
			for sk, s in pairs(v.s) do
				out[k].s[s.bin] = v
			end
		end

		return out

	end,

	-- Index a given table of scales by how many notes they contain
	indexByNoteQuantity = function(t)

		local out = {}
		for i = 0, 12 do
			out[i] = {s = {}}
		end

		for k, v in pairs(t) do
			table.insert(out[v.ints[1]].s, v)
		end

		return out

	end,

	-- Remove scales that are the same combinatoric k-species as other scales
	purgeIdenticalScales = function(t)

		-- For every scale...
		for i = #t - 1, 1, -1 do

			-- For each possible position of a given scale...
			for p = 1, 11 do

				-- Rotate the scale to that position
				local rotated = rotateScale(t[i], p)

				-- If any scales match the rotated scale, remove them
				for c = i + 1, #t do
					if rotated.bin == t[c].bin then
						table.remove(t, c)
						break
					end
				end

			end

		end

		return t

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

	-- Rotate all given scales so that their first note is a filled position
	rotateToFilledPosition = function(t)

		for k, v in pairs(t) do

			local count = 0
			while (not ((t[k].bin:sub(1, 1) == "1") and (t[k].bin:sub(12, 12) == "0"))) and (count < 12) do
				t[k] = rotateScale(t[k], 1)
				count = count + 1
			end

		end

		return t

	end,


}
