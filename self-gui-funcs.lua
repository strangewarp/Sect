return {

	-- Build a series of flat lines that summarize all currently-loaded sequences
	buildSummaryLines = function(data, left, top, width, height, lheight)

		-- If all lheights and margins are greater than height, reduce lheight
		if (((lheight + 1) * #data.seq) - 1) > height then
			lheight = (height - (#data.seq - 1)) / #data.seq
		end

		local lhalf = lheight / 2
		local poly = {0, 0, 0, 0, 0, 0}

		-- For every sequence...
		for i = 1, #data.seq do

			local loffset = (lheight * (i - 1)) + (i - 1)

			local strength = 0
			local ticks = #data.seq[i].tick
			local beats = ticks / data.tpq

			-- Increase color-strength for every note
			for k, v in pairs(data.seq[i].tick) do
				strength = strength + (#v / beats)
			end

			-- Mix empty and full colors, based on strength
			local scolor = mixColors(
				data.color.summary.empty,
				data.color.summary.full,
				strength
			)

			-- Draw the summary rectangle
			love.graphics.setColor(scolor)
			love.graphics.rectangle("fill", left, top + loffset, width, lheight)

			-- Store coordinates of the active-sequence reticule
			if i == data.active then

				local rlx = left + width - 19
				local rly = top + loffset + lhalf
				local rrx = left + width
				local rty = top + loffset + lhalf - 19
				local rby = top + loffset + lhalf + 19

				poly = {
					rlx, rly,
					rrx, rty,
					rrx, rby,
				}

			end

		end

		-- Draw the active-sequence reticule
		love.graphics.setColor(data.color.summary.pointer)
		love.graphics.polygon("fill", poly)
		love.graphics.setColor(data.color.summary.pointer_border)
		love.graphics.polygon("line", poly)

	end,

	-- Build the sidebar that contains all the sequence's metadata, and hotseat information
	buildSidebar = function(data, left, top, right, bot, width, height)

		local tleft, ttop, tright = left + 5, top + 10, right - 10
		local fontheight = fontsmall:getHeight()
		local outtab = {}

		-- Draw the pane's background
		love.graphics.setColor(data.color.window.mid)
		love.graphics.rectangle("fill", left, top, right, bot)

		-- Set the font and font-color
		love.graphics.setFont(fontsmall)
		love.graphics.setColor(data.color.font.mid)

		-- If no sequences are loaded, write a simple guidance statement,
		-- and skip displaying the sequence/pointer information.
		if data.active == false then

			outtab = {
				"no seqs loaded!",
				"",
				table.concat(data.cmds.LOAD_FILE, "-"),
				"opens a hotseat",
				"",
				table.concat(data.cmds.INSERT_SEQ, "-"),
				"creates a seq",
				"",
			}
			printMultilineText(outtab, tleft, ttop, tright, "left")
			ttop = ttop + (#outtab * fontheight) + roundNum(fontheight / 2, 0)

		else -- Display sequence/pointer information

			-- Gather and draw the metadata info
			local oticks = #data.seq[data.active].tick
			local obeats = tostring(roundNum(oticks / data.tpq, 2))
			local notelet = data.pianometa[wrapNum(data.np + 1, 1, 12)][2]
			local octave = math.floor(data.np / 12)
			obeats = ((obeats:sub(-3, -3) == ".") and ("~" .. obeats)) or obeats
			outtab = {
				"seq " .. data.active .. "/" .. #data.seq,
				"beats " .. obeats,
				"",
				"tick " .. data.tp .. "/" .. oticks,
				"note " .. data.np .. " (" .. notelet .. "-" .. octave .. ")",
				"",
				"bpm " .. data.bpm,
				"tpq " .. data.tpq,
				"",
				"chan " .. data.chan,
				"velo " .. data.velo,
				"duration " .. data.dur,
				"spacing " .. data.spacing,
				"",
				"recording: " .. ((data.recording and "on") or "off"),
				"notes: " .. ((data.drawnotes and "visible") or "hidden"),
				"",
			}
			printMultilineText(outtab, tleft, ttop, tright, "left")
			ttop = ttop + (#outtab * fontheight) + roundNum(fontheight / 2, 0)

		end

		-- Print out the hotseats, with the currently-active one highlighted
		outtab = {"hotseats"}
		local acheck = 1
		while acheck ~= data.activeseat do
			local text = acheck .. string.rep(".", 1 + string.len(#data.hotseats - (string.len(acheck) - 1))) .. data.hotseats[acheck]
			table.insert(outtab, text)
			--table.insert(outtab, acheck .. ". " .. data.hotseats[acheck])
			acheck = acheck + 1
		end
		love.graphics.setColor(data.color.font.mid)
		printMultilineText(outtab, tleft, ttop, tright, "left")
		ttop = ttop + (#outtab * fontheight)

		love.graphics.setColor(data.color.font.highlight)
		printMultilineText({acheck .. string.rep(".",  1 + string.len(#data.hotseats) - (string.len(acheck) - 1)) .. data.hotseats[acheck]}, tleft, ttop, tright, "left")
		acheck = acheck + 1
		ttop = ttop + fontheight

		outtab = {}
		while acheck <= #data.hotseats do
				local text = acheck .. string.rep(".",  1 + string.len(#data.hotseats) - (string.len(acheck) - 1)) .. data.hotseats[acheck]
				table.insert(outtab, text)
				--table.insert(outtab, acheck .. ". " .. data.hotseats[acheck])
			acheck = acheck + 1
		end
		table.insert(outtab, "")
		love.graphics.setColor(data.color.font.mid)
		printMultilineText(outtab, tleft, ttop, tright, "left")
		ttop = ttop + (#outtab * fontheight) + roundNum(fontheight / 2, 0)

		-- Draw the sequence-summary panel
		data:buildSummaryLines(left, ttop, right - left, bot - ttop, 15)

	end,

	-- Draw the contents of the sequence-frame
	buildSeqFrame = function(data, left, top, width, height)

		-- If no sequences are loaded, terminate the function
		if data.active == false then
			return nil
		end

		-- Piano-roll width (based on window size)
		local kwidth = roundNum(width / 10, 0)

		-- Piano-key height (based on zoom)
		local cellheight = (height / 12) / data.zoomy

		-- Sequence grid's left border position
		local seqleft = left + (kwidth / 2)

		-- Draw the sequence-grid
		drawSeqGrid(seqleft, top, width, height, cellheight)

		-- Draw the vertical piano-roll
		drawPianoRoll(left, kwidth, cellheight, width, height)

	end,

	buildGUI = function(data, cnv, width, height)

		buildBackground(width, height)
		data:buildSidebar(0, 2, 100, height - 4, width, height)
		data:buildSeqFrame(100, 0, width, height)

		-- Draw the canvas onto the screen
		love.graphics.draw(cnv, 0, 0)

	end,

}