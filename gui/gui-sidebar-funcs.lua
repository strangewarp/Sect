
return {
	
	-- Build the sidebar that contains all the sequence's metadata, and hotseat information
	buildSidebar = function(left, top, right, bot, width, height)

		local tleft, ttop, tright = left + 5, top + 10, right - 10
		local outtab = {}

		local fontheight = data.font.sidebar.raster:getHeight()

		-- Draw the pane's background
		love.graphics.setColor(data.color.window.mid)
		love.graphics.rectangle("fill", left, top, right, bot)

		-- Draw the sidebar image
		drawBoundedImage(left, top, right, bot, data.img.sidebar)

		-- Set the font-color
		love.graphics.setColor(data.color.font.light)

		-- If no sequences are loaded, write a simple guidance statement,
		-- and skip displaying the sequence/pointer information.
		if data.active == false then

			outtab = {
				"no seqs loaded!",
				"",
				string.upper(table.concat(data.cmds.LOAD_FILE, "-")),
				"opens a hotseat",
				"",
				string.upper(table.concat(data.cmds.INSERT_SEQ, "-")),
				"creates a seq",
				"",
			}

		end

		-- Gather and draw the metadata info
		local oticks = (data.active and #data.seq[data.active].tick) or 0
		local obeats = tostring(roundNum(oticks / (data.tpq * 4), 2))
		local notelet = data.pianometa[wrapNum(data.np + 1, 1, 12)][2]
		local octave = math.floor(data.np / 12)
		obeats = ((obeats:sub(-3, -3) == ".") and ("~" .. obeats)) or obeats

		local addtab = {
			"mode: " .. data.modenames[data.cmdmode],
			"recording: " .. ((data.recording and "on") or "off"),
			"notes: " .. ((data.drawnotes and "visible") or "hidden"),
			"chans: " .. ((data.chanview and "visible") or "hidden"),
			"",
			"seq " .. (data.active or 0) .. "/" .. #data.seq,
			"beats " .. obeats,
			"",
			"tick " .. data.tp .. "/" .. oticks,
		}
		outtab = tableCombine(outtab, addtab)

		if data.cmdmode == "cmd" then
			local addcmd = {
				"",
				"cmd: " .. data.cmdtypes[data.cmdtype][2],
				"byte1: " .. data.cmdbyte1,
				"byte2: " .. data.cmdbyte2,
				"",
			}
			outtab = tableCombine(outtab, addcmd)
		else
			local addnocmd = {
				"note " .. data.np .. " (" .. notelet .. "-" .. octave .. ")",
				"",
			}
			outtab = tableCombine(outtab, addnocmd)
		end

		if data.cmdmode == "gen" then
			local addtab2 = {
				"k-species: " .. data.kspecies,
				"maxscales: " .. #data.scales[data.kspecies].s,
				"grabscales: " .. data.scalenum,
				"grabwheels: " .. data.wheelnum,
				"consonance: " .. data.consonance .. " %",
				"s-switch: " .. data.scaleswitch .. " %",
				"w-switch: " .. data.wheelswitch .. " %",
				"",
				"density: " .. data.density .. " %",
				"stick: " .. data.beatstick .. " %",
				"alt-ticks: " .. data.beatlength,
				"fill-beats: " .. data.beatbound,
				"",
				"beat-grain: " .. data.beatgrain,
				"note-grain: " .. data.notegrain,
				"",
			}
			outtab = tableCombine(outtab, addtab2)
		end

		local addtab3 = {
			"bpm " .. data.bpm,
			"tpq " .. data.tpq,
			"",
			"chan " .. data.chan,
			"velo " .. data.velo,
			"duration " .. data.dur,
			"spacing " .. data.spacing,
			"",
		}
		outtab = tableCombine(outtab, addtab3)

		-- Set the correct font for sidebar text
		love.graphics.setFont(data.font.sidebar.raster)

		-- If the save-folder wasn't found, throw some warning-text
		if not data.saveok then
			local warntab = {
				"! WARNING !",
				"savepath not found!",
				"saveload disabled.",
				"",
				"please change",
				"\"savepath\" entry",
				"in user-prefs.lua!",
				"",
			}
			love.graphics.setColor(data.color.font.shadow)
			printMultilineText(warntab, tleft + 1, ttop + 1, _, "left")
			love.graphics.setColor(data.color.font.warning)
			printMultilineText(warntab, tleft, ttop, _, "left")
			ttop = ttop + (#warntab * fontheight) + roundNum(fontheight / 2, 0)
		end

		-- Print the pre-hotseat sidebar text
		love.graphics.setColor(data.color.font.shadow)
		printMultilineText(outtab, tleft + 1, ttop + 1, _, "left")
		love.graphics.setColor(data.color.font.light)
		printMultilineText(outtab, tleft, ttop, _, "left")
		ttop = ttop + (#outtab * fontheight) + roundNum(fontheight / 2, 0)

		-- Print out the hotseats, with the currently-active one highlighted
		outtab = {"hotseats"}
		local acheck = 1
		while acheck ~= data.activeseat do
			local text = acheck .. string.rep(".", 1 + string.len(#data.hotseats) - (string.len(acheck) - 1)) .. data.hotseats[acheck]
			table.insert(outtab, text)
			acheck = acheck + 1
		end
		love.graphics.setColor(data.color.font.mid)
		printMultilineText(outtab, tleft, ttop, _, "left")
		ttop = ttop + (#outtab * fontheight)

		love.graphics.setColor(data.color.font.highlight)
		printMultilineText({acheck .. string.rep(".",  1 + string.len(#data.hotseats) - (string.len(acheck) - 1)) .. data.hotseats[acheck]}, tleft, ttop, tright, "left")
		acheck = acheck + 1
		ttop = ttop + fontheight

		outtab = {}
		while acheck <= #data.hotseats do
			local text = acheck .. string.rep(".",  1 + string.len(#data.hotseats) - (string.len(acheck) - 1)) .. data.hotseats[acheck]
			table.insert(outtab, text)
			acheck = acheck + 1
		end
		table.insert(outtab, "")
		love.graphics.setColor(data.color.font.mid)
		printMultilineText(outtab, tleft, ttop, _, "left")

	end,

	-- Build a series of flat lines that summarize all currently-loaded sequences
	buildTrackBar = function(left, top, width, height)

		love.graphics.setColor(data.color.window.dark)
		love.graphics.rectangle("fill", left, top, width, height)

		drawBoundedImage(left, top, width, height, data.img.botbar)

		local fontheight = data.font.botbar.raster:getHeight()

		local seqs = #data.seq

		local boxwidth = (height / 3) - 1
		local coltotal = math.floor(width / (boxwidth + 1))
		local rowtotal = 0
		for i = 1, seqs, coltotal do
			rowtotal = rowtotal + 1
		end
		local boxheight = math.min(boxwidth, (height / rowtotal) - 1)

		local row = 1
		local col = 1

		-- For every sequence...
		for i = 1, seqs do

			local boxleft = (boxwidth * (col - 1)) + (col - 1)
			local boxtop = (boxheight * (row - 1)) + (row - 1)

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
			love.graphics.rectangle("fill", left + boxleft, top + boxtop, boxwidth, boxheight)

			local itext = tostring(i)
			local fontwidth = data.font.botbar.raster:getWidth(itext)
			local textleft = left + boxleft + ((boxwidth - fontwidth) / 2)
			local texttop = top + boxtop + ((boxheight - fontheight) / 2)

			-- Build coordinates of the active-sequence reticule
			if i == data.active then

				local boxhalfx = boxwidth / 2
				local boxhalfy = boxheight / 2

				local rlx =	left + boxleft
				local rcx = left + boxleft + boxhalfx
				local rrx = left + boxleft + boxwidth
				local rty = top + boxtop
				local rcy = top + boxtop + boxhalfy
				local rby = top + boxtop + boxheight

				local poly = {
					rlx, rcy,
					rcx, rty,
					rrx, rcy,
					rcx, rby,
				}

				-- Draw the active-sequence reticule
				love.graphics.setColor(data.color.summary.pointer)
				love.graphics.polygon("fill", poly)
				love.graphics.setColor(data.color.summary.pointer_border)
				love.graphics.polygon("line", poly)

			end

			-- Print a number on the sequence-bar, if space allows
			local displaynum = 5
			if (coltotal % 5) == 0 then
				displaynum = 4
			end
			if (fontheight <= boxheight) or ((i % displaynum) == 0) then
				love.graphics.setFont(data.font.botbar.raster)
				love.graphics.setColor(data.color.summary.text_shadow)
				love.graphics.print(itext, textleft + 1, texttop + 1)
				love.graphics.setColor(data.color.summary.text)
				love.graphics.print(itext, textleft, texttop)
			end

			-- Iterate through row and column positions
			if col == coltotal then
				col = 1
				row = row + 1
			else
				col = col + 1
			end

		end

	end,

	-- Draw the column of piano-keys in the sequence window
	drawPianoRoll = function(left, kwidth, width, height)

		local whitedraw = {}
		local blackdraw = {}

		-- Get key heights, and half-key heights, and note-row heights
		local yflare = data.cellheight * 1.5
		local ymid = data.cellheight
		local khalf = data.cellheight / 2

		-- Get the center-point, on which the sequence grid (and by extension, the piano-roll) are fixed
		local ycenter = height * data.size.anchor.y

		-- Add the active note, in center position, with highlighted color, to the relevant draw-table
		whitedraw, blackdraw = pianoNoteToDrawTables(whitedraw, blackdraw, data.np, left, ycenter, ymid, yflare, kwidth, true)

		-- Moving outwards from center, add piano-keys to the draw-tables, until fully passing the stencil border
		local upkey, downkey, uppos, downpos = data.np, data.np, ycenter, ycenter
		while uppos >= (0 - khalf) do

			-- Update position and pointer values
			upkey = wrapNum(upkey + 1, data.bounds.np)
			downkey = wrapNum(downkey - 1, data.bounds.np)
			uppos = uppos - data.cellheight
			downpos = downpos + data.cellheight

			-- Add the two outermost notes, with normal color, to the relevant draw-tables
			whitedraw, blackdraw = pianoNoteToDrawTables(whitedraw, blackdraw, upkey, left, uppos, ymid, yflare, kwidth, false)
			whitedraw, blackdraw = pianoNoteToDrawTables(whitedraw, blackdraw, downkey, left, downpos, ymid, yflare, kwidth, false)

		end

		-- Draw all tabled keys, in the proper visibility order
		drawTabledPianoKeys(whitedraw, "white")
		drawTabledPianoKeys(blackdraw, "black")

	end,

	-- Draw a table of piano-key rectangles, with text overlay
	drawTabledPianoKeys = function(tab, kind)

		local fontheight = data.font.piano.raster:getHeight()

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
			if fontheight <= kh then
				local color = ((kind == "white") and data.color.piano.labeldark) or data.color.piano.labellight
				love.graphics.setColor(color)
				love.graphics.setFont(data.font.piano.raster)
				love.graphics.printf(
					v.name,
					v.l + v.fl,
					(v.t + kh) - ((kh + fontheight) / 2),
					v.fr,
					"center"
				)
			end

		end

	end,

}
