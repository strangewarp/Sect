
return {

	-- Draw the rows and columns of the active sequence-grid	
	drawSeqGrid = function()

		local left = D.size.sidebar.width
		local top = 0
		local width = D.width - D.size.sidebar.width
		local height = D.height - D.size.track.height
		local bot = top + height

		-- Draw the seq-panel's background
		love.graphics.setColor(D.color.seq.light)
		love.graphics.rectangle("fill", left, top, width, height)

		-- Render the seq-window's background-image
		drawBoundedImage(left, top, width, height, D.img.grid)

		-- If Cmd Mode isn't active, draw highlighted rows
		if D.cmdmode ~= "cmd" then

			-- Draw all tinted rows
			for _, v in pairs(D.gui.seq.row) do
				local color, rl, rt, rw = unpack(v)
				love.graphics.setColor(color)
				love.graphics.rectangle("fill", rl, rt, rw, D.cellheight)
			end

			-- Draw all tinted columns
			for _, v in pairs(D.gui.seq.col) do
				local color, cl, ct, cw, ch = unpack(v)
				love.graphics.setColor(color)
				love.graphics.rectangle("fill", cl, ct, cw, ch)
			end

		end

		love.graphics.setFont(D.font.beat.raster)

		-- Draw all beat-triangles
		local breadth = D.size.triangle.breadth
		local bhalf = breadth / 2
		local bhalfout = bhalf + 1
		for _, v in ipairs(D.gui.seq.tri) do
			local beat, tmiddle, tt, trifonttop = unpack(v)
			love.graphics.setColor(D.color.triangle.fill)
			love.graphics.polygon("fill", tmiddle - bhalfout, bot, tmiddle, tt, tmiddle + bhalfout, bot)
			love.graphics.setColor(D.color.triangle.line)
			love.graphics.line(tmiddle - bhalfout, bot + 1, tmiddle, tt, tmiddle + bhalfout, bot + 1)
			love.graphics.setColor(D.color.triangle.text)
			love.graphics.printf(beat, tmiddle - bhalf, trifonttop, breadth, "center")
		end

	end,

	-- Build the rows and columns of the active sequence-grid
	buildSeqGrid = function()

		-- Clear old GUI elements
		D.gui.seq.col = {}
		D.gui.seq.row = {}
		D.gui.seq.tri = {}

		-- If no sequences are loaded, then abort function
		if not D.active then
			return nil
		end

		local left = D.size.sidebar.width
		local top = 0

		-- Get ticks-per-beat
		local beatsize = D.tpq * 4

		-- Get the number of ticks in the active sequence, and global notes
		local ticks = D.seq[D.active].total
		local notes = D.bounds.np[2] - D.bounds.np[1]

		-- Grid-panel's full X and Y size
		local xfull = D.width - left
		local yfull = D.height - D.size.track.height

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

		-- If note-cells are less than 1 wide, keep tick-columns from vanishing
		local colwidth = math.max(1, D.cellwidth)

		-- Positioning for beat-triangles
		local trifonttop = yfull - (D.font.beat.raster:getHeight() + 1)
		local tritop = yfull - (D.size.triangle.breadth / 2)

		-- If Cmd Mode isn't active, build highlighted rows
		if D.cmdmode ~= "cmd" then

			-- Find and generate darkened rows
			for y = 0, ycells + 1 do

				-- Get row's Y-center and Y-top
				local ytop = gridtop + (D.cellheight * y)

				-- Get the row's corresponding note, and the note's scale position
				local note = wrapNum(topnote - y, D.bounds.np)
				local notetype = D.pianometa[wrapNum(note + 1, 1, 12)][1]

				if notetype == 0 then -- On black-key rows, tab dark overlays for later rendering
					local outrow = {D.color.seq.dark, left, ytop, xfull}
					table.insert(D.gui.seq.row, outrow)
				end
				if note == D.np then -- Highlight the active note-row, overlaid atop a dark row if necessary
					local outrow = {D.color.seq.active, left, ytop, xfull}
					table.insert(D.gui.seq.row, outrow)
				end

			end

		end

		-- Find and generate tick-columns
		for x = 0, xcells do

			local xleft = gridleft + (D.cellwidth * x)

			-- Get the row's corresponding tick
			local tick = wrapNum(lefttick + x, 1, ticks)

			local color = D.color.seq.active
			local render = false

			-- If not active column, and factor column, then table blended color for later rendering
			if tick ~= D.tp then
				if ((tick - 1) % (D.tpq * 4)) == 0 then
					color = D.color.seq.beat_gradient[0]
					render = true
				elseif ((tick - 1) % D.factors[D.fp]) == 0 then
					color = D.color.seq.beat_gradient[roundNum(15 * (1 / D.factors[D.fp]), 0)]
					render = true
				end
			else -- Else, if active column, table active color for later rendering
				render = true
			end

			-- Tab color-column for later rendering
			if render then
				local outcol = {color, left + xleft, top, colwidth, yfull}
				table.insert(D.gui.seq.col, outcol)
			end

			-- If this column is on a beat, add a triangle to the beat-triangle-table
			if ((tick - 1) % beatsize) == 0 then
				local beat = ((tick - 1) / beatsize) + 1
				local trimiddle = left + gridleft + xcellhalf + (x * D.cellwidth)
				local tri = {beat, trimiddle, tritop, trifonttop}
				table.insert(D.gui.seq.tri, tri)
			end

		end

	end,

	dummyFunc = function() -- TODO: REMOVE THIS

		-- Left/top boundaries of sequence's current, non-wrapped chunk
		local tboundary = xanchor - ((D.cellwidth * (D.tp - 1)) + xcellhalf)
		local nboundary = yanchor - ((D.cellheight * (D.bounds.np[2] - D.np)) + ycellhalf)

		-- Sequence's full width and height, in pixels
		local fullwidth = D.cellwidth * ticks
		local fullheight = D.cellheight * notes

		-- All boundaries for wrapping the sequence's display
		local xranges = getTileAxisBounds(0, xfull, tboundary, fullwidth)
		local yranges = getTileAxisBounds(0, yfull, nboundary, fullheight)

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

}
