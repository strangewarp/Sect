
return {
	
	-- Draw all tinted beat-solumns in the sequence pane
	drawBeatColumns = function(tintcolumns)

		for k, v in ipairs(tintcolumns) do
			local tick, colleft, coltop, colwidth, colheight, color = unpack(v)
			love.graphics.setColor(color)
			love.graphics.rectangle("fill", colleft, coltop, colwidth, colheight)
		end

	end,

	-- Render a table of beat-triangles
	drawBeatTriangles = function(tris, beatsize, yfull, tritop, trifonttop)
	
		for k, v in ipairs(tris) do

			local tick, xpos = unpack(v)
			local beat = ((tick - 1) / beatsize) + 1

			love.graphics.setColor(data.color.seq.highlight)
			love.graphics.polygon("fill", xpos - 19, yfull, xpos + 19, yfull, xpos, tritop)
			love.graphics.setColor(data.color.font.light)
			love.graphics.printf(beat, xpos - 19, trifonttop, 38, "center")

		end

	end,

	-- Draw the reticules that show the position and size of current note-entry
	drawReticules = function(left, top, right, xhalf, yhalf, xcellhalf, ycellhalf, cellwidth)

		local trh = 38
		local trl = left + xhalf - 19
		local trt = top + yhalf - 19
		local trr = trl + trh
		local trb = trt + trh
		trt = trt - ycellhalf
		trb = trb + ycellhalf
		
		local nrh = ycellhalf
		local nrlr = left + xhalf - xcellhalf
		local nrll = nrlr - nrh
		local nrrl = nrlr + (cellwidth * data.dur)
		local nrrr = nrrl + nrh
		local nrt = yhalf - nrh
		local nrb = yhalf + nrh

		-- Draw the tick reticule
		love.graphics.setColor(data.color.reticule.dark)
		love.graphics.polygon(
			"fill",
			trl, trt,
			trr, trt,
			left + xhalf, top + yhalf - ycellhalf
		)
		love.graphics.polygon(
			"fill",
			trl, trb,
			trr, trb,
			left + xhalf, top + yhalf + ycellhalf
		)

		-- Draw the note-duration reticule
		love.graphics.setColor(data.color.reticule.light)
		love.graphics.polygon(
			"fill",
			nrll, nrt,
			nrlr, yhalf,
			nrll, nrb
		)
		if nrrl < right then
			love.graphics.polygon(
				"fill",
				nrrr, nrt,
				nrrl, yhalf,
				nrrr, nrb
			)
		end

	end,

}