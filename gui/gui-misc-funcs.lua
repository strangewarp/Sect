
return {
	
	-- Draw the GUI elements onto the canvas
	drawGUI = function(width, height)

		canvas:clear()

		love.graphics.setCanvas(canvas)

		drawBackground()

		drawSidebar()

		drawMetaSeqPanel()

		-- If not in Cmd Mode, draw the vertical piano-roll
		if D.cmdmode ~= "cmd" then
			drawPianoRoll()
		end

		drawTrackPanel()

		love.graphics.setCanvas()

	end,

	-- Build the entire GUI
	buildGUI = function(width, height)

		buildSidebar()

		buildMetaSeqPanel()

		-- If not in Cmd Mode, build the vertical piano-roll
		if D.cmdmode ~= "cmd" then
			buildPianoRoll()
		end

		buildTrackPanel()

		--[[
		-- Draw a line that compensates for a dangling border on the piano-roll,
		-- in order to keep any frame-lines from changing when toggled into Cmd Mode.
		love.graphics.setColor(D.color.piano.border)
		love.graphics.setLineWidth(2)
		love.graphics.line(
			D.size.sidebar.width, 0,
			D.size.sidebar.width, height
		)
		love.graphics.setLineWidth(1)
		]]

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
			--buildSeqNotes()
		end
	end,

	-- Draw either the saveload-panel or the seq-panel, depending on the D.cmdmode flag.
	drawMetaSeqPanel = function()
		if D.cmdmode == "saveload" then
			drawSaveLoadPanel()
		else
			drawSeqGrid()
			--drawSeqNotes()
		end
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
