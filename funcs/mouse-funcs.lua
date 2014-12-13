
return {

	-- Check whether to enlarge the boundaries ofthe mouse's dragged-range
	checkMouseDrag = function(left, top, width, height, x, y)

		-- If no sequences exist, abort function
		if not D.active then
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
		local xanchor = xfull * D.size.anchor.x
		local yanchor = yfull * D.size.anchor.y

		-- Get the cursor's tick and note coordinates
		local newtick, newnote = getCursorCell(xanchor, yanchor, x, y)

		-- If dragx and dragy are empty, set them to the current position
		D.dragx = D.dragx or {newtick, newtick}
		D.dragy = D.dragy or {newnote, newnote}

		-- Keep old values for comparison
		local oldtick = D.dragx[2]
		local oldnote = D.dragy[2]

		-- Set the target dragx and dragy based on cursor position
		D.dragx[2] = newtick
		D.dragy[2] = newnote

		-- Enlarge the select-area according to new dragx,dragy ranges
		if (oldtick ~= D.dragx[2])
		or (oldnote ~= D.dragy[2])
		then
			toggleSelect("top", D.dragx[1], D.dragy[1])
			toggleSelect("bottom", D.dragx[2], D.dragy[2])
		end

	end,

	-- Get the tick-column and note-row that the cursor currently occupies
	getCursorCell = function(xanchor, yanchor, x, y)

		-- Get mouse-position offsets
		local xoffset = roundNum((x - xanchor) / D.cellwidth, 0)
		local yoffset = roundNum((yanchor - y) / D.cellheight, 0)

		-- Get new tick and note positions
		local newtick = wrapNum(D.tp + xoffset, 1, D.seq[D.active].total)
		local newnote = wrapNum(D.np + yoffset, D.bounds.np)

		return newtick, newnote

	end,

	-- Change the cursor-image, and selection, based on mouse-click state	
	mouseCursorChange = function(button, down)

		-- If the mouse-click is a downstroke...
		if down then

			-- Set the cursor to one of the two click-type images
			if button == 'l' then
				love.mouse.setCursor(D.cursor.leftclick.c)
				D.dragging = true
			elseif button == 'r' then
				love.mouse.setCursor(D.cursor.rightclick.c)
			end

		else -- Else, if the mouse-click is an upstroke...

			-- If the mouse was dragged, reset the drag-trackers, and clear selection
			if D.dragging then
				D.dragging = false
				D.dragx = false
				D.dragy = false
				toggleSelect("clear")
			end

			-- Set the cursor to its default image
			love.mouse.setCursor(D.cursor.default.c)

		end

	end,

	-- Pick out the location of the mouse on-screen, and react to it
	mousePick = function(x, y, width, height, button)

		local left = D.size.sidebar.width
		local top = 0
		local right = left + width
		local middle = height - D.size.track.height

		if collisionCheck(x, y, 0, 0, left, top, right, middle) then
			reactToGridClick(left, top, width, middle, x - left, y - top, button)
		elseif collisionCheck(x, y, 0, 0, left, middle, right, height) then
			reactToTrackClick(left, middle, width - left, height - middle, x - left, y - middle)
		end

	end,

	-- React to a mouse-click on the sequence-grid
	reactToGridClick = function(left, top, width, height, x, y, button)

		-- If no sequences exist, abort function
		if not D.active then
			return nil
		end

		-- Get panel-position information
		local xfull = width - left
		local yfull = height - top

		-- Get anchor-position information
		local xanchor = xfull * D.size.anchor.x
		local yanchor = yfull * D.size.anchor.y

		-- Get total number of ticks
		local ticks = D.seq[D.active].total

		-- Get the cursor's tick and note coordinates
		local newtick, newnote = getCursorCell(xanchor, yanchor, x, y)

		local bestmatch = false

		-- Figure out whether the mouse-position overlaps with a note
		local ntab = getContents(D.seq[D.active].tick, {pairs, 'note', pairs, pairs})
		for _, n in pairs(ntab) do

			-- If the pitch matches the new-note-position...
			if newnote == n[5] then

				local low = n[2] + 1
				local high = n[2] + n[3]

				-- If the note contains the clicked tick, check it against other candidates
				if rangeCheck(newtick, low, high) then
					if bestmatch then
						if bestmatch[4] == D.chan then
							if n[4] == D.chan then
								if n[3] < bestmatch[3] then
									bestmatch = n
								end
							end
						else
							if n[4] == D.chan then
								bestmatch = n
							elseif n[4] < bestmatch[4] then
								bestmatch = n
							end
						end
					else
						bestmatch = n
					end
				end

			end

		end

		-- Modify the target tick and note, based on the presence or absence of a clicked note
		local modtick = (bestmatch and (bestmatch[2] + 1)) or newtick
		local modnote = (bestmatch and bestmatch[5]) or newnote

		-- If the right button was clicked...
		if button == 'r' then

			-- Set tick and note pointers to new positions
			D.tp = modtick
			D.np = modnote

			-- Set mouse-position to the anchor point
			if D.mousetocenter then
				love.mouse.setPosition(left + xanchor, top + yanchor)
			end

		else -- Else, if the left button was clicked...

			-- Check whether the Shift key is being held down
			local shiftheld = entryExists(D.keys, "shift")

			-- If a note overlapped the mouse-click...
			if bestmatch then

				-- Clear any selection-window that might be active
				toggleSelect("clear")

				-- Check whether the clicked note is already within the select-table
				local exists = getIndex(D.seldat, {modtick, bestmatch[4], modnote})

				if exists then -- If the selection-index exists...

					if shiftheld then -- If shift is held...

						-- Unset the individual note's index
						copyUnsetCascade('seldat', bestmatch)

					else -- If shift isn't being held...

						-- Get currently-existing select items
						local selitems = getContents(D.seldat, {pairs, pairs, pairs})

						-- Clear the select memory
						toggleSelect("clear")
						clearSelectMemory()

						-- If the matching note wasn't the only active select note,
						-- then build a select-index for it.
						if #selitems ~= 1 then
							buildTable(D.seldat, {modtick, bestmatch[4], modnote}, bestmatch)
						end

					end

				else -- If the selection-index doesn't exist...

					-- If shift isn't held, clear the old select data
					if not shiftheld then
						toggleSelect("clear")
						clearSelectMemory()
					end

					-- Build the note's selection-index
					buildTable(D.seldat, {modtick, bestmatch[4], modnote}, bestmatch)

				end

			else -- If no note was clicked...

				-- If shift isn't held, clear select-memory
				if not shiftheld then
					toggleSelect("clear")
					clearSelectMemory()
				end

			end

		end

	end,

	-- React to a mouse-click on the track-bar
	reactToTrackClick = function(left, top, width, height, x, y)

		-- If no sequences exist, abort function
		if not D.active then
			return nil
		end

		local seqs = #D.seq

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
				D.active = newseq
				sanitizeDataStructures()
			end
		end

	end,

}
