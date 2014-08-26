
return {

	-- Execute a queued data-loading command, and draw the loading-screen
	executeLoadingFuncAndDraw = function(width, height)

		-- Get the current loading-command data
		local cmd, text = unpack(data.loadcmds[data.loadnum])

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

		-- Execute the loading-command
		executeFunction(unpack(cmd))

		-- Increment the loading-command pointer
		data.loadnum = data.loadnum + 1

		-- If all loading-commands are finished, set the loading-flag to false
		if data.loadnum > #data.loadcmds then
			data.loading = false
			love.keyboard.setTextInput(true) -- Set keyboard-input to true
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

}
