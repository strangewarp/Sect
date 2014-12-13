
return {

	drawSidebar = function()

		local left, top = 0, 0
		local width, height = data.size.sidebar.width, data.height

		-- Draw the panel's background
		love.graphics.setColor(data.color.window.mid)
		love.graphics.rectangle("fill", left, top, width, height)

		-- Draw the sidebar image
		drawBoundedImage(left, top, width, height, data.img.sidebar)

		-- Set the correct font for sidebar text
		love.graphics.setFont(data.font.sidebar.raster)

		-- Draw all text, with shadows
		for k, v in ipairs(data.gui.sidebar.text) do
			local color, tleft, ttop, twidth, line = unpack(v)
			love.graphics.setColor(data.color.font.shadow)
			love.graphics.print(line, tleft + 1, ttop + 1)
			love.graphics.setColor(color)
			love.graphics.print(line, tleft, ttop)
		end

	end,
	
	-- Build the sidebar that contains all the sequence's metadata, and hotseat information
	buildSidebar = function()

		local left, top = 0, 0
		local width, height = data.size.sidebar.width, data.height
		local bot = top + height

		local tleft, ttop, twidth = left + 5, top + 10, width - 10

		local fontheight = data.font.sidebar.raster:getHeight()
		local fonthalf = roundNum(fontheight / 2, 0)

		local outtab = {}

		data.gui.sidebar.text = {} -- Clear old sidebar text

		-- Gather the metadata info
		local oticks = (data.active and #data.seq[data.active].tick) or 0
		local obeats = tostring(roundNum(oticks / (data.tpq * 4), 2))
		local notelet = data.pianometa[wrapNum(data.np + 1, 1, 12)][2]
		local octave = math.floor(data.np / 12)
		obeats = ((obeats:sub(-3, -3) == ".") and ("~" .. obeats)) or obeats

		-- If the save-folder wasn't found, throw some warning-text
		if not data.saveok then
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
				"left", data.color.font.warning
			)
			ttop = ttop + (fontheight * #warntab) + fonthalf
		end

		-- If no sequences are loaded, write a simple guidance statement,
		-- and skip displaying the sequence/pointer information.
		if data.active == false then
			outtab = {
				"no seqs loaded!",
				"",
				string.upper(table.concat(data.cmds.TOGGLE_SAVELOAD_MODE, "-")),
				"opens the",
				"saveload panel",
				"",
				string.upper(table.concat(data.cmds.INSERT_SEQ, "-")),
				"creates a seq",
				"",
			}
		end

		local addtab = {
			"mode: " .. data.modenames[data.cmdmode],
			"recording: " .. ((data.recording and "on") or "off"),
			"e-quant: " .. ((data.entryquant and "on") or "off"),
			"notes: " .. ((data.drawnotes and "visible") or "hidden"),
			"chans: " .. ((data.chanview and "visible") or "hidden"),
			"",
			"seq " .. (data.active or 0) .. "/" .. #data.seq,
			"beats " .. obeats,
			"",
			"tick " .. data.tp .. "/" .. oticks,
		}
		outtab = tableCombine(outtab, addtab)

		if data.cmdmode ~= "cmd" then
			local addnocmd = {
				"note " .. data.np .. " (" .. notelet .. "-" .. octave .. ")",
			}
			outtab = tableCombine(outtab, addnocmd)
		else
			local addnocmd = {
				"",
			}
			outtab = tableCombine(outtab, addnocmd)
		end

		local addtab2 = {
			"chan " .. data.chan,
			"",
		}
		outtab = tableCombine(outtab, addtab2)

		if data.cmdmode == "cmd" then
			local addcmd = {
				"cmd: " .. data.cmdtypes[data.cmdtype][2],
				"byte1: " .. data.cmdbyte1,
				"byte2: " .. data.cmdbyte2,
				"",
			}
			outtab = tableCombine(outtab, addcmd)
		end

		if data.cmdmode == "gen" then
			local addtab3 = {
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
			outtab = tableCombine(outtab, addtab3)
		end

		if data.cmdmode ~= "cmd" then
			local addtab4 = {
				"velo " .. data.velo,
				"",
				"duration " .. data.dur,
			}
			outtab = tableCombine(outtab, addtab4)
		end

		local addtab5 = {
			"spacing " .. data.spacing,
			"factor " .. data.factors[data.fp] .. " (" .. data.factors[#data.factors] .. "/" .. (data.factors[#data.factors] / data.factors[data.fp]) .. ")",
			"",
			"bpm " .. data.bpm,
			"tpq " .. data.tpq,
			"",
			"hotseats",
		}
		outtab = tableCombine(outtab, addtab5)

		-- Put all pre-hotseat text into sidebar-text-storage
		linesToSidebarText(
			outtab,
			tleft, ttop, twidth, fontheight,
			"left", data.color.font.light
		)
		ttop = ttop + (fontheight * #outtab)

		-- Print out the hotseats, with the currently-active one highlighted
		for k, v in ipairs(data.hotseats) do
			local text = k .. string.rep(".", 1 + string.len(#data.hotseats) - (string.len(k) - 1)) .. v
			local color = ((k == data.activeseat) and data.color.font.highlight) or data.color.font.mid
			local line = {color, tleft, ttop, twidth, text}
			table.insert(data.gui.sidebar.text, line)
			ttop = ttop + fontheight
		end

	end,

	-- Convert a table of lines, boundaries, and color into sidebar-text.
	linesToSidebarText = function(lines, l, t, w, h, align, color)

		w = w - 1 -- Compensate for drop-shadow

		for _, v in ipairs(lines) do

			if (t + h + 1) > data.height then
				do break end
			end

			local clip = clipTextLine(v, w, "left", data.font.sidebar.raster)
			local out = {color, l, t, w, clip}
			table.insert(data.gui.sidebar.text, out)

			t = t + h

		end

	end,

}
