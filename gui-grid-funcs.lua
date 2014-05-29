
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

	-- Draw a table of wrapped visible selection-positions
	drawSelectionTable = function(sels)

		love.graphics.setLineWidth(2)

		for k, v in pairs(sels) do

			local l, t, w, h = unpack(v)

			love.graphics.setColor(data.color.selection.fill)
			love.graphics.rectangle("fill", l, t, w, h)

			love.graphics.setColor(data.color.selection.line)
			love.graphics.rectangle("line", l, t, w, h)

		end

		love.graphics.setLineWidth(1)

	end,

	-- Make a wrapping render-table of all visible positions of the selection
	makeSelectionRenderTable = function(
		left, top, xfull, yfull,
		selleft, seltop, selwidth, selheight,
		xranges, yranges
	)

		local sels = {}

		-- For every combination of on-screen X-ranges and Y-ranges,
		-- check the selection's visibility there, and render if visible.
		for _, xr in pairs(xranges) do
			for _, yr in pairs(yranges) do

				-- Get the concrete offsets of the wrapped selection position
				local l = left + xr.a + selleft
				local t = top + yr.a + seltop

				-- If the selection is onscreen in this chunk, table it for display
				if collisionCheck(left, top, xfull, yfull, l, t, selwidth, selheight) then
					table.insert(sels, {l, t, selwidth, selheight})
				end

			end
		end

		return sels

	end,

}