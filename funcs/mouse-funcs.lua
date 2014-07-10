
return {
	
	-- Pick out the location of the mouse on-screen, and react to it
	mousePick = function(x, y, width, height)

		local left = data.size.sidebar.width + (data.pianowidth / 3)
		local right = left + width
		local middle = height - data.size.botbar.height

		if collisionCheck(x, y, 0, 0, left, 0, right, middle) then
			reactToGridClick(x - left, y, width, middle)
		elseif collisionCheck(x, y, 0, 0, left, middle, right, height) then
			reactToTrackClick(x - left, y - middle, width, height - middle)
		end

	end,

	-- React to a mouse-click on the sequence-grid
	reactToGridClick = function(x, y, width, height)

		-- If there's no active sequence, abort function
		if not data.active then
			return nil
		end

		-- Get panel-position information
		local left = data.size.sidebar.width
		local top = 0
		local xfull = width - left
		local yfull = height - top

		-- Get anchor-position information
		local xanchor = xfull * data.size.anchor.x
		local yanchor = yfull * data.size.anchor.y

		-- Get mouse-position offsets
		local xoffset = roundNum((x - xanchor) / data.cellwidth, 0)
		local yoffset = roundNum((yanchor - y) / data.cellheight, 0)

		print("DYE 1: " .. table.concat({left, xfull, xanchor, x, xoffset}, " ")) -- debugging
		print("DYE 2: " .. table.concat({top, yfull, yanchor, y, yoffset}, " ")) -- debugging

		data.tp = wrapNum(data.tp + xoffset, 1, #data.seq[data.active].tick)
		data.np = wrapNum(data.np + yoffset, data.bounds.np)

	end,

	-- React to a mouse-click on the track-bar
	reactToTrackClick = function(x, y, width, height)

		print("DYE 2") -- debugging

	end,

}
