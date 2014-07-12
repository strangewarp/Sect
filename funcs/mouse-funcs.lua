
return {
	
	-- Pick out the location of the mouse on-screen, and react to it
	mousePick = function(x, y, width, height)

		local left = data.size.sidebar.width
		local pianoleft = left + (data.pianowidth / 2)
		local top = 0
		local right = left + width
		local middle = height - data.size.botbar.height

		if collisionCheck(x, y, 0, 0, left, 0, right, middle) then
			reactToGridClick(pianoleft, top, width, middle, x - pianoleft, y)
		elseif collisionCheck(x, y, 0, 0, left, middle, right, height) then
			reactToTrackClick(left, middle, width - left, height - middle, x - left, y - middle)
		end

	end,

	-- React to a mouse-click on the sequence-grid
	reactToGridClick = function(left, top, width, height, x, y)

		-- If no sequences exist, abort function
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

		-- Get total number of ticks
		local ticks = #data.seq[data.active].tick

		-- Get new tick and note positions
		local newtick = wrapNum(data.tp + xoffset, 1, #data.seq[data.active].tick)
		local newnote = wrapNum(data.np + yoffset, data.bounds.np)

		local tightest = math.huge
		local modtick = newtick
		for k, v in pairs(data.seq[data.active].tick) do
			for kk, vv in pairs(v) do

				local pitch = vv.note[data.acceptmidi[vv.note[1]][1]]

				if (newnote == pitch) then

					local offset = 0
					local low = vv.tick + offset
					local high = low
					if vv.note[1] == 'note' then
						if (vv.tick + vv.note[3]) > ticks then
							offset = ticks - (vv.tick - 1)
						end
						high = vv.tick + vv.note[3] + offset
					end

					if rangeCheck(newtick + offset, low, high) then
						local size = high - low
						if size < tightest then
							tightest = size
							modtick = vv.tick
						end
					end

				end

			end
		end

		-- If mousemove is enabled...
		if data.mousemove then

			-- Set tick and note pointers to new positions
			data.tp = modtick
			data.np = newnote

			-- Set mouse-position to the anchor point
			love.mouse.setPosition(left + xanchor, top + yanchor)

		end

		-- If a note overlapped the mouse-click...
		if tightest ~= math.huge then

			-- Clear any selection-window that might be active
			toggleSelect("clear")

			-- If shift isn't being held, clear the select-memory
			if not entryExists(data.keys, "shift") then
				clearSelectMemory()
			end

			-- Select the note at the click location, and clear the select-window.
			toggleSelect("top", modtick, newnote)
			toggleSelect("clear")

		else -- If no note was clicked, clear the select-window and select-memory

			toggleSelect("clear")
			clearSelectMemory()

		end

	end,

	-- React to a mouse-click on the track-bar
	reactToTrackClick = function(left, top, width, height, x, y)

		-- If no sequences exist, abort function
		if not data.active then
			return nil
		end

		local seqs = #data.seq

		-- Get box-size information
		local boxwidth = (height / 3) - 1
		local coltotal = math.floor(width / (boxwidth + 1))
		local rowtotal = 0
		for i = 1, seqs, coltotal do
			rowtotal = rowtotal + 1
		end
		local boxheight = math.min(boxwidth, (height / rowtotal) - 1)

		-- Get panel-position information
		local xfull = width - left
		local yfull = height - top

		local xoffset = math.ceil(x / (boxwidth + 1))
		local yoffset = math.ceil(y / (boxheight + 1))
		local xhit = (x % (boxwidth + 1)) and true
		local yhit = (y % (boxheight + 1)) and true

		local newseq = xoffset + (coltotal * (yoffset - 1))

		if xhit and yhit then
			if newseq <= seqs then
				data.active = newseq
			end
		end

		print("box xy " .. table.concat({boxwidth, boxheight}, " ")) -- debugging
		print("x y " .. table.concat({x, y}, " ")) -- debugging
		print("offsets " .. table.concat({xoffset, yoffset}, " ")) -- debugging
		print("xhit yhit " .. table.concat({tostring(xhit), tostring(yhit)}, " ")) -- debugging
		print("coltotal " .. coltotal)
		print("newseq " .. newseq) -- debugging
		print("left x " .. left .. " " .. x)


	end,

}
