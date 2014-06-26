
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

		local genscales = {}
		local genwheels = {}

		-- Limit wheel-species to wheel lengths that have been generated
		local wheelspecies = math.min(7, data.kspecies)

		-- If there are fewer scales in the k-species than in scalenum, grab all scales
		if data.scalenum >= #data.scales[data.kspecies].s then

			genscales = deepCopy(data.scales[data.kspecies].s)

		else -- Else, choose scales based on proximity to the data.consonance val

			-- Get a copy of the given k-species' scales
			local tempscales = deepCopy(data.scales[data.kspecies].s)

			-- Until genscales is filled with a "data.scalenum" number of scales...
			repeat

				local dist = math.huge
				local closest = {}

				-- Find all scales with consonance-ranks closest to the desired consonance
				for k, v in pairs(tempscales) do
					local target = v.rank / data.scales[data.kspecies].ranks
					local thisdist = math.abs(target - data.consonance)
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
		local beatfactors = getGrainFactors(data.beatgrain, data.beatlength)
		local notefactors = getGrainFactors(data.notegrain, data.beatlength)


		-- TODO tomorrow: add stuff here!


	end,

}
