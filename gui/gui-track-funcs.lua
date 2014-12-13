
return {

	-- Draw the GUI elements for the track-panel
	drawTrackPanel = function()

		love.graphics.setFont(D.font.track.raster)

		local left = D.size.sidebar.width
		local top = D.height - D.size.track.height
		local width = D.width - left
		local height = D.size.track.height

		-- Draw panel's background
		love.graphics.setColor(D.color.window.dark)
		love.graphics.rectangle("fill", left, top, width, height)

		-- Draw background image, if applicable
		drawBoundedImage(left, top, width, height, D.img.track)

		-- For every stored cell in the track-panel-GUI table...
		for k, v in ipairs(D.gui.track.cell) do

			local bgcolor, rl, rt, rw, rh, text, tl, tt = unpack(v)

			-- Draw the summary text
			love.graphics.setColor(bgcolor)
			love.graphics.rectangle("fill", rl, rt, rw, rh)

			-- Draw the cell's text, if any exists
			if text then
				love.graphics.setColor(D.color.summary.text_shadow)
				love.graphics.print(text, tl + 1, tt + 1)
				love.graphics.setColor(D.color.summary.text)
				love.graphics.print(text, tl, tt)
			end

		end

		-- Draw the active-sequence reticule,if a sequence is active
		if D.active then
			love.graphics.setColor(D.color.summary.pointer)
			love.graphics.polygon("fill", D.gui.track.cursor)
			love.graphics.setColor(D.color.summary.pointer_border)
			love.graphics.polygon("line", D.gui.track.cursor)
		end

	end,
	
	-- Build the GUI elements for the track-panel
	buildTrackPanel = function(left, top, width, height)

		D.gui.track.cell = {} -- Clear old track-cells

		local left = D.size.sidebar.width
		local top = D.height - D.size.track.height
		local width = D.width - left
		local height = D.size.track.height

		local fontheight = D.font.track.raster:getHeight()

		local seqs = #D.seq

		local boxwidth = (height / 3) - 1
		local coltotal = math.floor(width / (boxwidth + 1))
		local rowtotal = 0
		for i = 1, seqs, coltotal do
			rowtotal = rowtotal + 1
		end
		local boxheight = math.min(boxwidth, (height / rowtotal) - 1)

		-- Get the alternating columns to print text onto, in case many sequences are loaded
		local displaynum = 4
		while (coltotal % displaynum) == 0 do
			displaynum = displaynum + 1
		end

		local row = 1
		local col = 1

		-- For every sequence...
		for i = 1, seqs do

			local text = false

			local boxleft = (boxwidth * (col - 1)) + (col - 1)
			local boxtop = (boxheight * (row - 1)) + (row - 1)

			local strength = 0
			local ticks = D.seq[i].total

			-- Increase color-strength for every note, weighted against ticks/duration
			local strcheck = getContents(D.seq[i].tick, {pairs, 'note', pairs, pairs})
			for _, v in pairs(strcheck) do
				if v[1] == 'note' then
					strength = strength + v[3]
				end
			end
			strength = math.min(ticks, strength) / ticks

			-- Assemble the track-cell, and set it aside for later rendering
			local itext = tostring(i)
			local fontwidth = D.font.track.raster:getWidth(itext)
			local textleft = left + boxleft + ((boxwidth - fontwidth) / 2)
			local texttop = top + boxtop + ((boxheight - fontheight) / 2)

			-- Build coordinates of the active-sequence reticule
			if i == D.active then

				local boxhalfx = boxwidth / 2
				local boxhalfy = boxheight / 2

				local rlx =	left + boxleft
				local rcx = left + boxleft + boxhalfx
				local rrx = left + boxleft + boxwidth
				local rty = top + boxtop
				local rcy = top + boxtop + boxhalfy
				local rby = top + boxtop + boxheight

				-- Save the active-track polygon position for later rendering
				D.gui.track.cursor = {
					rlx, rcy,
					rcx, rty,
					rrx, rcy,
					rcx, rby,
				}

			end

			-- Print a number on the sequence-bar, if space allows
			if (fontheight <= boxheight) or ((i % displaynum) == 0) then
				text = itext
			end

			-- Iterate through row and column positions
			if col == coltotal then
				col = 1
				row = row + 1
			else
				col = col + 1
			end

			-- Save all GUI data for this track-cell, for later rendering
			local cell = {
				D.color.summary.gradient[roundNum(strength * 15, 0)],
				left + boxleft,
				top + boxtop,
				boxwidth,
				boxheight,
				text,
				textleft,
				texttop,
			}
			table.insert(D.gui.track.cell, cell)

		end

	end,

}
