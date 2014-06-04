
return {

	-- Execute a queued data-loading command, and draw the loading-screen
	executeLoadingFuncAndDraw = function(cnv, width, height)

		-- Get the current loading-command data
		local cmd, text = unpack(data.loadcmds[data.loadnum])

		-- Append the new text-line to the loading-screen text
		data.loadtext = data.loadtext .. "\r\n" .. text

		-- Draw background
		love.graphics.setColor(data.color.loading.background)
		love.graphics.rectangle("fill", 0, 0, width, height)

		-- Draw background-image
		love.graphics.draw(loadingbg, width - loadingbg:getWidth(), 0)

		-- Draw loading text-shadows
		love.graphics.setColor(data.color.loading.text_shadow)
		love.graphics.printf(data.loadtext, 51, 51, width - 99, "left")

		-- Draw loading text
		love.graphics.setColor(data.color.loading.text)
		love.graphics.printf(data.loadtext, 50, 50, width - 100, "left")

		-- Draw the canvas onto the screen
		love.graphics.draw(cnv, 0, 0)

		print(cmd[1]) -- DEBUGGING

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

}
