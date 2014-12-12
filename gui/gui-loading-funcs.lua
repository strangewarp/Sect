
return {

	-- Draw a visual confirmation that the file was saved
	drawSavePopup = function()

		-- If the popup isn't flagged for drawing, abort function
		if not data.savepopup then
			return nil
		end

		local pl = data.size.save.margin_left
		local pt = data.size.save.margin_top

		local pw, lines = data.font.save.raster:getWrap(data.savemsg, data.size.save.width - 1)
		local ph = data.font.save.raster:getHeight() * lines

		love.graphics.setColor(data.color.save.background_gradient[roundNum(31 * (data.savedegrade / 90), 0)])
		love.graphics.rectangle("fill", pl, pt, pw + 2, ph)

		love.graphics.setColor(data.color.save.border)
		love.graphics.rectangle("line", pl, pt, pw + 2, ph)

		love.graphics.setFont(data.font.save.raster)

		love.graphics.setColor(data.color.save.text_shadow)
		love.graphics.printf(data.savemsg, pl + 2, pt + 2, data.size.save.width - 1, "left")

		love.graphics.setColor(data.color.save.text)
		love.graphics.printf(data.savemsg, pl + 1, pt + 1, data.size.save.width - 1, "left")

	end,

	-- If the save-popup is active, gradually degrade its activity
	degradeSavePopup = function()
		if data.savepopup then
			data.savedegrade = data.savedegrade - 1
			if data.savedegrade <= 0 then
				data.savepopup = false
				data.savemsg = ""
				drawGUI() -- Redraw the GUI elements again, to vanish the save-popup
			end
		end
	end,

	-- Execute a queued data-loading command, and draw the loading-screen
	executeLoadingFuncAndDraw = function(width, height)

		-- Get the current loading-command data
		local cmd, text = unpack(data.loadcmds[data.loadnum])

		-- Clear the global canvas
		canvas:clear()
		love.graphics.setCanvas(canvas)

		-- Switch to the loading-screen font
		love.graphics.setFont(data.font.loading.raster)

		-- Append the new text-line to the loading-screen text
		data.loadtext = data.loadtext .. "\r\n" .. text

		-- Draw background
		love.graphics.setColor(data.color.loading.background)
		love.graphics.rectangle("fill", 0, 0, width, height)

		-- Draw background-image
		drawBoundedImage(0, 0, width, height, data.img.loading)

		-- Draw loading text-shadows
		love.graphics.setColor(data.color.loading.text_shadow)
		love.graphics.printf(data.loadtext, 51, 51, width - 99, "left")

		-- Draw loading text
		love.graphics.setColor(data.color.loading.text)
		love.graphics.printf(data.loadtext, 50, 50, width - 100, "left")

		-- Draw the canvas to screen
		love.graphics.setCanvas()
		love.graphics.draw(canvas, 0, 0)

		-- Execute the loading-command
		executeFunction(unpack(cmd))

		-- Increment the loading-command pointer
		data.loadnum = data.loadnum + 1

		-- If all loading-commands are finished, set the loading-flag to false,
		-- build the new GUI elements, and draw them to canvas.
		if data.loadnum > #data.loadcmds then
			data.loading = false
			buildGUI()
			drawGUI()
		end

	end,

	-- Pre-render all cursors into Cursor objects
	preloadCursors = function()
		for k, v in pairs(data.cursor) do
			data.cursor[k].c = love.mouse.newCursor(v.file, v.x, v.y)
		end
	end,

	-- Preload all GUI-theme fonts
	preloadFonts = function()
		for k, v in pairs(data.font) do
			data.font[k].raster = love.graphics.newFont(v.file, v.height)
		end
	end,

	-- Preload all GUI-theme images
	preloadImages = function()
		for k, v in pairs(data.img) do
			if v.file then
				data.img[k].raster = love.graphics.newImage(v.file)
				data.img[k].width = data.img[k].raster:getWidth()
				data.img[k].height = data.img[k].raster:getHeight()
			end
		end
	end,

	-- Preload all liminal combinations of GUI gradient-colors
	preloadGradients = function()
		for k, v in pairs(data.gradients) do
			local ctab, cold, hot, name = unpack(v)
			local c1, c2 = data.color[ctab][cold], data.color[ctab][hot]
			data.color[ctab][name] = data.color[ctab][name] or {}
			for i = 0, 15 do
				data.color[ctab][name][i] = mixColors(c1, c2, i / 15)
			end
		end
	end,

}
