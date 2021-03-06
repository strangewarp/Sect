
return {
	
	drawSaveLoadPanel = function()

		love.graphics.setFont(D.font.save.raster)

		-- Draw frame's background
		love.graphics.setColor(D.color.saveload.background)
		local bgl, bgt, bgw, bgh = unpack(D.gui.save.bg)
		love.graphics.rectangle("fill", bgl, bgt, bgw, bgh)

		-- Draw every rectangle-panel
		for k, v in pairs(D.gui.save.rect) do
			local color, l, t, w, h = unpack(v)
			love.graphics.setColor(color)
			love.graphics.rectangle("fill", l, t, w, h)
		end

		-- Draw every text-slice
		for k, v in pairs(D.gui.save.text) do
			local color, text, l, t, w, align = unpack(v)
			love.graphics.setColor(color)
			love.graphics.printf(text, l, t, w, align)
		end

		-- Draw the reticule-line
		love.graphics.setColor(D.color.saveload.reticule)
		love.graphics.setLineWidth(2)
		love.graphics.line(D.gui.save.line)
		love.graphics.setLineWidth(1)

	end,

	buildSaveLoadPanel = function()

		-- Get save-font's height per line, as rendered on screen
		local textheight = D.font.save.raster:getHeight()

		local left = D.c.sqleft
		local top = D.c.sqtop
		local width = D.c.sqwidth
		local height = D.c.sqheight

		-- Get dir-validity-panel size
		local dleft = left + 15
		local dtop = top + 80
		local dwidth = width - 30
		local dheight = (textheight * 2) + 30

		-- Get dir-validity-text size
		local dtextleft = dleft + 15
		local dtexttop = dtop + 15
		local dtextwidth = dwidth - 30

		-- Get file-validity-panel size
		local vleft = left + 15
		local vtop = dtop + dheight + 10
		local vwidth = width - 30
		local vheight = (textheight * 2) + 30

		-- Get file-validity-text size
		local vtextleft = vleft + 15
		local vtexttop = vtop + 15
		local vtextwidth = vwidth - 30

		-- Get entry-panel size
		local eleft = left + 15
		local etop = vtop + vheight + 10
		local ewidth = width - 30

		-- Get entry-text size
		local etextleft = eleft + 15
		local etexttop = etop + 10
		local etextwidth = ewidth - 30

		-- Draw directory-existence confirmation panel
		local trect = {D.color.saveload.exist, dleft, dtop, dwidth, dheight}
		local trtext = {D.color.saveload.text_exist, D.savepath .. "\r\nDirectory exists!", dtextleft, dtexttop, dtextwidth, "center"}
		if not D.saveok then
			local scmdtab = deepCopy(D.cmds.SET_SAVE_PATH)
			for k, v in pairs(scmdtab) do
				local vlen = #v
				scmdtab[k] = v:sub(1, 1):upper() .. (((vlen > 1) and v:sub(2, vlen)) or "")
			end
			trect[1] = D.color.saveload.not_exist
			trtext = {D.color.saveload.text_not_exist, D.savepath .. "\r\nDirectory doesn't exist! " .. table.concat(scmdtab, "-") .. " to change it!", dtextleft, dtexttop, dtextwidth, "center"}
		end

		-- Draw file-existence confirmation panel
		local vrect = {D.color.saveload.exist, vleft, vtop, vwidth, vheight}
		local vmsg = "File already exists.\r\nSaving will overwrite it! Loading is OK!"
		local vcolor = D.color.saveload.text_exist
		if not D.savevalid then
			vrect[1] = D.color.saveload.not_exist
			vcolor = D.color.saveload.text_not_exist
			vmsg = "Enter a valid directory before using saveload commands!"
			if D.saveok then
				if D.savestring:len() > 0 then
					vmsg = "File does not already exist.\r\nCannot load; can save!"
				else
					vmsg = "Type a filename to check availability!"
				end
			end
		end
		local vtext = {vcolor, vmsg, vtextleft, vtexttop, vtextwidth, "center"}

		local text = D.savestring
		local overflow = ""
		local lines = {}
		repeat
			while D.font.save.raster:getWidth(text) > etextwidth do
				overflow = (((#text > 0) and text:sub(-1)) or "") .. overflow
				text = ((#text > 0) and text:sub(1, #text - 1)) or ""
			end
			table.insert(lines, text)
			text = overflow
			overflow = ""
		until #text == 0

		text = table.concat(lines, " ")

		local rx = D.sfsp
		local ry = 0
		local roffset = 0
		for k, v in pairs(lines) do
			ry = ry + 1
			roffset = roffset + #v
			if roffset >= D.sfsp then
				roffset = roffset - #v
				break
			end
			rx = rx - #v
		end

		local eheight = (textheight * (#lines - 1)) + 40

		-- Get the text-entry-reticule position
		local retleft = etextleft + (((D.sfsp > 0) and D.font.save.raster:getWidth(lines[ry]:sub(1, rx))) or 0)
		local rettop = etexttop + (textheight * (ry - 1))

		local drect = {D.color.saveload.panel, eleft, etop, ewidth, eheight}
		local dtext = {D.color.saveload.text, text, etextleft, etexttop + 1, etextwidth, "left"}

		-- Save the panel-items for later rendering
		D.gui.save = {
			bg = {left, top, width, height},
			rect = {trect, vrect, drect},
			text = {trtext, vtext, dtext},
			line = {retleft, rettop, retleft, rettop + textheight},
		}

	end,

}
