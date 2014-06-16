
return {
	
	buildChordPanel = function()

	end,

	-- Build the Scale Mode suggestion panel
	drawScalePanel = function(
		left, top, width, height,
		xanchor, yanchor,
		cellwidth, cellheight
	)

		-- If there is no active sequence, abort function
		if data.active == false then
			return nil
		end

		local notes = getNotes(data.active)
		local ticks = #data.seq[data.active].tick

		local found = {}
		local foundnums = {}
		local similar = {}
		local thresholds = {}

		local scale = {
			["notes"] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			["bin"] = "",
		}

		local filled = 0

		local biggest = 0
		local smallest = math.huge

		local ycellhalf = cellheight / 2
		local wbgtop = top + yanchor - (cellheight * (12 - wrapNum(data.np, 0, 11)))
		local scaletop = wbgtop + ycellhalf

		-- Populate the thresholds table with default values
		for i = 1, 12 do
			thresholds[i] = 0
			similar[i] = {}
		end

		-- For all notes in the active sequence...
		for k, v in pairs(notes) do

			-- Wrap the testtick to the tick-pointer position
			local testtick = ((v.tick > data.tp) and (v.tick - ticks)) or v.tick

			-- If the note is a NOTE command, add the note and testtick to found-tab
			if v.note[1] == 'note' then
				table.insert(found, {testtick, deepCopy(v)})
			end

		end

		table.sort(found, function(a, b) return a[1] < b[1] end)

		-- Translate the nearest found-notes into a found-scale,
		-- until the notecompare limit is reached.
		for i = #found, 1, -1 do

			-- Wrap the pitch-value to a generic pitch-within-an-octave
			local n = wrapNum(found[i][2].note[5] + 1, 1, 12)

			-- If the found-scale-note is unfilled, fill it;
			-- if the filled notes equal the notecompare-limit, break from loop.
			if scale.notes[n] == 0 then
				scale.notes[n] = 1
				foundnums[n] = true
				filled = filled + 1
				if filled == data.notecompare then
					do break end
				end
			end

		end

		-- Get the found-scale's binary identity
		scale.bin = table.concat(scale.notes)

		-- For all scales of the current comparison-k-species...
		for _, v in pairs(data.scales[data.kspecies].s) do

			for i = 1, 12 do

				local rot = rotateScale(v, i - 1)
				local diff = getScaleDifference(scale.notes, rot.notes)

				diff = diff + 1

				similar[diff] = similar[diff] or {}
				table.insert(similar[diff], rot)

			end

		end

		-- Combine diff values into thresholds
		for diff, difftab in pairs(similar) do
			for sk, s in pairs(difftab) do
				local consodist = s.conso - data.scales[data.kspecies].con
				for nk, n in pairs(s.notes) do
					if n == 1 then
						thresholds[nk] = thresholds[nk] + (consodist / diff)
						biggest = math.max(biggest, thresholds[nk])
					end
				end
			end
		end

		for i = 1, 12 do
			smallest = math.min(smallest, thresholds[i])
		end
		for i = 1, 12 do
			thresholds[i] = thresholds[i] - smallest
		end
		biggest = biggest - smallest

		-- Display note-suggestion lines
		for k, v in ipairs(thresholds) do

			-- If the scale-note is within the current active octave, render its bar
			if (((data.np - (12 - wrapNum(data.bounds.np[2] + 1, 1, 12))) + 12) <= data.bounds.np[2])
			or (k <= wrapNum(data.bounds.np[2] + 1, 1, 12))
			then

				local notetop = scaletop + (cellheight * (12 - k))
				local noteycenter = notetop + ycellhalf
				local consonant = deepCopy(data.color.scale.consonant)
				local dissonant = deepCopy(data.color.scale.dissonant)

				local notecolor = mixColors(consonant, dissonant, v / biggest)
				if foundnums[k] ~= nil then
					notecolor = mixColors(notecolor, data.color.scale.filled, 0.6)
				end

				love.graphics.setColor(notecolor)
				love.graphics.setLineWidth(math.max(2, cellheight / 3))
				love.graphics.line(left, noteycenter, left + width, noteycenter)
				love.graphics.setLineWidth(1)

			end

		end

	end,

}
