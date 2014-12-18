
return {
	
	-- Draw the reticules that show the position and size of current note-entry
	drawReticules = function()
		for k, v in ipairs(D.gui.reticule) do
			local color, poly = unpack(v)
			love.graphics.setColor(color)
			love.graphics.polygon("fill", poly)
		end
	end,

	-- Build the reticules that show the position and size of current note-entry
	buildReticules = function()

		D.gui.reticule = {} -- Reset GUI-reticule table

		-- If no sequenceis active, abort function
		if not D.active then
			return nil
		end

		local left = D.size.sidebar.width
		local top = 0
		local right = D.width
		local width = D.width - left
		local height = D.height - D.size.track.height
		local xhalf = width * D.size.anchor.x
		local yhalf = height * D.size.anchor.y
		local xcellhalf = D.cellwidth / 2
		local ycellhalf = D.cellheight / 2

		local nrh = ycellhalf
		local nrlr = left + xhalf - xcellhalf
		local nrll = nrlr - nrh
		local nrrl = nrlr + (D.cellwidth * D.dur)
		local nrrr = nrrl + nrh
		local nrt = yhalf - nrh
		local nrb = yhalf + nrh

		-- Draw the tick reticule
		local color
		if D.recording then
			if D.cmdmode == "gen" then
				color = D.color.reticule.generator
			elseif D.cmdmode == "cmd" then
				color = D.color.reticule.cmd
			else
				color = D.color.reticule.recording
			end
		else
			if D.cmdmode == "gen" then
				color = D.color.reticule.generator_dark
			elseif D.cmdmode == "cmd" then
				color = D.color.reticule.cmd_dark
			else
				color = D.color.reticule.dark
			end
		end

		local poly2 = {
			(D.recording and color) or D.color.reticule.light,
			{
				nrll, nrt,
				nrlr, yhalf,
				nrll, nrb
			},
		}
		table.insert(D.gui.reticule, poly2)

		-- Only draw right reticule arrow if Cmd Mode is inactive
		if D.cmdmode ~= "cmd" then
			if nrrl < right then
				local poly3 = {
					(D.recording and color) or D.color.reticule.light,
					{
						nrrr, nrt,
						nrrl, yhalf,
						nrrr, nrb
					},
				}
				table.insert(D.gui.reticule, poly3)
			end
		end

	end,

}
