
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

		local breadth = data.size.triangle.breadth
		local bhalf = breadth / 2
		local bhalfout = bhalf + 1
	
		for k, v in ipairs(tris) do

			local beat, xpos = unpack(v)

			love.graphics.setColor(data.color.triangle.fill)

			if (xpos - bhalfout) < data.size.sidebar.width then
				local xleft = data.size.sidebar.width
				local yshort = tritop + (xpos - xleft)
				love.graphics.polygon("fill", xleft, yshort, xleft, yfull, xpos + bhalf, yfull, xpos, tritop)
				love.graphics.setColor(data.color.triangle.line)
				love.graphics.line(xleft, yshort, xpos, tritop, xpos + bhalfout, yfull + 2)
			else
				love.graphics.polygon("fill", xpos - bhalf, yfull, xpos + bhalf, yfull, xpos, tritop)
				love.graphics.setColor(data.color.triangle.line)
				love.graphics.line(xpos - bhalfout, yfull + 1, xpos, tritop, xpos + bhalfout, yfull + 1)
			end

			love.graphics.setColor(data.color.triangle.text)
			love.graphics.setFont(data.font.beat.raster)
			love.graphics.printf(beat, xpos - bhalf, trifonttop, breadth, "center")

		end

	end,

	-- Draw the reticules that show the position and size of current note-entry
	drawReticules = function(left, top, right, xhalf, yhalf, xcellhalf, ycellhalf)

		local trh = data.size.reticule.breadth
		local trl = left + xhalf - (data.size.reticule.breadth / 2)
		local trt = top + yhalf - (data.size.reticule.breadth / 2)
		local trr = trl + trh
		local trb = trt + trh
		trt = trt - ycellhalf
		trb = trb + ycellhalf
		
		local nrh = ycellhalf
		local nrlr = left + xhalf - xcellhalf
		local nrll = nrlr - nrh
		local nrrl = nrlr + (data.cellwidth * data.dur)
		local nrrr = nrrl + nrh
		local nrt = yhalf - nrh
		local nrb = yhalf + nrh

		-- Draw the tick reticule
		if data.recording then
			if data.cmdmode == "gen" then
				love.graphics.setColor(data.color.reticule.generator)
			elseif data.cmdmode == "cmd" then
				love.graphics.setColor(data.color.reticule.cmd)
			else
				love.graphics.setColor(data.color.reticule.recording)
			end
		else
			if data.cmdmode == "gen" then
				love.graphics.setColor(data.color.reticule.generator_dark)
			elseif data.cmdmode == "cmd" then
				love.graphics.setColor(data.color.reticule.cmd_dark)
			else
				love.graphics.setColor(data.color.reticule.dark)
			end
		end
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
		if not data.recording then
			love.graphics.setColor(data.color.reticule.light)
		end
		love.graphics.polygon(
			"fill",
			nrll, nrt,
			nrlr, yhalf,
			nrll, nrb
		)
		if data.cmdmode ~= "cmd" then -- Only draw right reticule arrow if Cmd Mode is inactive
			if nrrl < right then
				love.graphics.polygon(
					"fill",
					nrrr, nrt,
					nrrl, yhalf,
					nrrr, nrb
				)
			end
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
	drawSeqGrid = function(left, top, right, bot)

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

		-- Reticule anchor coordinates
		local xanchor = xfull * data.size.anchor.x
		local yanchor = yfull * data.size.anchor.y

		-- Halved cell sizes, for later GUI positioning
		local xcellhalf = data.cellwidth / 2
		local ycellhalf = data.cellheight / 2

		-- Total number of grid-cells along both axes
		local xcells = math.ceil(xfull / data.cellwidth)
		local ycells = math.ceil(yfull / data.cellheight)

		-- Number of cells between anchor point and grid origin borders
		local xleftcells = math.ceil(xanchor / data.cellwidth)
		local ytopcells = math.ceil(yanchor / data.cellheight)

		-- Positions for the left and top grid borders, adjusted to anchor point
		local gridleft = (xanchor - (xleftcells * data.cellwidth)) - xcellhalf
		local gridtop = (yanchor - (ytopcells * data.cellheight)) - ycellhalf

		-- Leftmost/topmost unwrapped tick and note values, for grid rendering
		local lefttick = wrapNum(data.tp - xleftcells, 1, ticks)
		local topnote = wrapNum(data.np + ytopcells, data.bounds.np)

		-- Left/top boundaries of sequence's current, non-wrapped chunk
		local tboundary = xanchor - ((data.cellwidth * (data.tp - 1)) + xcellhalf)
		local nboundary = yanchor - ((data.cellheight * (data.bounds.np[2] - data.np)) + ycellhalf)

		-- Sequence's full width and height, in pixels
		local fullwidth = data.cellwidth * ticks
		local fullheight = data.cellheight * notes

		-- If note-cells are less than 1 wide, keep tick-columns from vanishing
		local colwidth = math.max(1, data.cellwidth)

		-- All boundaries for wrapping the sequence's display
		local xranges = getTileAxisBounds(0, xfull, tboundary, fullwidth)
		local yranges = getTileAxisBounds(0, yfull, nboundary, fullheight)

		-- Positioning for beat-triangles
		local trifontheight = data.font.beat.raster:getHeight()
		local trifonttop = yfull - (trifontheight + 1)
		local tritop = yfull - (data.size.triangle.breadth / 2)

		-- Initialize the local tables that will be populated
		local tintcolumns, drawnotes, drawsels, triangles = {}, {}, {}, {}

		-- Render the seq-window's background
		love.graphics.setColor(data.color.seq.light)
		love.graphics.rectangle("fill", left, top, xfull, yfull)

		-- Render the seq-window's background-image
		drawBoundedImage(left, top, xfull, yfull, data.img.grid)

		-- If Cmd Mode isn't active, draw highlighted rows
		if data.cmdmode ~= "cmd" then

			-- Set color for rendering darkened rows
			love.graphics.setColor(data.color.seq.dark)

			-- Find and render darkened rows
			for y = 0, ycells + 1 do

				-- Get row's Y-center and Y-top
				local ytop = gridtop + (data.cellheight * y)

				-- Get the row's corresponding note, and the note's scale position
				local note = wrapNum(topnote - y, data.bounds.np)
				local notetype = data.pianometa[wrapNum(note + 1, 1, 12)][1]

				-- On black-key rows, render dark overlays
				if notetype == 0 then
					love.graphics.rectangle("fill", left, ytop, xfull, data.cellheight)
				end

				-- Highlight the active note-row
				if note == data.np then
					love.graphics.setColor(data.color.seq.active)
					love.graphics.rectangle("fill", left, ytop, xfull, data.cellheight)
					love.graphics.setColor(data.color.seq.dark)
				end

			end

		end

		-- Find and render tick-columns
		for x = 0, xcells do

			local xleft = gridleft + (data.cellwidth * x)

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
				table.insert(tintcolumns, {tick, left + xleft, top, colwidth, yfull, color})
			end

			-- If active column, table activity-color for later rendering
			if tick == data.tp then
				local color = data.color.seq.active
				table.insert(tintcolumns, {tick, left + xleft, top, colwidth, yfull, color})
			end

			-- If this column is on a beat, add a triangle to the beat-triangle-table
			if ((tick - 1) % beatsize) == 0 then
				local beat = ((tick - 1) / beatsize) + 1
				local trileft = left + gridleft + xcellhalf + (x * data.cellwidth)
				table.insert(triangles, {beat, trileft})
			end

		end

		-- Get render-note data from all visible sequences
		for snum, s in pairs(data.seq) do

			local render = false

			-- Assign render type based on notedraw and shadow activity
			if data.drawnotes then
				if snum == data.active then
					render = 'normal'
				elseif s.overlay then
					render = 'shadow'
				end
			else
				if s.overlay then
					render = 'shadow'
				end
			end

			-- If the shadow-seq is a different length than the active seq,
			-- wrap the shadow-seq onto the active-seq accordingly.
			local tempxr = deepCopy(xranges)
			if snum ~= data.active then
				if #s.tick ~= ticks then
					tempxr = getTileAxisBounds(0, xfull, tboundary, data.cellwidth * #s.tick)
				end
			end

			-- If the sequence is to be rendered...
			if render then

				-- If Cmd Mode is active, use only one vertical render-range
				if data.cmdmode == "cmd" then
					yranges = {{a = -math.huge, b = yanchor - ycellhalf, o = 0}}
				end

				-- Add visible notes to the drawnotes table
				drawnotes = tableCombine(
					drawnotes,
					makeNoteRenderTable(
						render,
						snum, s.tick,
						left, top, xfull, yfull,
						tempxr, yranges
					)
				)
			end

		end

		-- If there is a selection range, find and store its coordinates
		if data.sel.l then

			local selleft = ((data.sel.l - 1) * data.cellwidth)
			local seltop = (data.bounds.np[2] - data.sel.t) * data.cellheight

			local selwidth = data.cellwidth * ((data.sel.r - data.sel.l) + 1)
			local selheight = data.cellheight * ((data.sel.t - data.sel.b) + 1)

			drawsels = makeSelectionRenderTable(
				left, top, xfull, yfull,
				selleft, seltop, selwidth, selheight,
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
		drawReticules(left, top, right, xanchor, yanchor, xcellhalf, ycellhalf)

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

				local sw = selwidth

				-- Get the concrete offsets of the wrapped selection position
				local l = left + xr.a + selleft
				local t = top + yr.a + seltop + (data.cellheight * yr.o)

				-- Clip the portion of the selection that would overflow the left border
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
