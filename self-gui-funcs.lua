return {

	-- Build the window's background
	buildBackground = function(data, width, height)
		love.graphics.setColor(data.color.window.dark)
		love.graphics.rectangle("fill", 0, 0, width, height)
	end,

	-- Build a series of flat lines that summarize all currently-loaded sequences
	buildSummaryLines = function(data, left, top, right, bot, lheight)

		for k, v in ipairs(data.seq) do -- For every sequence...

			local bticks = data.tpq * 4
			local beats = math.ceil(#v.tick / bticks)
			local subsect = right / beats
			for i = 1, beats do -- For every beat's worth of ticks...

				local strength = 0
				local presence = false

				-- For every tick in the beat, increase the strength-var based on notes' cumulative length and volume
				for t = ((i - 1) * bticks) + 1, i * bticks do
					if v.tick[t] == nil then
						break
					elseif next(v.tick[t]) ~= nil then
						for nk, note in ipairs(v.tick[t]) do
							presence = true
							if note[1] == 'note' then
								strength = math.min(1, strength + (math.min(1, note[2] * data.tpq) * (note[5] * 127)))
							else
								strength = math.min(1, strength + (1 / data.tpq))
							end
						end
					end
				end

				-- Assign colors based on note presence and strength, and draw the beat's portion of the summary line
				local bcolor = data.color.window.dark
				local c1, c2 = bcolor, bcolor
				if presence then
					if k == data.active then
						c1, c2 = data.color.note.highlight, data.color.note.loud
					else
						c1, c2 = data.color.note.quiet, data.color.note.loud
					end
				end
				for hue, chroma in pairs(c1) do
					bcolor[hue] = (chroma * (1 - strength)) + (c2[hue] * strength)
				end
				love.graphics.setColor(bcolor)
				love.graphics.rectangle("fill", left + (subsect * (i - 1)), top + (lheight * (k - 1)), subsect, lheight)

			end

		end

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
			local notelet = data.pianometa[wrapNum(data.np, 1, 12)][2]
			local octave = math.floor(data.np / 12)
			obeats = ((obeats:sub(-3, -3) == ".") and ("~" .. obeats)) or obeats
			outtab = {
				"seq " .. data.active .. "/" .. #data.seq,
				"beats " .. obeats,
				"",
				"tick " .. data.tp .. "/" .. oticks,
				"note " .. data.np .. " (" .. notelet .. "-" .. octave .. ")",
				"",
				"chan " .. data.chan,
				"velo " .. data.velo,
				"duration " .. data.dur,
				"spacing " .. data.spacing,
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

		-- Call the function that draws the sequence-summary panel
		data:buildSummaryLines(left, ttop, right, bot - ttop, 2)

	end,

	-- Convert a note, and various positioning data, into an item in the two drawtables
	pianoNoteToDrawTables = function(data, whitedraw, blackdraw, note, left, center, midheight, flareheight, kwidth, highlight)

		local midhalf = midheight / 2
		local flarehalf = flareheight / 2
		local kcenter = kwidth * 0.6

		local key = wrapNum(note + 1, 1, 12)
		local octave = math.floor(note / 12)
		local whicharr = true
		local shape = data.pianometa[key][1]

		local intab = {
			name = data.pianometa[key][2] .. "-" .. octave,
			color = data.color.piano.light,
			l = left,
			t = center - midhalf,
			b = center + midhalf,
			r = left + kwidth,
			fl = kcenter, -- Left key-text offset
			fr = kwidth - kcenter, -- Right key-text limit
		}

		-- Insert color type and rectangle polygon, based on key type
		if shape == 0 then -- Black note poly
			whicharr = false
			intab.color = data.color.piano.dark
			intab.r = left + left + kcenter
			intab.fl = 0
			intab.fr = kcenter
			intab.poly = {
				left, center + midhalf,
				left, center - midhalf,
				left + kcenter, center - midhalf,
				left + kcenter, center + midhalf,
			}
		elseif (shape == 3) or (note == data.bounds.np[2]) then -- White note poly 3 (E, B)
			intab.b = center + flarehalf
			intab.poly = {
				left, center + midhalf,
				left, center - midhalf,
				left + kwidth, center - midhalf,
				left + kwidth, center + flarehalf,
				left + kcenter, center + flarehalf,
				left + kcenter, center + midhalf,
			}
		elseif shape == 1 then -- White note poly 1 (C, F)
			intab.t = center - flarehalf
			intab.poly = {
				left, center + midhalf,
				left, center - midhalf,
				left + kcenter, center - midhalf,
				left + kcenter, center - flarehalf,
				left + kwidth, center - flarehalf,
				left + kwidth, center + midhalf,
			}
		elseif shape == 2 then -- White note poly 2 (D, G, A)
			intab.t = center - flarehalf
			intab.b = center + flarehalf
			intab.poly = {
				left, center + midhalf,
				left, center - midhalf,
				left + kcenter, center - midhalf,
				left + kcenter, center - flarehalf,
				left + kwidth, center - flarehalf,
				left + kwidth, center + flarehalf,
				left + kcenter, center + flarehalf,
				left + kcenter, center + midhalf,
			}
		end

		-- If a highlight command has been received, set the key to a highlighted color
		if highlight then
			intab.color = data.color.piano.highlight
		end

		-- Put the key-table into the relevant draw-table
		table.insert((whicharr and whitedraw) or blackdraw, intab)

		return whitedraw, blackdraw

	end,

	-- Draw the column of piano-keys in the sequence window
	drawPianoRoll = function(data, left, kwidth, kheight, width, height)

		local whitedraw = {}
		local blackdraw = {}

		-- Get key heights, and half-key heights, and note-row heights
		local yflare = kheight * 1.5
		local ymid = kheight
		local khalf = kheight / 2

		-- Get the center-point, on which the sequence grid (and by extension, the piano-roll) are fixed
		local ycenter = height / 2

		-- Add the active note, in center position, with highlighted color, to the relevant draw-table
		whitedraw, blackdraw = data:pianoNoteToDrawTables(whitedraw, blackdraw, data.np, left, ycenter, ymid, yflare, kwidth, true)

		-- Moving outwards from center, add piano-keys to the draw-tables, until fully passing the stencil border
		local upkey, downkey, uppos, downpos = data.np, data.np, ycenter, ycenter
		while uppos >= (0 - khalf) do

			-- Update position and pointer values
			upkey = wrapNum(upkey + 1, data.bounds.np)
			downkey = wrapNum(downkey - 1, data.bounds.np)
			uppos = uppos - kheight
			downpos = downpos + kheight

			-- Add the two outermost notes, with normal color, to the relevant draw-tables
			whitedraw, blackdraw = data:pianoNoteToDrawTables(whitedraw, blackdraw, upkey, left, uppos, ymid, yflare, kwidth, false)
			whitedraw, blackdraw = data:pianoNoteToDrawTables(whitedraw, blackdraw, downkey, left, downpos, ymid, yflare, kwidth, false)

		end

		-- Draw all tabled keys, in the proper visibility order
		drawTabledKeys(whitedraw, "white")
		drawTabledKeys(blackdraw, "black")

	end,

	-- Draw the sequence-grid, centered on the active note and tick, and corresponding to the piano-roll
	drawSeqGrid = function(data, left, top, right, bot, kheight)

		local xfull = right - left
		local yfull = bot - top
		local xhalf = xfull / 2
		local yhalf = yfull / 2

		local cellwidth = (xhalf / data.tpq) / data.zoomx -- Tick-column width (based on tpq and zoom)
		local xcellhalf = cellwidth / 2
		local ycellhalf = kheight / 2

		local xrawcells = xfull / cellwidth
		local yrawcells = yfull / kheight
		local xhalfcells = xhalf / cellwidth
		local yhalfcells = yhalf / kheight
		local xcells = math.ceil(xrawcells)
		local ycells = math.ceil(yrawcells)

		local xleftcenter = xhalf - (xhalfcells * cellwidth)
		local ybotcenter = yhalf + (yhalfcells * kheight)

		local lefttick = wrapNum((data.tp - math.ceil(xhalfcells)), 1, #data.seq[data.active].tick)
		local botnote = wrapNum(data.np - math.ceil(yhalfcells), data.bounds.np)

		local trifontheight = fontsmall:getHeight()
		local trifonttop = yfull - (fontsmall:getHeight() + 1)
		local tritop = trifonttop - trifontheight

		local tintcolumns = {}
		local triangles = {}
		local drawnotes = {}

		-- Get all factors of the ticks-per-beat, for later column colorization
		local beatsize = data.tpq * 4
		local factors = getFactors(beatsize)

		for y = 0, ycells do

			-- Get row's Y-center and Y-top
			local ypos = yfull - (kheight * y)
			local ytop = ypos - ycellhalf

			local note = wrapNum(botnote + y, data.bounds.np)
			local rowcolor = ((note == data.np) and data.color.seq.active) or (((data.pianometa[wrapNum(note + 1, 1, 12)][1] > 0) and data.color.seq.light) or data.color.seq.dark)

			-- Draw the row's background line
			love.graphics.setColor(rowcolor)
			love.graphics.rectangle("fill", left, ytop, xfull, kheight)

			for x = 0, xcells do

				local xpos = xleftcenter + (cellwidth * x)
				local xleft = xpos - xcellhalf

				local tick = wrapNum(lefttick + x, 1, #data.seq[data.active].tick)
				local color = ((tick == data.tp) and deepCopy(data.color.seq.active)) or deepCopy(rowcolor)

				if y == 0 then -- On the first pass across the grid's X-axis...

					-- See whether the current column is a factor of the beat
					local adjtick = wrapNum(tick, 1, beatsize)
					local adivide = false
					local afactor = 1
					for i = #factors, 1, -1 do
						if wrapNum(adjtick - 1, 0, factors[i] - 1) == 0 then
							adivide = (#factors - i) + 1
							afactor = factors[i]
							break
						end
					end

					-- Table factor-columns, and active-column, for later color-change.
					if (afactor >= (data.tpq / 2)) or (xpos == xhalf) then

						-- If this isthe active column, highlight it.
						if xpos == xhalf then
							color = deepCopy(data.color.seq.active)
						end

						-- If the column falls on the beat itself,
						-- tab a beat-triangle to be drawn.
						if adjtick == 1 then
							table.insert(triangles, {tick, left + xpos})
						end

						-- Set the outgoing color to the beat-color
						color = deepCopy(data.color.seq.beat)

						-- Change the color's alpha, based on its primacy of beat-modulo
						color[4] = color[4] / adivide

						-- If this is the active column, highlight it.
						if xpos == xhalf then
							for k, v in pairs(data.color.seq.active) do
								color[k] = ((afactor < (data.tpq / 2)) and v) or ((color[k] + v) / 2)
							end
							color[4] = 255
						end

						-- Put the color and tick into tintcolumns-tab, for later rendering
						table.insert(tintcolumns, {tick, left + xleft, top, cellwidth, yfull, color})

					end

				end

				local redraw = false

				-- If the tick is within the selection range, change its color
				if data.sel.l
				and rangeCheck(tick, data.sel.l, data.sel.r)
				and rangeCheck(note, data.sel.t, data.sel.b)
				then
					redraw = true
					for i = 1, #color do
						color[i] = (color[i] + (data.color.seq.highlight[i] * 2)) / 3
					end
				end

				-- If this cell is a different color from the line-background, redraw it
				if redraw then
					love.graphics.setColor(color)
					love.graphics.rectangle("fill", left + xleft, ytop, cellwidth, kheight)
				end

			end

		end




		-- TODO: make this into a function, for RIGHT SIDE, to prevent repeat code
		-- Add notes to the drawtable that intersect with the seq-panel
		local ticks = #data.seq[data.active].tick
		local fullwidth = (cellwidth * ticks)
		local ldist = xhalf
		local rdist = xhalf + fullwidth
		local tdist = yhalf
		local bdist = yhalf
		while checkCollision(left, top, right, bot, ldist, top, rdist, bot) do

			for k, v in pairs(data.seq[data.active].tick) do

				for kk, vv in pairs(v) do

					local xmod = vv.tick - data.tp
					local xpos = ldist + (cellwidth * xmod)
					local xleft = xpos - xcellhalf
					local xwidth = (cellwidth * vv.note[3]) + xcellhalf

					local ytop = yhalf

					if checkCollision(left, top, right, bot, left + xleft, ytop, xwidth, kheight) then
						table.insert(drawnotes, {vv.tick, vv, left + xleft, ytop, xwidth, kheight})
					end

				end

			end

			ldist = ldist - fullwidth
			rdist = rdist - fullwidth

		end




		-- Draw all tinted beat-columns
		for k, v in ipairs(tintcolumns) do
			local tick, colleft, coltop, colwidth, colheight, color = unpack(v)
			love.graphics.setColor(color)
			love.graphics.rectangle("fill", colleft, coltop, colwidth, colheight)
		end

		-- Draw all note-squares on top of the sequence-grid
		for k, v in ipairs(drawnotes) do

			local tick, note, nleft, ntop, nx, ny = unpack(v)

			local notecolor = {}
			if tick == data.tp then
				notecolor = deepCopy(data.color.note.highlight)
			else
				local c1 = deepCopy(data.color.note.quiet)
				local c2 = deepCopy(data.color.note.loud)
				for hue, chroma in pairs(c1) do
					notecolor[hue] = (chroma * (1 - (v[5] * 2))) + (c2[hue] * (v[5] * 2))
				end
			end

			love.graphics.setColor(notecolor)
			love.graphics.rectangle("fill", nleft, ntop, nx, ny)
			love.graphics.setColor(data.color.seq.line)
			love.graphics.rectangle("line", nleft, ntop, nx, ny)

		end

		-- Draw all beat-triangles along the bottom of the sequence frame
		for k, v in ipairs(triangles) do
			local tick, xpos = unpack(v)
			local beat = ((tick - 1) / beatsize) + 1
			love.graphics.setColor(data.color.seq.highlight)
			love.graphics.polygon("fill", xpos - 19, yfull, xpos + 19, yfull, xpos, tritop)
			--love.graphics.setColor(data.color.seq.line)
			--love.graphics.polygon("line", xpos - 19, yfull, xpos + 19, yfull, xpos, tritop)
			love.graphics.setColor(data.color.font.light)
			love.graphics.printf(beat, xpos - 19, trifonttop, 38, "center")
		end

	end,

	-- Draw the contents of the sequence-frame
	buildSeqFrame = function(data, left, top, width, height)

		-- If no sequences are loaded, terminate the function
		if data.active == false then
			return nil
		end

		-- Set the frame-stencil
		love.graphics.setStencil(frameStencil(left, top, width, height))

		-- Piano-roll width (based on window size)
		local kwidth = roundNum(width / 10, 0)

		-- Piano-key height (based on zoom)
		local kheight = (height / 12) / data.zoomy

		-- Sequence grid's left border position
		local seqleft = left + (kwidth / 2)

		-- Draw the sequence-grid
		data:drawSeqGrid(seqleft, top, width, height, kheight)

		-- Draw the vertical piano-roll
		data:drawPianoRoll(left, kwidth, kheight, width, height)

		-- Unset the frame-stencil
		love.graphics.setStencil(nil)

	end,

	buildGUI = function(data, cnv, width, height)

		data:buildBackground(width, height)
		data:buildSidebar(0, 2, 100, height - 4, width, height)
		data:buildSeqFrame(100, 0, width, height)

		-- Draw the canvas onto the screen
		love.graphics.draw(cnv, 0, 0)

	end,

}