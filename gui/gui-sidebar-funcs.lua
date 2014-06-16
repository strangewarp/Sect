
return {
	
	-- Build the sidebar that contains all the sequence's metadata, and hotseat information
	buildSidebar = function(left, top, right, bot, width, height)

		local tleft, ttop, tright = left + 5, top + 10, right - 10
		local fontheight = fontsmall:getHeight()
		local outtab = {}

		-- Draw the pane's background
		love.graphics.setColor(data.color.window.mid)
		love.graphics.rectangle("fill", left, top, right, bot)

		-- Draw the Sect logo
		love.graphics.draw(sectlogo, left, top + bot - sectlogo:getHeight())

		-- Set the font-color
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
			}

			if data.scalemode then
				local addtab = {
					"pullnotes: " .. data.notecompare,
					"k-species: " .. data.kspecies,
					"",
				}
				outtab = tableCombine(outtab, addtab)
			end

			local addtab2 = {
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

			outtab = tableCombine(outtab, addtab2)

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
		buildSummaryLines(left, ttop, right - left, bot - ttop, 15)

	end,

	-- Build a series of flat lines that summarize all currently-loaded sequences
	buildSummaryLines = function(left, top, width, height, lheight)

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

			-- Increase color-strength for every note, weighted against ticks/duration
			for _, v in pairs(data.seq[i].tick) do
				for _, nv in pairs(v) do
					if nv.note[1] == 'note' then
						strength = strength + nv.note[3]
					end
				end
			end
			strength = math.min(ticks, strength) / ticks

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

	-- Draw the column of piano-keys in the sequence window
	drawPianoRoll = function(left, kwidth, cellheight, width, height)

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

	-- Draw a table of piano-key rectangles, with text overlay
	drawTabledKeys = function(tab, kind)

		local fh = fontsmall:getHeight()

		for _, v in pairs(tab) do

			-- Simplify the possibly-concave polygon into triangles
			local tri = love.math.triangulate(v.poly)

			-- Draw the triangles that comprise the piano-key polygon
			love.graphics.setColor(v.color)
			for _, t in pairs(tri) do
				love.graphics.polygon("fill", t)
			end

			-- Draw the polygon's outline
			love.graphics.setColor(data.color.piano.border)
			love.graphics.polygon("line", v.poly)

			-- Get key height from its positional metadata
			local kh = v.b - v.t

			-- If the small font is smaller than the key size, print the key-name onto the key
			if fh <= kh then
				local color = ((kind == "white") and data.color.piano.labeldark) or data.color.piano.labellight
				love.graphics.setColor(color)
				love.graphics.printf(
					v.name,
					v.l + v.fl,
					(v.t + kh) - ((kh + fh) / 2),
					v.fr,
					"center"
				)
			end

		end

	end,

}
