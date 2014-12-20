
return {

	drawSidebar = function()

		local left, top = 0, 0
		local width, height = D.size.sidebar.width, D.height

		-- Draw the panel's background
		love.graphics.setColor(D.color.window.mid)
		love.graphics.rectangle("fill", left, top, width, height)

		-- Draw the sidebar image
		drawBoundedImage(left, top, width, height, D.img.sidebar)

		-- Set the correct font for sidebar text
		love.graphics.setFont(D.font.sidebar.raster)

		-- Draw all text, with shadows
		for k, v in ipairs(D.gui.sidebar.text) do
			local color, tleft, ttop, twidth, line = unpack(v)
			love.graphics.setColor(D.color.font.shadow)
			love.graphics.print(line, tleft + 1, ttop + 1)
			love.graphics.setColor(color)
			love.graphics.print(line, tleft, ttop)
		end

	end,
	
	-- Build the sidebar that contains all the sequence's metadata, and hotseat information
	buildSidebar = function()

		local left, top = 0, 0
		local width, height = D.size.sidebar.width, D.height
		local bot = top + height

		local tleft, ttop, twidth = left + 5, top + 10, width - 10

		local fontheight = D.font.sidebar.raster:getHeight()
		local fonthalf = roundNum(fontheight / 2, 0)

		local outtab = {}

		D.gui.sidebar.text = {} -- Clear old sidebar text

		-- Gather the metadata info
		local oticks = (D.active and D.seq[D.active].total) or 0
		local obeats = tostring(roundNum(oticks / (D.tpq * 4), 2))
		local notelet = D.pianometa[wrapNum(D.np + 1, 1, 12)][2]
		local octave = math.floor(D.np / 12)
		obeats = ((obeats:sub(-3, -3) == ".") and ("~" .. obeats)) or obeats

		-- If the save-folder wasn't found, throw some warning-text
		if not D.saveok then
			local warntab = {
				"! WARNING !",
				"savepath not found!",
				"saveload disabled.",
				"",
				"please change",
				"your savepath",
				"in the",
				"saveload panel!",
				"",
			}
			linesToSidebarText(
				warntab,
				tleft, ttop, twidth, fontheight,
				"left", D.color.font.warning
			)
			ttop = ttop + (fontheight * #warntab) + fonthalf
		end

		-- If no sequences are loaded, write a simple guidance statement,
		-- and skip displaying the sequence/pointer information.
		if D.active == false then
			outtab = {
				"no seqs loaded!",
				"",
				table.concat(D.cmds.TOGGLE_SAVELOAD_MODE, "-"),
				"opens the",
				"saveload panel",
				"",
				table.concat(D.cmds.INSERT_SEQ, "-"),
				"creates a seq",
				"",
			}
		end

		local addtab = {
			"mode: " .. D.modenames[D.cmdmode],
			"recording: " .. ((D.recording and "on") or "off"),
			"e-quant: " .. ((D.entryquant and "on") or "off"),
			"notes: " .. ((D.drawnotes and "visible") or "hidden"),
			"chans: " .. ((D.chanview and "visible") or "hidden"),
			"",
			"seq " .. (D.active or 0) .. "/" .. #D.seq,
			"beats " .. obeats,
			"",
			"tick " .. D.tp .. "/" .. oticks,
		}
		outtab = tableCombine(outtab, addtab)

		if D.cmdmode ~= "cmd" then
			local addnocmd = {
				"note " .. D.np .. " (" .. notelet .. "-" .. octave .. ")",
			}
			outtab = tableCombine(outtab, addnocmd)
		else
			local addnocmd = {
				"",
			}
			outtab = tableCombine(outtab, addnocmd)
		end

		local addtab2 = {
			"chan " .. D.chan,
			"",
		}
		outtab = tableCombine(outtab, addtab2)

		if D.cmdmode == "cmd" then
			local addcmd = {
				"cmd: " .. D.cmdtypes[D.cmdtype][2],
				"byte1: " .. D.cmdbyte1,
				"byte2: " .. D.cmdbyte2,
				"",
			}
			outtab = tableCombine(outtab, addcmd)
		end

		if D.cmdmode == "gen" then
			local addtab3 = {
				"k-species: " .. D.kspecies,
				"maxscales: " .. #D.scales[D.kspecies].s,
				"grabscales: " .. D.scalenum,
				"grabwheels: " .. D.wheelnum,
				"consonance: " .. D.consonance .. " %",
				"s-switch: " .. D.scaleswitch .. " %",
				"w-switch: " .. D.wheelswitch .. " %",
				"",
				"density: " .. D.density .. " %",
				"stick: " .. D.beatstick .. " %",
				"alt-ticks: " .. D.beatlength,
				"fill-beats: " .. D.beatbound,
				"",
				"beat-grain: " .. D.beatgrain,
				"note-grain: " .. D.notegrain,
				"",
			}
			outtab = tableCombine(outtab, addtab3)
		end

		if D.cmdmode ~= "cmd" then
			local addtab4 = {
				"velo " .. D.velo,
				"",
				"duration " .. D.dur,
			}
			outtab = tableCombine(outtab, addtab4)
		end

		local addtab5 = {
			"spacing " .. D.spacing,
			"factor " .. D.factors[D.fp] .. " (" .. D.factors[#D.factors] .. "/" .. (D.factors[#D.factors] / D.factors[D.fp]) .. ")",
			"",
			"bpm " .. D.bpm,
			"tpq " .. D.tpq,
			"",
			"hotseats",
		}
		outtab = tableCombine(outtab, addtab5)

		-- Put all pre-hotseat text into sidebar-text-storage
		linesToSidebarText(
			outtab,
			tleft, ttop, twidth, fontheight,
			"left", D.color.font.light
		)
		ttop = ttop + (fontheight * #outtab)

		-- Print out the hotseats, with the currently-active one highlighted
		for k, v in ipairs(D.hotseats) do
			local text = k .. string.rep(".", 1 + string.len(#D.hotseats) - (string.len(k) - 1)) .. v
			local color = ((k == D.activeseat) and D.color.font.highlight) or D.color.font.mid
			local line = {color, tleft, ttop, twidth, text}
			table.insert(D.gui.sidebar.text, line)
			ttop = ttop + fontheight
		end

	end,

	-- Convert a table of lines, boundaries, and color into sidebar-text.
	linesToSidebarText = function(lines, l, t, w, h, align, color)

		w = w - 1 -- Compensate for drop-shadow

		for _, v in ipairs(lines) do

			if (t + h + 1) > D.height then
				do break end
			end

			local clip = clipTextLine(v, w, "left", D.font.sidebar.raster)
			local out = {color, l, t, w, clip}
			table.insert(D.gui.sidebar.text, out)

			t = t + h

		end

	end,

}
