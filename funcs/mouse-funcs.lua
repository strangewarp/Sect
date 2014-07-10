
return {
	
	-- Pick out the location of the mouse on-screen, and react to it
	mousePick = function(x, y, width, height)

		local left = data.size.sidebar.width + (data.pianowidth / 2)
		local top = 0
		local right = left + width
		local middle = height - data.size.botbar.height

		if collisionCheck(x, y, 0, 0, left, 0, right, middle) then
			reactToGridClick(left, top, width, middle, x - left, y)
		elseif collisionCheck(x, y, 0, 0, left, middle, right, height) then
			reactToTrackClick(left, middle, width, height - middle, x - left, y - middle)
		end

	end,

	-- React to a mouse-click on the sequence-grid
	reactToGridClick = function(left, top, width, height, x, y)

		-- If there's no active sequence, abort function
		if not data.active then
			return nil
		end

		-- Get panel-position information
		local xfull = width - left
		local yfull = height - top

		-- Get anchor-position information
		local xanchor = xfull * data.size.anchor.x
		local yanchor = yfull * data.size.anchor.y

		-- Get mouse-position offsets
		local xoffset = roundNum((x - xanchor) / data.cellwidth, 0)
		local yoffset = roundNum((yanchor - y) / data.cellheight, 0)

		-- Set tick and note pointers to new positions
		data.tp = wrapNum(data.tp + xoffset, 1, #data.seq[data.active].tick)
		data.np = wrapNum(data.np + yoffset, data.bounds.np)

	end,

	-- React to a mouse-click on the track-bar
	reactToTrackClick = function(left, top, width, height, x, y)

		print("DYE 2") -- debugging

	end,

}
