
return {
	
	-- Draw all tinted beat-solumns in the sequence pane
	drawBeatColumns = function(tintcolumns)

		for k, v in ipairs(tintcolumns) do

			local tick, colleft, coltop, colwidth, colheight, color = unpack(v)

			-- If any portion of the column is within the seq-panel...
			if (colleft + colwidth) >= D.size.sidebar.width then

				-- Crop the tinted column to the seq-panel's left border
				if colleft < D.size.sidebar.width then
					colwidth = colwidth - (D.size.sidebar.width - colleft)
					colleft = D.size.sidebar.width
				end

				love.graphics.setColor(color)
				love.graphics.rectangle("fill", colleft, coltop, colwidth, colheight)

			end

		end

	end,

	-- Draw the reticules that show the position and size of current note-entry
	drawReticules = function(left, top, right, xhalf, yhalf, xcellhalf, ycellhalf)

		local trh = D.size.reticule.breadth
		local trl = left + xhalf - (D.size.reticule.breadth / 2)
		local trt = top + yhalf - (D.size.reticule.breadth / 2)
		local trr = trl + trh
		local trb = trt + trh
		trt = trt - ycellhalf
		trb = trb + ycellhalf
		
		local nrh = ycellhalf
		local nrlr = left + xhalf - xcellhalf
		local nrll = nrlr - nrh
		local nrrl = nrlr + (D.cellwidth * D.dur)
		local nrrr = nrrl + nrh
		local nrt = yhalf - nrh
		local nrb = yhalf + nrh

		-- Draw the tick reticule
		if D.recording then
			if D.cmdmode == "gen" then
				love.graphics.setColor(D.color.reticule.generator)
			elseif D.cmdmode == "cmd" then
				love.graphics.setColor(D.color.reticule.cmd)
			else
				love.graphics.setColor(D.color.reticule.recording)
			end
		else
			if D.cmdmode == "gen" then
				love.graphics.setColor(D.color.reticule.generator_dark)
			elseif D.cmdmode == "cmd" then
				love.graphics.setColor(D.color.reticule.cmd_dark)
			else
				love.graphics.setColor(D.color.reticule.dark)
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
		if not D.recording then
			love.graphics.setColor(D.color.reticule.light)
		end
		love.graphics.polygon(
			"fill",
			nrll, nrt,
			nrlr, yhalf,
			nrll, nrb
		)
		if D.cmdmode ~= "cmd" then -- Only draw right reticule arrow if Cmd Mode is inactive
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

		for k, v in pairs(sels) do

			local l, t, w, h = unpack(v)

			love.graphics.setColor(D.color.selection.fill)
			love.graphics.rectangle("fill", l, t, w, h)

			love.graphics.setColor(D.color.selection.line)
			love.graphics.rectangle("line", l, t, w, h)

		end

	end,

	-- Draw the sequence-grid, centered on the active note and tick, and corresponding to the piano-roll
	drawSeqGrid = function(left, top, right, bot)

		-- All factors of the ticks-per-beat, for later column colorization
		local beatsize = D.tpq * 4
		local factors = getFactors(beatsize)

		-- Get the number of ticks in the active sequence, and global notes
		local ticks = D.seq[D.active].total
		local notes = D.bounds.np[2] - D.bounds.np[1]

		-- Get visible/invisible versions of the beat-color, for mixing
		local beatcolor = deepCopy(D.color.seq.beat)
		local invis = deepCopy(D.color.seq.beat)
		invis[4] = 0

		-- Grid-panel's full X and Y size
		local xfull = right - left
		local yfull = bot - top

		-- Reticule anchor coordinates
		local xanchor = xfull * D.size.anchor.x
		local yanchor = yfull * D.size.anchor.y

		-- Halved cell sizes, for later GUI positioning
		local xcellhalf = D.cellwidth / 2
		local ycellhalf = D.cellheight / 2

		-- Total number of grid-cells along both axes
		local xcells = math.ceil(xfull / D.cellwidth)
		local ycells = math.ceil(yfull / D.cellheight)

		-- Number of cells between anchor point and grid origin borders
		local xleftcells = math.ceil(xanchor / D.cellwidth)
		local ytopcells = math.ceil(yanchor / D.cellheight)

		-- Positions for the left and top grid borders, adjusted to anchor point
		local gridleft = (xanchor - (xleftcells * D.cellwidth)) - xcellhalf
		local gridtop = (yanchor - (ytopcells * D.cellheight)) - ycellhalf

		-- Leftmost/topmost unwrapped tick and note values, for grid rendering
		local lefttick = wrapNum(D.tp - xleftcells, 1, ticks)
		local topnote = wrapNum(D.np + ytopcells, D.bounds.np)

		-- Left/top boundaries of sequence's current, non-wrapped chunk
		local tboundary = xanchor - ((D.cellwidth * (D.tp - 1)) + xcellhalf)
		local nboundary = yanchor - ((D.cellheight * (D.bounds.np[2] - D.np)) + ycellhalf)

		-- Sequence's full width and height, in pixels
		local fullwidth = D.cellwidth * ticks
		local fullheight = D.cellheight * notes

		-- If note-cells are less than 1 wide, keep tick-columns from vanishing
		local colwidth = math.max(1, D.cellwidth)

		-- All boundaries for wrapping the sequence's display
		local xranges = getTileAxisBounds(0, xfull, tboundary, fullwidth)
		local yranges = getTileAxisBounds(0, yfull, nboundary, fullheight)

		-- Positioning for beat-triangles
		local trifontheight = D.font.beat.raster:getHeight()
		local trifonttop = yfull - (trifontheight + 1)
		local tritop = yfull - (D.size.triangle.breadth / 2)

		-- Initialize the local tables that will be populated
		local tintcolumns, drawnotes, drawsels, triangles = {}, {}, {}, {}

		-- Render the seq-window's background
		love.graphics.setColor(D.color.seq.light)
		love.graphics.rectangle("fill", left, top, xfull, yfull)

		-- Render the seq-window's background-image
		drawBoundedImage(left, top, xfull, yfull, D.img.grid)

		-- If Cmd Mode isn't active, draw highlighted rows
		if D.cmdmode ~= "cmd" then

			-- Set color for rendering darkened rows
			love.graphics.setColor(D.color.seq.dark)

			-- Find and render darkened rows
			for y = 0, ycells + 1 do

				-- Get row's Y-center and Y-top
				local ytop = gridtop + (D.cellheight * y)

				-- Get the row's corresponding note, and the note's scale position
				local note = wrapNum(topnote - y, D.bounds.np)
				local notetype = D.pianometa[wrapNum(note + 1, 1, 12)][1]

				-- On black-key rows, render dark overlays
				if notetype == 0 then
					love.graphics.rectangle("fill", left, ytop, xfull, D.cellheight)
				end

				-- Highlight the active note-row
				if note == D.np then
					love.graphics.setColor(D.color.seq.active)
					love.graphics.rectangle("fill", left, ytop, xfull, D.cellheight)
					love.graphics.setColor(D.color.seq.dark)
				end

			end

		end

		-- Find and render tick-columns
		for x = 0, xcells do

			local xleft = gridleft + (D.cellwidth * x)

			-- Get the row's corresponding tick
			local tick = wrapNum(lefttick + x, 1, ticks)

			-- If factor-column, table for later rendering
			if ((tick - 1) % (D.tpq * 4)) == 0 then
				local color = mixColors(beatcolor, invis, 0.1)
				table.insert(tintcolumns, {tick, left + xleft, top, colwidth, yfull, color})
			elseif ((tick - 1) % D.factors[D.fp]) == 0 then
				local color = mixColors(beatcolor, invis, 0.5)
				table.insert(tintcolumns, {tick, left + xleft, top, colwidth, yfull, color})
			end

			-- If active column, table activity-color for later rendering
			if tick == D.tp then
				local color = D.color.seq.active
				table.insert(tintcolumns, {tick, left + xleft, top, colwidth, yfull, color})
			end

			-- If this column is on a beat, add a triangle to the beat-triangle-table
			if ((tick - 1) % beatsize) == 0 then
				local beat = ((tick - 1) / beatsize) + 1
				local trileft = left + gridleft + xcellhalf + (x * D.cellwidth)
				table.insert(triangles, {beat, trileft})
			end

		end

		-- Get render-note data from all visible sequences
		for snum, s in pairs(D.seq) do

			local render = false

			-- Assign render type based on notedraw and shadow activity
			if D.drawnotes then
				if snum == D.active then
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
			if snum ~= D.active then
				if s.total ~= ticks then
					tempxr = getTileAxisBounds(0, xfull, tboundary, D.cellwidth * s.total)
				end
			end

			-- If the sequence is to be rendered...
			if render then

				-- If Cmd Mode is active, use only one vertical render-range
				if D.cmdmode == "cmd" then
					yranges = {{a = -math.huge, b = yanchor - ycellhalf, o = 0}}
				end

				-- Add visible notes to the drawnotes table
				drawnotes = tableCombine(
					drawnotes,
					makeNoteRenderTable(
						render,
						snum, getContents(s.tick, {pairs, 'note', pairs, pairs}, true),
						left, top, xfull, yfull,
						tempxr, yranges
					)
				)
				drawnotes = tableCombine(
					drawnotes,
					makeNoteRenderTable(
						render,
						snum, getContents(s.tick, {pairs, 'cmd', pairs}, true),
						left, top, xfull, yfull,
						tempxr, yranges
					)
				)
			end

		end

		-- If there is a selection range, find and store its coordinates
		if D.sel.l then

			local selleft = ((D.sel.l - 1) * D.cellwidth)
			local seltop = (D.bounds.np[2] - D.sel.t) * D.cellheight

			local selwidth = D.cellwidth * ((D.sel.r - D.sel.l) + 1)
			local selheight = D.cellheight * ((D.sel.t - D.sel.b) + 1)

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
				local t = top + yr.a + seltop + (D.cellheight * yr.o)

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
