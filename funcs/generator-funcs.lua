
return {

	-- Get all factors within a given beat, down to grain size,
	-- combined and doubled up to the fill-limit.
	getGrainFactors = function(beat, grain, fill, stick, putzero, increase)

		local beatfactors = getFactors(beat)
		local factors = deepCopy(beatfactors)
		local weights = {}

		-- Get all beat-factors equal to or larger than the beatgrain
		for i = #factors, 1, -1 do
			if factors[i] < grain then
				table.remove(factors, i)
			end
		end

		-- If no beat-factors were smaller than beatgrain, use beatlength instead
		if #factors == 0 then

			table.insert(factors, beat)

		-- Else, if there's more than one beatfactor...
		elseif #factors > 1 then

			-- Double every factor, until surpassing the beatbound limit
			local newfactors = {}
			local larger = false
			local i = 2
			while not larger do
				for k, v in pairs(factors) do
					local nf = v * i
					if nf < fill then
						table.insert(newfactors, nf)
					else
						larger = true
					end
				end
				i = i + 1
			end

			-- Combine the new-factors and old-factors, remove duplicates, and sort
			factors = tableCombine(factors, newfactors)
			removeDuplicates(factors)
			table.sort(factors)

			-- Generate sub-factors
			for i = #factors, 2, -1 do
				for i2 = i - 1, 1, -1 do
					local twofactors = factors[i] + factors[i2]
					if twofactors < fill then
						table.insert(factors, twofactors)
					end
				end
			end

		end

		-- Insert a 0 into the factors table, if putzero-flag is true
		if putzero then
			table.insert(factors, 1, 0)
		end

		-- Remove duplicate sub-factors, and sort again
		removeDuplicates(factors)
		table.sort(factors)

		-- Get the weight values for each beat's prominence level
		for k, v in pairs(factors) do
			local vmod = v % beat
			local vadd = 0
			for kk, vv in pairs(beatfactors) do
				if ((vv % vmod) == 0) or ((vmod % vv) == 0) then
					vadd = vadd + 1
				end
			end
			weights[v] = vadd ^ (3 * stick)
		end

		-- Get the total sum of all weight values
		local wtotal = 0
		for k, v in pairs(weights) do
			wtotal = wtotal + v
		end

		-- Make beat-factors correspond to the 1-indexing, if increase-flag is true
		if increase then
			for i = 1, #factors do
				factors[i] = factors[i] + 1
			end
		end

		return factors, weights, wtotal

	end,

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

		local ticks = data.seq[data.active].total

		local npoffset = dist + (data.np - (data.np % 12))

		-- Convert percentage-based generator vars into floats
		local consonance = data.consonance / 100
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

		local beatfactors, beatweights, bwtotal = getGrainFactors(
			data.beatlength, -- Factor source: non-TPQ secondary beat-length
			data.beatgrain, -- Minimal acceptable factor size
			data.beatbound * data.tpq * 4, -- Doubling limit: beatmod times beats
			beatstick, -- Modifies stickiness of prominent beats
			true, -- Insert a 0 into the factor list's first position
			true -- Increase each factor by 1
		)

		local notefactors, _, _ = getGrainFactors(
			data.beatlength,
			data.notegrain,
			data.beatlength,
			beatstick,
			false,
			false
		)

		-- Select the ticks that will be used to allocate notes,
		-- based on random chance and beat-factor stickiness,
		-- until the density quotient is fulfilled.
		repeat

			-- Get a random value that covers all integers,
			-- plus all decimal values, plus the remainder.
			local wint, wmod = math.modf(bwtotal)
			local weightrand = math.random(0, wint - 1) + (math.random() * wmod) + math.random()

			local wbot, wtop = 0, 0

			-- Find the beat-value whose threshold catches the random value
			for k, v in ipairs(beatfactors) do

				-- Get the current weight range
				local weight = beatweights[v - 1]
				wbot = wtop
				wtop = wtop + weight

				-- If the random value is within the current weight range...
				if rangeCheck(weightrand, wbot, wtop) then

					-- Reduce the beat-weight total by the current weight
					bwtotal = bwtotal - weight

					-- Remove the beat from factors-table, and put it into the selected-ticks table
					table.insert(putticks, table.remove(beatfactors, k))

					break

				end

			end

		until ((#putticks * data.beatgrain) >= (ticks * density))
		or (#beatfactors == 0)

		-- Sort the selected ticks by position
		table.sort(putticks)

		-- Get initial scale, wheel, scale-pointer, and wheel-pointer vals
		local snum, wnum = math.random(#genscales), math.random(#genwheels)
		local scale, wheel = genscales[snum], genwheels[wnum]
		local sp = scale.filled[math.random(#scale.filled)]
		local wp = math.random(#wheel)

		local notetotal = 0

		-- Fill all selected ticks with wheel-controlled scale notes.
		for _, tick in ipairs(putticks) do

			-- Wrap all putticks to the sequence range
			tick = wrapNum(data.tp + tick - 1, 1, ticks)

			-- Get a random duration from the acceptable note-lengths
			local dur = notefactors[math.random(#notefactors)]

			-- Get a pitch, bounded within an octave from the given note
			local pitch = wrapNum(npoffset + sp - 1, data.bounds.np)

			local note = {
				'insert',
				{
					'note',
					tick - 1,
					dur,
					data.chan,
					pitch,
					data.velo,
				},
			}

			table.insert(outnotes, note)

			-- Increment notetotal, which modifies note likelihood elsewhere
			notetotal = notetotal + data.beatgrain

			-- Increment all scale and wheel positions
			snum = getNewThresholdKey(genscales, snum, data.scaleswitch / 100)
			wnum = getNewThresholdKey(genwheels, wnum, data.wheelswitch / 100)
			scale = genscales[snum]
			wheel = genwheels[wnum]
			wp = wheel[wp]
			sp = scale.filled[wp]

		end

		setNotes(data.active, outnotes, undo)

	end,

}
