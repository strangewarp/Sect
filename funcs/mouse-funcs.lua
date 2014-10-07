
return {

	-- Check whether to enlarge the boundaries ofthe mouse's dragged-range
	checkMouseDrag = function(left, top, width, height, x, y)

		-- If no sequences exist, abort function
		if not data.active then
			return nil
		end

		-- If the dragging-cursor is outside of frame, abort function
		if not collisionCheck(0, 0, width, height, x, y, 1, 1) then
			return nil
		end

		-- Get panel-position information
		local xfull = width - left
		local yfull = height - top

		-- Get anchor-position information
		local xanchor = xfull * data.size.anchor.x
		local yanchor = yfull * data.size.anchor.y

		-- Get the cursor's tick and note coordinates
		local newtick, newnote = getCursorCell(xanchor, yanchor, x, y)

		-- If dragx and dragy are empty, set them to the current position
		data.dragx = data.dragx or {newtick, newtick}
		data.dragy = data.dragy or {newnote, newnote}

		-- Keep old values for comparison
		local oldtick = data.dragx[2]
		local oldnote = data.dragy[2]

		-- Set the target dragx and dragy based on cursor position
		data.dragx[2] = newtick
		data.dragy[2] = newnote

		-- Enlarge the select-area according to new dragx,dragy ranges
		if (oldtick ~= data.dragx[2])
		or (oldnote ~= data.dragy[2])
		then
			toggleSelect("top", data.dragx[1], data.dragy[1])
			toggleSelect("bottom", data.dragx[2], data.dragy[2])
		end

	end,

	-- Get the tick-column and note-row that the cursor currently occupies
	getCursorCell = function(xanchor, yanchor, x, y)

		-- Get mouse-position offsets
		local xoffset = roundNum((x - xanchor) / data.cellwidth, 0)
		local yoffset = roundNum((yanchor - y) / data.cellheight, 0)

		-- Get new tick and note positions
		local newtick = wrapNum(data.tp + xoffset, 1, #data.seq[data.active].tick)
		local newnote = wrapNum(data.np + yoffset, data.bounds.np)

		return newtick, newnote

	end,

	-- Change the cursor-image, and selection, based on mouse-click state	
	mouseCursorChange = function(button, down)

		-- If the mouse-click is a downstroke...
		if down then

			-- Set the cursor to one of the two click-type images
			if button == 'l' then
				love.mouse.setCursor(data.cursor.leftclick.c)
				data.dragging = true
			elseif button == 'r' then
				love.mouse.setCursor(data.cursor.rightclick.c)
			end

		else -- Else, if the mouse-click is an upstroke...

			-- If the mouse was dragged, reset the drag-trackers, and clear selection
			if data.dragging then
				data.dragging = false
				data.dragx = false
				data.dragy = false
				toggleSelect("clear")
			end

			-- Set the cursor to its default image
			love.mouse.setCursor(data.cursor.default.c)

		end

	end,

	-- Pick out the location of the mouse on-screen, and react to it
	mousePick = function(x, y, width, height, button)

		local left = data.size.sidebar.width
		local top = 0
		local right = left + width
		local middle = height - data.size.botbar.height

		if collisionCheck(x, y, 0, 0, left, top, right, middle) then
			reactToGridClick(left, top, width, middle, x - left, y - top, button)
		elseif collisionCheck(x, y, 0, 0, left, middle, right, height) then
			reactToTrackClick(left, middle, width - left, height - middle, x - left, y - middle)
		end

	end,

	-- React to a mouse-click on the sequence-grid
	reactToGridClick = function(left, top, width, height, x, y, button)

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

		-- Get total number of ticks
		local ticks = #data.seq[data.active].tick

		-- Get the cursor's tick and note coordinates
		local newtick, newnote = getCursorCell(xanchor, yanchor, x, y)

		-- Figure out whether the mouse-position overlaps with a note
		local closest = false
		local modtick = newtick
		for k, v in pairs(data.seq[data.active].tick) do
			for kk, vv in pairs(v) do

				-- Get the note's pitch or pitch-equivalent
				local pitch = vv.note[data.acceptmidi[vv.note[1]][1]]

				-- If the pitch matches the new-note-position...
				if (newnote == pitch) then

					local low = vv.tick
					local high = low

					-- If the note is a note-note, get and wrap its high-point
					if vv.note[1] == 'note' then
						high = vv.tick + vv.note[3] - 1
						if high > ticks then
							high = wrapNum(high + 1, 1, ticks)
						end
					end

					-- If the note wrapped around, adjust its virtual bounds
					if low > high then
						if newtick < high then
							low = low - ticks
						else
							high = high + ticks
						end
					end

					-- If the note contains the clicked tick,
					-- and starts later than other matching candidates,
					-- set modtick to that note's first tick.
					if rangeCheck(newtick, low, high) then
						if (not closest) or (low > closest) then
							closest = low
							modtick = vv.tick
						end
					end

				end

			end
		end

		-- If the right button was clicked...
		if button == 'r' then

			-- Set tick and note pointers to new positions
			data.tp = modtick
			data.np = newnote

			-- Set mouse-position to the anchor point
			if data.mousetocenter then
				love.mouse.setPosition(left + xanchor, top + yanchor)
			end

		else -- Else, if the left button was clicked...

			-- If a note overlapped the mouse-click...
			if closest then

				-- Clear any selection-window that might be active
				toggleSelect("clear")

				-- If shift isn't being held, clear the select-memory
				if not entryExists(data.keys, "shift") then
					clearSelectMemory()
				end

				-- Select the note at the click location, and clear the select-window.
				toggleSelect("top", modtick, newnote)
				toggleSelect("clear")

			else -- If no note was clicked, and shift isn't held, clear select-memory

				if not entryExists(data.keys, "shift") then
					toggleSelect("clear")
					clearSelectMemory()
				end

			end

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

		-- Get box-offset and mouse-hit information
		local xoffset = math.ceil(x / (boxwidth + 1))
		local yoffset = math.ceil(y / (boxheight + 1))
		local xhit = (x % (boxwidth + 1)) and true
		local yhit = (y % (boxheight + 1)) and true

		-- Get new sequence number
		local newseq = xoffset + (coltotal * (yoffset - 1))

		-- If sequence exists, tab to it, and sanitize data structures
		if xhit and yhit then
			if newseq <= seqs then
				data.active = newseq
				sanitizeDataStructures()
			end
		end

	end,

}
