
return {
	
	-- Draw the GUI elements onto the canvas
	drawGUI = function(width, height)

		canvas:clear()

		love.graphics.setCanvas(canvas)

		drawBackground()

		drawMetaSeqPanel()

		drawSidebar()

		-- If not in Cmd Mode, draw the vertical piano-roll
		if D.cmdmode ~= "cmd" then
			drawPianoRoll()
		end

		drawTrackPanel()

		love.graphics.setCanvas()

	end,

	-- Build the entire GUI
	buildGUI = function(width, height)

		buildConstants()

		buildSidebar()

		buildMetaSeqPanel()

		-- If not in Cmd Mode, build the vertical piano-roll
		if D.cmdmode ~= "cmd" then
			buildPianoRoll()
		end

		buildTrackPanel()

	end,

	-- Build the window's background
	drawBackground = function()
		love.graphics.setColor(D.color.window.dark)
		love.graphics.rectangle("fill", 0, 0, D.width, D.height)
	end,

	-- Build either the saveload-panel or the seq-panel, depending on the D.cmdmode flag.
	buildMetaSeqPanel = function()
		if D.cmdmode == "saveload" then
			buildSaveLoadPanel()
		else
			buildSeqGrid()
			buildSelectionTable()
			buildReticules()
		end
	end,

	-- Draw either the saveload-panel or the seq-panel, depending on the D.cmdmode flag.
	drawMetaSeqPanel = function()
		if D.cmdmode == "saveload" then
			drawSaveLoadPanel()
		else
			drawSeqGrid()
			drawSelectionTable()
			drawReticules()
		end
	end,

	-- Generate the constants used by the seq-panel-building functions
	buildConstants = function()

		-- If there isno active sequence, abort function
		if not D.active then
			return nil
		end

		-- Get the number of ticks in the active sequence, and global notes
		D.c.ticks = D.seq[D.active].total
		D.c.notes = D.bounds.np[2] - D.bounds.np[1]

		-- Seq-panel boundaries
		D.c.sqleft = D.size.sidebar.width
		D.c.sqtop = 0
		D.c.sqwidth = D.width - D.c.sqleft
		D.c.sqheight = (D.height - D.c.sqtop) - D.size.track.height

		-- Reticule anchor-points
		D.c.xanchor = D.c.sqwidth * D.size.anchor.x
		D.c.yanchor = D.c.sqheight * D.size.anchor.y

		-- Halved cell-sizes
		D.c.xcellhalf = D.cellwidth / 2
		D.c.ycellhalf = D.cellheight / 2

		-- Sequence's full width and height, in pixels
		D.c.fullwidth = D.cellwidth * D.c.ticks
		D.c.fullheight = D.cellheight * D.c.notes

		-- Left/top boundaries of sequence's current, non-wrapped chunk
		D.c.tboundary = D.c.xanchor - ((D.cellwidth * (D.tp - 1)) + D.c.xcellhalf)
		D.c.nboundary = D.c.yanchor - ((D.cellheight * (D.bounds.np[2] - D.np)) + D.c.ycellhalf)

		-- Tables of all boundaries for wrapping the sequence's display
		D.c.xwrap = getTileAxisBounds(0, D.c.sqwidth, D.c.tboundary, D.c.fullwidth)
		D.c.ywrap = getTileAxisBounds(0, D.c.sqheight, D.c.nboundary, D.c.fullheight)

	end,

	-- Draw an image in the specified area, aligned in a certain way
	drawBoundedImage = function(left, top, width, height, imgtab)

		-- If the raster doesn't exist, abort function
		if not imgtab.raster then
			return nil
		end

		local l = left
		local t = top

		if imgtab.xglue == "right" then
			l = left + (width - imgtab.width)
		elseif imgtab.xglue == "center" then
			l = left + ((width - imgtab.width) / 2)
		end

		if imgtab.yglue == "bottom" then
			t = top + (height - imgtab.height)
		elseif imgtab.yglue == "center" then
			t = top + ((height - imgtab.height) / 2)
		end

		love.graphics.setStencil(
			function()
				love.graphics.rectangle("fill", left, top, width, height)
			end
		)
		love.graphics.draw(imgtab.raster, l, t)
		love.graphics.setStencil(nil)

	end,

	-- Mix two colors, with the average biased in the given direction.
	-- Var "bias" must be in the range of 0.0 to 1.0.
	mixColors = function(c1, c2, bias)

		local outcolor = {}

		for hue, chroma in pairs(c1) do
			outcolor[hue] = (chroma * (1 - bias)) + (c2[hue] * bias)
		end

		return outcolor

	end,

}
