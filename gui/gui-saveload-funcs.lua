
return {
	
	buildSaveLoadFrame = function(left, top, width, height)

		-- Get save-font's height per line, as rendered on screen
		local textheight = data.font.save.raster:getHeight()

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

		love.graphics.setFont(data.font.save.raster)

		-- Draw frame's background
		love.graphics.setColor(data.color.saveload.background)
		love.graphics.rectangle("fill", left, top, width, height)

		-- Draw directory-existence confirmation panel
		if data.saveok then
			love.graphics.setColor(data.color.saveload.exist)
			love.graphics.rectangle("fill", dleft, dtop, dwidth, dheight)
			love.graphics.setColor(data.color.saveload.text_exist)
			love.graphics.printf(data.savepath .. "\r\nDirectory exists!", dtextleft, dtexttop, dtextwidth, "center")
		else
			local scmdtab = deepCopy(data.cmds.SET_SAVE_PATH)
			for k, v in pairs(scmdtab) do
				local vlen = #v
				scmdtab[k] = v:sub(1, 1):upper() .. (((vlen > 1) and v:sub(2, vlen)) or "")
			end
			love.graphics.setColor(data.color.saveload.not_exist)
			love.graphics.rectangle("fill", dleft, dtop, dwidth, dheight)
			love.graphics.setColor(data.color.saveload.text_not_exist)
			love.graphics.printf(data.savepath .. "\r\nDirectory doesn't exist! " .. table.concat(scmdtab, "-") .. " to change it!", dtextleft, dtexttop, dtextwidth, "center")
		end

		-- Draw file-existence confirmation panel
		if data.savevalid then
			love.graphics.setColor(data.color.saveload.exist)
			love.graphics.rectangle("fill", vleft, vtop, vwidth, vheight)
			love.graphics.setColor(data.color.saveload.text_exist)
			love.graphics.printf("File already exists.\r\nSaving will overwrite it! Loading is OK!", vtextleft, vtexttop, vtextwidth, "center")
		else
			local vmsg = "Enter a valid directory before using saveload commands!"
			if data.saveok then
				if data.savestring:len() > 0 then
					vmsg = "File does not already exist.\r\nCannot load; can save!"
				else
					vmsg = "Type a filename to check availability!"
				end
			end
			love.graphics.setColor(data.color.saveload.not_exist)
			love.graphics.rectangle("fill", vleft, vtop, vwidth, vheight)
			love.graphics.setColor(data.color.saveload.text_not_exist)
			love.graphics.printf(vmsg, vtextleft, vtexttop, vtextwidth, "center")
		end

		local text = data.savestring
		local overflow = ""
		local lines = {}
		repeat
			while data.font.save.raster:getWidth(text) > etextwidth do
				overflow = (((#text > 0) and text:sub(-1)) or "") .. overflow
				text = ((#text > 0) and text:sub(1, #text - 1)) or ""
			end
			table.insert(lines, text)
			text = overflow
			overflow = ""
		until #text == 0

		text = table.concat(lines, " ")

		local rx = data.sfsp
		local ry = 0
		local roffset = 0
		for k, v in pairs(lines) do
			ry = ry + 1
			roffset = roffset + #v
			if roffset >= data.sfsp then
				roffset = roffset - #v
				break
			end
			rx = rx - #v
		end

		local eheight = (textheight * (#lines - 1)) + 40

		-- Get the text-entry-reticule position
		local retleft = etextleft + (((data.sfsp > 0) and data.font.save.raster:getWidth(lines[ry]:sub(1, rx))) or 0)
		local rettop = etexttop + (textheight * (ry - 1))

		-- Draw text-entry panel
		love.graphics.setColor(data.color.saveload.panel)
		love.graphics.rectangle("fill", eleft, etop, ewidth, eheight)
		love.graphics.setColor(data.color.saveload.reticule)
		love.graphics.setLineWidth(2)
		love.graphics.line(retleft, rettop, retleft, rettop + textheight)
		love.graphics.setLineWidth(1)
		love.graphics.setColor(data.color.saveload.text)
		love.graphics.printf(text, etextleft, etexttop + 1, etextwidth, "left")

	end,

}
