
return {

	-- Draw a visual confirmation that the file was saved
	drawSavePopup = function()

		-- If the popup isn't flagged for drawing, abort function
		if not D.savepopup then
			return nil
		end

		local pl = D.size.save.margin_left
		local pt = D.size.save.margin_top

		local pw, lines = D.font.save.raster:getWrap(D.savemsg, D.size.save.width - 1)
		local ph = D.font.save.raster:getHeight() * lines

		love.graphics.setColor(D.color.save.background_gradient[roundNum(15 * (D.savedegrade / 90), 0)])
		love.graphics.rectangle("fill", pl, pt, pw + 2, ph)

		love.graphics.setColor(D.color.save.border)
		love.graphics.rectangle("line", pl, pt, pw + 2, ph)

		love.graphics.setFont(D.font.save.raster)

		love.graphics.setColor(D.color.save.text_shadow)
		love.graphics.printf(D.savemsg, pl + 2, pt + 2, D.size.save.width - 1, "left")

		love.graphics.setColor(D.color.save.text)
		love.graphics.printf(D.savemsg, pl + 1, pt + 1, D.size.save.width - 1, "left")

	end,

	-- If the save-popup is active, gradually degrade its activity
	degradeSavePopup = function()
		if D.savepopup then
			D.savedegrade = D.savedegrade - 1
			if D.savedegrade <= 0 then
				D.savepopup = false
				D.savemsg = ""
				drawGUI() -- Redraw the GUI elements again, to vanish the save-popup
			end
		end
	end,

	-- Execute a queued data-loading command, and draw the loading-screen
	executeLoadingFuncAndDraw = function(width, height)

		-- Get the current loading-command data
		local cmd, text = unpack(D.loadcmds[D.loadnum])

		-- Clear the global canvas
		canvas:clear()
		love.graphics.setCanvas(canvas)

		-- Switch to the loading-screen font
		love.graphics.setFont(D.font.loading.raster)

		-- Append the new text-line to the loading-screen text
		D.loadtext = D.loadtext .. "\r\n" .. text

		-- Draw background
		love.graphics.setColor(D.color.loading.background)
		love.graphics.rectangle("fill", 0, 0, width, height)

		-- Draw background-image
		drawBoundedImage(0, 0, width, height, D.img.loading)

		-- Draw loading text-shadows
		love.graphics.setColor(D.color.loading.text_shadow)
		love.graphics.printf(D.loadtext, 51, 51, width - 99, "left")

		-- Draw loading text
		love.graphics.setColor(D.color.loading.text)
		love.graphics.printf(D.loadtext, 50, 50, width - 100, "left")

		-- Draw the canvas to screen
		love.graphics.setCanvas()
		love.graphics.draw(canvas, 0, 0)

		-- Execute the loading-command
		executeFunction(unpack(cmd))

		-- Increment the loading-command pointer
		D.loadnum = D.loadnum + 1

		-- If all loading-commands are finished, set the loading-flag to false,
		-- build the new GUI elements, and draw them to canvas.
		if D.loadnum > #D.loadcmds then
			D.loading = false
			buildGUI()
			drawGUI()
		end

	end,

	-- Pre-render all cursors into Cursor objects
	preloadCursors = function()
		for k, v in pairs(D.cursor) do
			D.cursor[k].c = love.mouse.newCursor(v.file, v.x, v.y)
		end
	end,

	-- Preload all GUI-theme fonts
	preloadFonts = function()
		for k, v in pairs(D.font) do
			D.font[k].raster = love.graphics.newFont(v.file, v.height)
		end
	end,

	-- Preload all GUI-theme images
	preloadImages = function()
		for k, v in pairs(D.img) do
			if v.file then
				D.img[k].raster = love.graphics.newImage(v.file)
				D.img[k].width = D.img[k].raster:getWidth()
				D.img[k].height = D.img[k].raster:getHeight()
			end
		end
	end,

	-- Preload all liminal combinations of GUI gradient-colors
	preloadGradients = function()
		for k, v in pairs(D.gradients) do
			local ctab, cold, hot, name = unpack(v)
			local c1, c2 = D.color[ctab][cold], D.color[ctab][hot]
			D.color[ctab][name] = D.color[ctab][name] or {}
			for i = 0, 15 do
				D.color[ctab][name][i] = mixColors(c1, c2, i / 15)
			end
		end
	end,

}
