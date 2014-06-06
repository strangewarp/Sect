
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
		local rotscales = {}
		local similar = {}
		local scale = {
			["notes"] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			["bin"] = "",
		}
		local filled = 0
		local foundbin = ""
		local foundthresh = -ticks

		-- Populate the thresholds table with default values
		local thresholds = {}
		for i = 1, 12 do
			thresholds[i] = 0
		end

		-- For all notes in the active sequence...
		for k, v in pairs(notes) do

			-- Wrap the testtick to the tick-pointer position
			local testtick = ((v.tick > data.tp) and (v.tick - ticks)) or v.tick

			local newnote = true

			-- If the note is a NOTE command, add the note and testtick to found-tab
			if v.note[1] == 'note' then
				table.insert(found, {testtick, deepCopy(v)})
			else -- If the note wasn't a NOTE command, set newnote-flag to false
				newnote = false
			end

		end

		table.sort(found, function(a, b) return a[1] < b[1] end)

		-- Translate the nearest found-notes into a found-scale,
		-- until the scalesize limit is reached.
		for i = #found, 1, -1 do

			-- Wrap the pitch-value to a generic pitch-within-an-octave
			local n = wrapNum(found[i][2].note[5] + 1, 1, 12)

			-- If the found-scale-note is unfilled, fill it;
			-- if the filled notes equal the notecompare-limit, break from loop.
			if scale.notes[n] == 0 then
				scale.notes[n] = 1
				filled = filled + 1
				if filled == data.notecompare then
					do break end
				end
			end

		end

		-- Get the found-scale's binary identity
		scale.bin = table.concat(scale.notes)
		rotscales[1] = scale

		-- Get all possible rotations of the scale
		for i = 2, 12 do
			rotscales[i] = rotateScale(rotscales[1], i - 1)
		end

		-- For all scales of the current comparison-k-species...
		for _, v in pairs(data.scales[data.kspecies]) do

			-- For every rotation of the found-scale, get the scale-diff,
			-- and add the scale to the similar-tab, indexed by diff.
			for rk, rv in pairs(rotscales) do
				local diff = getScaleDifference(v.notes, rv.notes)
				similar[diff] = similar[diff] or {}
				table.insert(similar[diff], v)
			end

		end

		-- Weigh note-consonance thresholds, based on scale-similarity,
		-- resulting in the largest threshold being most-consonant.
		for i = 1, 12 do
			for k, v in pairs(similar[i]) do
				for diff, n in pairs(v.notes) do
					thresholds[diff] = thresholds[diff] + (n * k)
				end
			end
		end
		for i = 1, 12 do
			thresholds[i] = thresholds[i] / #similar
		end

		-- Display note-suggestion window

		local xcellhalf = cellwidth / 2
		local ycellhalf = cellheight / 2

		local wbgleft = xanchor + (data.spacing * cellwidth) + xcellhalf
		local wbgtop = yanchor - (cellheight * 12.5)
		local wbgwidth = cellwidth * 2
		local wbgheight = cellheight * 13.5

		local scaleleft = wbgleft + xcellhalf
		local scaletop = wbgtop + ycellhalf

		love.graphics.setColor(data.color.scale.background)
		love.graphics.rectangle("fill", wbgleft, wbgtop, wbgwidth, wbgheight)
		love.graphics.setColor(data.color.scale.border)
		love.graphics.rectangle("line", wbgleft, wbgtop, wbgwidth, wbgheight)

		for k, v in ipairs(thresholds) do

			local notetop = scaletop + (cellheight * (k - 1))
			local notexcenter = notetop + ycellhalf
			local noteycenter = scaleleft + xcellhalf
			local consonant = deepCopy(data.color.scale.consonant)
			local dissonant = deepCopy(data.color.scale.dissonant)

			local notecolor = mixColors(consonant, dissonant, v)

			love.graphics.setColor(notecolor)
			love.grphics.rectangle("fill", scaleleft, notetop, cellwidth, cellheight)
			love.graphics.setColor(data.color.scale.note_border)
			love.grphics.rectangle("line", scaleleft, notetop, cellwidth, cellheight)

			love.graphics.setColor(notecolor)
			love.graphics.setLineWidth(2)
			love.graphics.line(xanchor, yanchor, notexcenter, noteycenter)
			love.graphics.setLineWidth(1)

		end

	end,

}
