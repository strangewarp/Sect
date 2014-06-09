
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

			love.graphics.setColor(data.color.triangle.fill)
			love.graphics.polygon("fill", xpos - 19, yfull, xpos + 19, yfull, xpos, tritop)

			love.graphics.setLineWidth(2)
			love.graphics.setColor(data.color.triangle.line)
			love.graphics.line(xpos - 21, yfull + 2, xpos, tritop, xpos + 21, yfull + 2)
			love.graphics.setLineWidth(1)

			love.graphics.setColor(data.color.triangle.text)
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

	-- Draw the sequence-grid, centered on the active note and tick, and corresponding to the piano-roll
	drawSeqGrid = function(left, top, right, bot, cellheight)

		-- All factors of the ticks-per-beat, for later column colorization
		local beatsize = data.tpq * 4
		local factors = getFactors(beatsize)

		-- Get the threshold for which sub-beat columns should be colorized
		local beatthresh = data.tpq / 2

		-- Get the number of ticks in the active sequence, and global notes
		local ticks = #data.seq[data.active].tick
		local notes = data.bounds.np[2] - data.bounds.np[1]

		-- Get visible/invisible versions of the beat-color, for mixing
		local beatcolor = deepCopy(data.color.seq.beat)
		local invis = deepCopy(data.color.seq.beat)
		invis[4] = 0

		-- Grid-panel's full X and Y size
		local xfull = right - left
		local yfull = bot - top

		-- Seq-grid-center coordinates
		local xhalf = xfull / 2
		local yhalf = yfull / 2

		-- Reticule anchor coordinates
		local xanchor = xfull / 3
		local yanchor = yfull / 1.7

		-- Tick-column width, based on zoom
		local cellwidth = (xhalf / data.tpq) / data.zoomx

		-- Halved cell sizes, for later GUI positioning
		local xcellhalf = cellwidth / 2
		local ycellhalf = cellheight / 2

		-- Total number of grid-cells along both axes
		local xcells = math.ceil(xfull / cellwidth)
		local ycells = math.ceil(yfull / cellheight)

		-- Number of cells between anchor point and grid origin borders
		local xleftcells = math.ceil(xanchor / cellwidth)
		local ytopcells = math.ceil(yanchor / cellheight)

		-- Positions for the left and top grid borders, adjusted to anchor point
		local gridleft = (xanchor - (xleftcells * cellwidth)) - xcellhalf
		local gridtop = (yanchor - (ytopcells * cellheight)) - ycellhalf

		-- Leftmost/topmost unwrapped tick and note values, for grid rendering
		local lefttick = wrapNum(data.tp - xleftcells, 1, ticks)
		local topnote = wrapNum(data.np + ytopcells, data.bounds.np)

		-- Left/top boundaries of sequence's current, non-wrapped chunk
		local tboundary = xanchor - ((cellwidth * (data.tp - 1)) + xcellhalf)
		local nboundary = yanchor - ((cellheight * (data.bounds.np[2] - data.np)) + ycellhalf)

		-- Sequence's full width and height, in pixels
		local fullwidth = cellwidth * ticks
		local fullheight = cellheight * notes

		-- All boundaries for wrapping the sequence's display
		local xranges = getTileAxisBounds(0, xfull, tboundary, fullwidth)
		local yranges = getTileAxisBounds(0, yfull, nboundary, fullheight)

		-- Positioning for beat-triangles
		local trifontheight = fontsmall:getHeight()
		local trifonttop = yfull - (fontsmall:getHeight() + 1)
		local tritop = trifonttop - trifontheight

		-- Initialize the local tables that will be populated
		local tintcolumns, drawnotes, drawsels, triangles = {}, {}, {}, {}

		-- Render the seq-window's background
		love.graphics.setColor(data.color.seq.light)
		love.graphics.rectangle("fill", left, top, xfull, yfull)

		-- Set color for rendering darkened rows
		love.graphics.setColor(data.color.seq.dark)

		-- Find and render darkened rows
		for y = 0, ycells + 1 do

			-- Get row's Y-center and Y-top
			local ytop = gridtop + (cellheight * y)

			-- Get the row's corresponding note, and the note's scale position
			local note = wrapNum(topnote - y, data.bounds.np)
			local notetype = data.pianometa[wrapNum(note + 1, 1, 12)][1]

			-- On black-key rows, render dark overlays
			if notetype == 0 then
				love.graphics.rectangle("fill", left, ytop, xfull, cellheight)
			end

			-- Highlight the active note-row
			if note == data.np then
				love.graphics.setColor(data.color.seq.active)
				love.graphics.rectangle("fill", left, ytop, xfull, cellheight)
				love.graphics.setColor(data.color.seq.dark)
			end

		end

		-- Find and render tick-columns
		for x = 0, xcells do

			local xleft = gridleft + (cellwidth * x)

			-- Get the row's corresponding tick
			local tick = wrapNum(lefttick + x, 1, ticks)

			-- See whether the current column is a factor of the beat
			local adjtick = wrapNum(tick, 1, beatsize)
			local afactor = 1
			for i = #factors, 1, -1 do
				if wrapNum(adjtick - 1, 0, factors[i] - 1) == 0 then
					afactor = factors[i]
					break
				end
			end

			-- If factor-column, table for later rendering
			if afactor >= beatthresh then
				local color = mixColors(beatcolor, invis, 1 - (1 / (beatsize / afactor)))
				table.insert(tintcolumns, {tick, left + xleft, top, cellwidth, yfull, color})
			end

			-- If active column, table activity-color for later rendering
			if tick == data.tp then
				local color = data.color.seq.active
				table.insert(tintcolumns, {tick, left + xleft, top, cellwidth, yfull, color})
			end

			-- If this column is on a beat, add a triangle to the beat-triangle-table
			if (tick % beatsize) == 0 then
				local beat = tick / beatsize
				local trileft = left + gridleft + xcellhalf + ((x + 1) * cellwidth)
				table.insert(triangles, {beat, trileft})
			end

		end

		-- Get render-note data from all visible sequences
		for snum, s in pairs(data.seq) do

			local render = false

			-- Get all on-screen notes
			if data.drawnotes
			and (snum == data.active)
			then
				render = 'normal'
			end

			-- Get all shadow notes
			if s.overlay
			and (
				(data.drawnotes and (snum ~= data.active))
				or ((not data.drawnotes) and (snum == data.active))
			)
			then
				render = 'shadow'
			end

			-- Add visible notes to the drawnotes tab
			if render then
				drawnotes = tableCombine(
					drawnotes,
					makeNoteRenderTable(
						render,
						seq, s.tick,
						left, top, xfull, yfull,
						cellwidth, cellheight, xranges, yranges
					)
				)
			end

		end

		-- If there is a selection range, find and store its coordinates
		if data.sel.l then

			local selleft = ((data.sel.l - 1) * cellwidth)
			local seltop = (data.bounds.np[2] - data.sel.t) * cellheight

			local selwidth = cellwidth * ((data.sel.r - data.sel.l) + 1)
			local selheight = cellheight * ((data.sel.t - data.sel.b) + 1)

			drawsels = makeSelectionRenderTable(
				left, top, xfull, yfull,
				selleft, seltop, selwidth, selheight,
				cellwidth, cellheight,
				xranges, yranges
			)

		end

		-- Draw all tinted beat-columns
		drawBeatColumns(tintcolumns)

		-- Draw all overlay-notes on top of the sequence grid
		drawNoteTable(drawnotes)

		-- Draw all wrapped selection blocks
		drawSelectionTable(drawsels)

		-- Draw all beat-triangles along the bottom of the sequence frame
		drawBeatTriangles(triangles, beatsize, yfull, tritop, trifonttop)

		-- Draw the tick and note-duration reticules
		drawReticules(left, top, right, xanchor, yanchor, xcellhalf, ycellhalf, cellwidth)

		-- If scale-mode is active, draw the scale-suggestion panel
		if data.scalemode then
			drawScalePanel(
				left, top, width, height,
				xanchor, yanchor,
				cellwidth, cellheight
			)
		end

	end,

	-- Make a wrapping render-table of all visible positions of the selection
	makeSelectionRenderTable = function(
		left, top, xfull, yfull,
		selleft, seltop, selwidth, selheight,
		cellwidth, cellheight,
		xranges, yranges
	)

		local sels = {}

		-- For every combination of on-screen X-ranges and Y-ranges,
		-- check the selection's visibility there, and render if visible.
		for _, xr in pairs(xranges) do
			for _, yr in pairs(yranges) do

				local sw = selwidth

				-- Get the concrete offsets of the wrapped selection position
				local l = left + xr.a + selleft
				local t = top + yr.a + seltop + (cellheight * yr.o)

				if l < left then
					sw = sw - (left - l)
					l = left
				end

				-- If the selection is onscreen in this chunk, table it for display
				if collisionCheck(left, top, xfull, yfull, l, t, sw, selheight) then
					table.insert(sels, {l, t, sw, selheight})
				end

			end
		end

		return sels

	end,

}
