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

	-- Draw the column of piano-keys in the sequence window
	drawPianoRoll = function(data, left, kwidth, cellheight, width, height)

		local whitedraw = {}
		local blackdraw = {}

		-- Get key heights, and half-key heights, and note-row heights
		local yflare = cellheight * 1.5
		local ymid = cellheight
		local khalf = cellheight / 2

		-- Get the center-point, on which the sequence grid (and by extension, the piano-roll) are fixed
		local ycenter = height / 1.7

		-- Add the active note, in center position, with highlighted color, to the relevant draw-table
		whitedraw, blackdraw = pianoNoteToDrawTables(whitedraw, blackdraw, data.np, left, ycenter, ymid, yflare, kwidth, true)

		-- Moving outwards from center, add piano-keys to the draw-tables, until fully passing the stencil border
		local upkey, downkey, uppos, downpos = data.np, data.np, ycenter, ycenter
		while uppos >= (0 - khalf) do

			-- Update position and pointer values
			upkey = wrapNum(upkey + 1, data.bounds.np)
			downkey = wrapNum(downkey - 1, data.bounds.np)
			uppos = uppos - cellheight
			downpos = downpos + cellheight

			-- Add the two outermost notes, with normal color, to the relevant draw-tables
			whitedraw, blackdraw = pianoNoteToDrawTables(whitedraw, blackdraw, upkey, left, uppos, ymid, yflare, kwidth, false)
			whitedraw, blackdraw = pianoNoteToDrawTables(whitedraw, blackdraw, downkey, left, downpos, ymid, yflare, kwidth, false)

		end

		-- Draw all tabled keys, in the proper visibility order
		drawTabledKeys(whitedraw, "white")
		drawTabledKeys(blackdraw, "black")

	end,

	-- Draw the sequence-grid, centered on the active note and tick, and corresponding to the piano-roll
	drawSeqGrid = function(data, left, top, right, bot, cellheight)

		-- All factors of the ticks-per-beat, for later column colorization
		local beatsize = data.tpq * 4
		local factors = getFactors(beatsize)

		-- Get the threshold for which sub-beat columns should be colorized
		local beatthresh = data.tpq / 2

		-- Get the number of ticks in the active sequence, and global notes
		local ticks = #data.seq[data.active].tick
		local notes = data.bounds.np[2] - data.bounds.np[1]

		-- Get visible/invisible versions of the beat-color, for mixing
		local beatcolor = deepCopy(data.color.seq.beat)
		local invis = deepCopy(data.color.seq.beat)
		invis[4] = 0

		-- Grid-panel's full X and Y size
		local xfull = right - left
		local yfull = bot - top

		-- Seq-grid-center coordinates
		local xhalf = xfull / 2
		local yhalf = yfull / 2

		-- Reticule anchor coordinates
		local xanchor = xfull / 3
		local yanchor = yfull / 1.7

		-- Tick-column width, based on zoom
		local cellwidth = (xhalf / data.tpq) / data.zoomx

		-- Halved cell sizes, for later GUI positioning
		local xcellhalf = cellwidth / 2
		local ycellhalf = cellheight / 2

		-- Total number of grid-cells along both axes
		local xcells = math.ceil(xfull / cellwidth)
		local ycells = math.ceil(yfull / cellheight)

		-- Number of cells between anchor point and grid origin borders
		local xleftcells = math.ceil(xanchor / cellwidth)
		local ytopcells = math.ceil(yanchor / cellheight)

		-- Positions for the left and top grid borders, adjusted to anchor point
		local gridleft = (xanchor - (xleftcells * cellwidth)) - xcellhalf
		local gridtop = (yanchor - (ytopcells * cellheight)) - ycellhalf

		-- Leftmost/topmost unwrapped tick and note values, for grid rendering
		local lefttick = wrapNum(data.tp - xleftcells, 1, ticks)
		local topnote = wrapNum(data.np + ytopcells, data.bounds.np)

		-- Left/top boundaries of sequence's current, non-wrapped chunk
		local tboundary = xanchor - ((cellwidth * (data.tp - 1)) + xcellhalf)
		local nboundary = yanchor - ((cellheight * (data.bounds.np[2] - data.np)) + ycellhalf)

		-- Sequence's full width and height, in pixels
		local fullwidth = cellwidth * ticks
		local fullheight = cellheight * notes

		-- All boundaries for wrapping the sequence's display
		local xranges = getTileAxisBounds(0, xfull, tboundary, fullwidth)
		local yranges = getTileAxisBounds(0, yfull, nboundary, fullheight)

		-- Positioning for beat-triangles
		local trifontheight = fontsmall:getHeight()
		local trifonttop = yfull - (fontsmall:getHeight() + 1)
		local tritop = trifonttop - trifontheight

		-- Initialize the local tables that will be populated
		local tintcolumns, drawnotes, drawsels, triangles = {}, {}, {}, {}

		-- Render the seq-window's background
		love.graphics.setColor(data.color.seq.light)
		love.graphics.rectangle("fill", left, top, xfull, yfull)

		-- Set color for rendering darkened rows
		love.graphics.setColor(data.color.seq.dark)

		-- Find and render darkened rows
		for y = 0, ycells - 1 do

			-- Get row's Y-center and Y-top
			local ytop = gridtop + (cellheight * y)

			-- Get the row's corresponding note, and the note's scale position
			local note = wrapNum(topnote - y, data.bounds.np)
			local notetype = data.pianometa[wrapNum(note + 1, 1, 12)][1]

			-- On black-key rows, render dark overlays
			if notetype == 0 then
				love.graphics.rectangle("fill", left, ytop, xfull, cellheight)
			end

			-- Highlight the active note-row
			if note == data.np then
				love.graphics.setColor(data.color.seq.active)
				love.graphics.rectangle("fill", left, ytop, xfull, cellheight)
				love.graphics.setColor(data.color.seq.dark)
			end

		end

		-- Find and render tick-columns
		for x = 0, xcells do

			local xleft = gridleft + (cellwidth * x)

			-- Get the row's corresponding tick
			local tick = wrapNum(lefttick + x, 1, ticks)

			-- See whether the current column is a factor of the beat
			local adjtick = wrapNum(tick, 1, beatsize)
			local afactor = 1
			for i = #factors, 1, -1 do
				if wrapNum(adjtick - 1, 0, factors[i] - 1) == 0 then
					afactor = factors[i]
					break
				end
			end

			-- If factor-column, table for later rendering
			if afactor >= beatthresh then
				local color = mixColors(beatcolor, invis, (beatsize / afactor) / 2)
				table.insert(tintcolumns, {tick, left + xleft, top, cellwidth, yfull, color})
			end

			-- If active column, table activity-color for later rendering
			if tick == data.tp then
				local color = data.color.seq.active
				table.insert(tintcolumns, {tick, left + xleft, top, cellwidth, yfull, color})
			end

		end

		-- Get render-note data from all visible sequences
		for snum, s in pairs(data.seq) do

			-- Get all shadow notes
			if s.overlay then
				drawnotes = tableCombine(
					drawnotes,
					makeNoteRenderTable(
						s.tick, 'shadow',
						left, top, xfull, yfull,
						cellwidth, cellheight, xranges, yranges
					)
				)
			end

			-- Get all active notes, if active notes are toggled visible
			if data.drawnotes and (snum == data.active) then
				drawnotes = tableCombine(
					drawnotes,
					makeNoteRenderTable(
						s.tick, 'active',
						left, top, xfull, yfull,
						cellwidth, cellheight, xranges, yranges
					)
				)
			end

		end

		-- If there is a selection range, find and store its coordinates
		if data.sel.l then

			local selleft = tickleft + ((data.tp - data.sel.l) * cellwidth)
			local seltop = (notetop + ((data.sel.t - 1) * cellheight)) - ycellhalf

			local selwidth = cellwidth * ((data.sel.r - data.sel.l) + 1)
			local selheight = cellheight * ((data.sel.t - data.sel.b) + 1)

			drawsels = makeSelectionRenderTable(
				left, top, xfull, yfull,
				selleft, seltop, selwidth, selheight,
				xranges, yranges
			)

		end

		-- Draw all tinted beat-columns
		drawBeatColumns(tintcolumns)

		-- Draw all overlay-notes on top of the sequence grid
		drawNoteTable(drawnotes)

		-- Draw all wrapped selection blocks
		drawSelectionTable(drawsels)

		-- Draw all beat-triangles along the bottom of the sequence frame
		drawBeatTriangles(triangles, beatsize, yfull, tritop, trifonttop)

		-- Draw the tick and note-duration reticules
		drawReticules(left, top, right, xanchor, yanchor, xcellhalf, ycellhalf, cellwidth)

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
		data:drawSeqGrid(seqleft, top, width, height, cellheight)

		-- Draw the vertical piano-roll
		data:drawPianoRoll(left, kwidth, cellheight, width, height)

	end,

	buildGUI = function(data, cnv, width, height)

		buildBackground(width, height)
		data:buildSidebar(0, 2, 100, height - 4, width, height)
		data:buildSeqFrame(100, 0, width, height)

		-- Draw the canvas onto the screen
		love.graphics.draw(cnv, 0, 0)

	end,

}