
return {

	-- Generate a sequence of notes, following user-defined parameters
	generateSeqNotes = function(seq, dist, undo)

		-- If recording isn't toggled, abort function
		if not data.recording then
			return nil
		end

		local outnotes = {}
		local genscales = {}
		local genwheels = {}
		local putticks = {}

		local ticks = #data.seq[data.active].tick

		local npoffset = dist + (data.np - (data.np % 12))

		-- Convert percentage-based generator vars into floats
		local consonance = data.consonance / 100
		local scaleswitch = data.scaleswitch / 100
		local wheelswitch = data.wheelswitch / 100
		local density = data.density / 100
		local beatstick = data.beatstick / 100

		-- Limit wheel-species to wheel lengths that have been generated
		local wheelspecies = math.min(7, data.kspecies)

		-- If there are fewer scales in the k-species than in scalenum, grab all scales
		if data.scalenum >= #data.scales[data.kspecies].s then

			genscales = deepCopy(data.scales[data.kspecies].s)

		else -- Else, choose scales based on proximity to the consonance val

			-- Get a copy of the given k-species' scales
			local tempscales = deepCopy(data.scales[data.kspecies].s)

			-- Until genscales is filled with a "data.scalenum" number of scales...
			repeat

				local consodist = 0
				local closest = {}

				-- Find all scales with consonance-ranks closest to the desired consonance
				for k, v in pairs(tempscales) do
					local target = v.rank / data.scales[data.kspecies].ranks
					local thisconsodist = math.abs(target - consonance)
					if thisconsodist > consodist then
						closest = {k}
						consodist = thisconsodist
					elseif thisconsodist == consodist then
						table.insert(closest, k)
					end
				end

				-- Put the closest found scales into the genscales table,
				-- until closest-tab is empty, or genscales-tab is full.
				while (#closest >= 1)
				and (#genscales < data.scalenum)
				do
					local randkey = math.random(1, #closest)
					local chosen = table.remove(closest, randkey)
					local outscale = table.remove(tempscales, chosen)
					table.insert(genscales, outscale)
				end

			until #genscales == data.scalenum

		end

		-- Rotate each selected scale to a random position, with a leading on-note.
		for k, v in pairs(genscales) do

			local rots = {}

			for r = 0, 11 do
				local newpos = rotateScale(v, r)
				if newpos.notes[1] == 1 then
					table.insert(rots, newpos)
				end
			end

			local rotkey = math.random(1, #rots)

			genscales[k] = rots[rotkey]

			print("SCALE " .. k .. "(" .. rotkey .. "): " .. genscales[k].bin .. " - " .. table.concat(genscales[k].filled, "-")) -- debugging

		end

		-- If there are fewer wheels in the wheel-species than in wheelnum, grab them
		if data.wheelnum >= #data.wheels[wheelspecies] then

			genwheels = deepCopy(data.wheels[wheelspecies])

		else -- Else, choose wheels from the wheel-species at random

			-- Get a copy of a given wheel-species
			local tempwheels = deepCopy(data.wheels[wheelspecies])

			-- Grab random wheels from the wheel-species, until "data.wheelnum" is reached
			repeat
				local randkey = math.random(1, #tempwheels)
				local outwheel = table.remove(tempwheels, randkey)
				table.insert(genwheels, outwheel)
			until #genwheels == data.wheelnum

		end

		local beatfactors = getFactors(data.beatlength)
		local notefactors = deepCopy(beatfactors)

		-- Get all beat-factors equal to or larger than the beatgrain
		for i = #beatfactors, 1, -1 do
			if beatfactors[i] < data.beatgrain then
				table.remove(beatfactors, i)
			end
		end

		-- If no beat-factors were smaller than beatgrain, use beatlength instead
		if #beatfactors == 0 then

			table.insert(beatfactors, data.beatlength)

		-- Else, if there's more than one beatfactor...
		elseif #beatfactors > 1 then

			-- Double every factor, until surpassing the beatbound limit
			local newfactors = {}
			local larger = false
			local i = 2
			while not larger do
				for k, v in pairs(beatfactors) do
					local nf = v * i
					if nf < (data.beatbound * data.tpq * 4) then
						table.insert(newfactors, nf)
					else
						larger = true
					end
				end
				i = i + 1
			end

			-- Combine the new-factors and old-factors, remove duplicates, and sort
			beatfactors = tableCombine(beatfactors, newfactors)
			removeDuplicates(beatfactors)
			table.sort(beatfactors)

			-- Generate sub-factors
			for i = #beatfactors, 2, -1 do
				for i2 = i - 1, 1, -1 do
					local twofactors = beatfactors[i] + beatfactors[i2]
					if twofactors < (data.beatbound * data.tpq * 4) then
						table.insert(beatfactors, twofactors)
					end
				end
			end

			-- Remove duplicate sub-factors, insert the base tick, and sort again
			removeDuplicates(beatfactors)
			table.insert(beatfactors, 1, 0)
			table.sort(beatfactors)

			print(table.concat(beatfactors, ", ")) -- debugging
			
			-- Make the beat-factors correspond to the 1-indexing of ticks
			for i = 1, #beatfactors do
				beatfactors[i] = beatfactors[i] + 1
			end

		end

		-- Generate all acceptable note-sizes
		for i = #notefactors, 1, -1 do
			if notefactors[i] < data.notegrain then
				table.remove(notefactors, i)
			end
		end
		if #notefactors == 0 then
			table.insert(notefactors, data.notegrain)
		end

		-- Select the ticks that will be used to allocate notes,
		-- based on random chance, until the density quotient is fulfilled.
		repeat
			local newput = table.remove(beatfactors, math.random(#beatfactors))
			table.insert(putticks, newput)
		until ((#putticks * data.beatgrain) >= (ticks * density))
		or (#beatfactors == 0)

		-- Sort the selected ticks by position
		table.sort(putticks)

		-- Get initial scale, wheel, scale-pointer, and wheel-pointer vals
		local scale = genscales[math.random(#genscales)]
		local wheel = genwheels[math.random(#genwheels)]
		local sp = scale.filled[math.random(#scale.filled)]
		local wp = math.random(#wheel)

		local notetotal = 0

		-- Fill all selected ticks with wheel-controlled scale notes.
		for _, tick in ipairs(putticks) do

			-- Get a random duration from the acceptable note-lengths
			local dur = notefactors[math.random(#notefactors)]

			-- Get a pitch, bounded within an octave from the given note
			local pitch = wrapNum(npoffset + sp - 1, data.bounds.np)

			local note = {
				tick = tick,
				note = {
					'note',
					tick - 1,
					dur,
					data.chan,
					pitch,
					data.velo,
				}
			}

			table.insert(outnotes, note)

			-- Increment notetotal, which modifies note likelihood elsewhere
			notetotal = notetotal + data.beatgrain

			-- Shift activity to new scales and wheels, if random thresholds are met
			if math.random() < scaleswitch then
				if #genscales > 1 then
					local oldscale = scale
					repeat
						scale = genscales[math.random(#genscales)]
					until oldscale ~= scale
				end
			end
			if math.random() < wheelswitch then
				if #genwheels > 1 then
					local oldwheel = wheel
					repeat
						wheel = genwheels[math.random(#genwheels)]
					until oldwheel ~= wheel
				end
			end

			-- Go to next wheel-position, and grab the scale's corresponding note
			wp = wheel[wp]
			sp = scale.filled[wp]

		end

		setNotes(data.active, outnotes, undo)

	end,

}
