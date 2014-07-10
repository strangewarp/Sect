
return {
	
	-- Pick out the location of the mouse on-screen, and react to it
	mousePick = function(x, y, width, height)

		local left = data.size.sidebar.width
		local right = left + width
		local middle = height - data.size.botbar.height

		if collisionCheck(x, y, 0, 0, left, 0, right, middle) then
			reactToGridClick(x - left, y)
		elseif collisionCheck(x, y, 0, 0, left, middle, right, height) then
			reactToTrackClick(x - left, y - middle)
		end

	end,

	-- React to a mouse-click on the sequence-grid
	reactToGridClick = function(x, y)

		print("DYE 1") -- debugging

	end,

	-- React to a mouse-click on the track-bar
	reactToTrackClick = function(x, y)

		print("DYE 2") -- debugging

	end,

}
