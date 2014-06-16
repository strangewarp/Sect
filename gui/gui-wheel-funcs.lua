
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

		local ycellhalf = cellheight / 2
		local wbgtop = top + yanchor - (cellheight * (12 - wrapNum(data.np, 0, 11)))
		local scaletop = wbgtop + ycellhalf

		-- Find the bigest consonance-threshold val
		local biggest = 0
		for _, v in pairs(data.thresholds) do
			biggest = math.max(biggest, v)
		end

		-- Display note-suggestion lines
		for k, v in ipairs(data.thresholds) do

			-- If the scale-note is within the current active octave, render its bar
			if (((data.np - (12 - wrapNum(data.bounds.np[2] + 1, 1, 12))) + 12) <= data.bounds.np[2])
			or (k <= wrapNum(data.bounds.np[2] + 1, 1, 12))
			then

				local notetop = scaletop + (cellheight * (12 - k))
				local noteycenter = notetop + ycellhalf
				local consonant = deepCopy(data.color.scale.consonant)
				local dissonant = deepCopy(data.color.scale.dissonant)

				local notecolor = mixColors(consonant, dissonant, v / biggest)
				if data.scalenotes[k] ~= nil then
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
