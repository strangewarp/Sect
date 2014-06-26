
return {

	-- Get all grain lengths that are factors of "max", down to "min",
	-- plus combinations of said factors, up to "max".
	getGrainFactors = function(min, max)

		local factors = getFactors(max)
		local grains = {}

		-- Remove all factors smaller than min
		for i = #factors, 1, -1 do
			if factors[i] < min then
				table.remove(factors, i)
			end
		end

		-- If all factors were removed, add max as the only factor
		if #factors == 0 then
			factors[1] = max
		end

		-- For every factor, add its multiples in the same grain-species
		for k, v in ipairs(factors) do
			grains[v] = {v}
			for i = v * 2, max, v do
				table.insert(grains[v], i)
			end
		end

		return grains

	end,

	-- Generate a sequence of notes, following user-defined parameters
	generateSeqNotes = function(seq, dist, undo)

		-- If recording isn't toggled, abort function
		if not data.recording then
			return nil
		end

		math.randomseed(os.time())

		local outnotes = {}

		local genscales = {}
		local genwheels = {}

		-- Convert percentage-based generator vars into floats
		local consonance = data.consonance / 100
		local scaleswitch = data.scaleswitch / 100
		local wheelswitch = data.wheelswitch / 100
		local density = data.density / 100
		local beatstick = data.beatstick / 100

		local nlow = data.lownote
		local nhigh = math.max(nlow, data.highnote)

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

				local dist = math.huge
				local closest = {}

				-- Find all scales with consonance-ranks closest to the desired consonance
				for k, v in pairs(tempscales) do
					local target = v.rank / data.scales[data.kspecies].ranks
					local thisdist = math.abs(target - consonance)
					if thisdist < dist then
						closest = {k}
					elseif thisdist == dist then
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

		-- Get all beat and note grains of the secondary non-TPQ beatlength
		local beatgrains = getGrainFactors(data.beatgrain, data.beatlength)
		local notegrains = getGrainFactors(data.notegrain, data.beatlength)

		-- Get the size of the range into which to generate a sequence
		local limit = math.min(data.beatbound * data.tpq * 4, #data.seq[data.active].tick)

		-- Get initial scale, wheel, scale-pointer, and wheel-pointer
		local scale = genscales[math.random(#genscales)]
		local wheel = genwheels[math.random(#genwheels)]
		local sp = math.random(#scale.filled)
		local wp = math.random(#wheel)

		local durtotal = 0

		-- For every tick within the limit-range...
		for i = 1, limit do

			-- Get the concrete tick value, as offset by tick-pointer
			local tick = wrapNum(data.tp + i - 1, 1, #data.seq[data.active].tick)

			-- Get the within-beatlength tick value, shifted to 0-indexing
			local subtick = wrapNum(tick, 1, data.beatlength) - 1

			-- Get the current note-density threshold
			local threshold = math.max(0, density - (durtotal / i))
			local stickthresh = threshold - beatstick
			local modthresh = stickthresh
			local chance = math.random()

			local okbeats = {}

			-- Find all values that fit the current beat, and index acceptable ones
			local beatfits = {}
			for val, thresh in pairs(beatgrains) do
				if (tick % val) == 0 then
					modthresh = stickthresh + (val / data.beatlength)
					if modthresh > chance then
						okbeats[thresh] = true
					end
				end
			end

			-- If the subtick is acceptable, put a note of some kind into outnotes,
			-- based on scale and wheel iterators.
			if okbeats[subtick] ~= nil then

				local dur = notegrains[math.random(#notegrains)]

				local pitches = getTileAxisBounds(dist + scale.filled[sp], 12, nlow, nhigh)
				local pitch = pitches[math.random(#pitches)].a

				local note = {
					["tick"] = tick,
					["note"] = {
						'note',
						tick - 1,
						dur,
						data.chan,
						pitch,
						data.velocity,
					}
				}

				table.insert(outnotes, note)

				-- Add the duration to the durtotal, which modifies density elsewhere
				durtotal = durtotal + dur

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

				wp = wheel[wp]
				sp = scale.notes[scale.filled[wp]]

			end

		end

		setNotes(data.active, outnotes, undo)

	end,

}
