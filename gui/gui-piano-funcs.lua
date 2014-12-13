
return {
	
	-- Draw a table of piano-key rectangles, with text overlay
	drawPianoRoll = function()

		love.graphics.setFont(data.font.piano.raster)

		local tab = data.gui.piano

		local fontheight = data.font.piano.raster:getHeight()

		for _, v in ipairs(tab) do

			-- Draw the triangles that comprise the piano-key polygon
			love.graphics.setColor(v.color)
			for _, t in pairs(v.tri) do
				love.graphics.polygon("fill", t)
			end

			-- Draw the polygon's outline
			love.graphics.setColor(data.color.piano.border)
			love.graphics.polygon("line", v.poly)

			-- Get key height from its positional data
			local kh = v.b - v.t

			-- If text was given, print the key-name onto the key
			if v.text then
				love.graphics.setColor(v.tcolor)
				love.graphics.printf(
					v.text,
					v.l + v.fl,
					v.t + ((kh - fontheight) / 2),
					v.fr,
					"center"
				)
			end

		end

	end,

	-- Draw the column of piano-keys in the sequence window
	buildPianoRoll = function()

		data.gui.piano = {} -- Empty the old piano-roll table

		local left = data.size.sidebar.width
		local kwidth = data.size.piano.basewidth + (data.width / 40)
		local width = data.width - left
		local height = data.height - data.size.track.height

		-- Get key heights, and half-key heights, and note-row heights
		local yflare = data.cellheight * 1.5
		local ymid = data.cellheight
		local khalf = data.cellheight / 2

		-- Get the center-point, on which the sequence grid (and by extension, the piano-roll) are fixed
		local ycenter = height * data.size.anchor.y

		-- Add the active note, in center position, with highlighted color, to the gui-table
		pianoNoteToDrawTable(data.np, left, ycenter, ymid, yflare, kwidth, true)

		-- Moving outwards from center, add piano-keys to the gui-table, until fully passing the stencil border
		local upkey, downkey, uppos, downpos = data.np, data.np, ycenter, ycenter
		while uppos >= (0 - khalf) do

			-- Update position and pointer values
			upkey = wrapNum(upkey + 1, data.bounds.np)
			downkey = wrapNum(downkey - 1, data.bounds.np)
			uppos = uppos - data.cellheight
			downpos = downpos + data.cellheight

			-- Add the two outermost notes, with normal color, to the gui-table
			pianoNoteToDrawTable(upkey, left, uppos, ymid, yflare, kwidth, false)
			pianoNoteToDrawTable(downkey, left, downpos, ymid, yflare, kwidth, false)

		end

	end,

	-- Convert a note, and various positioning data, into an item in the two drawtables
	pianoNoteToDrawTable = function(note, left, center, midheight, flareheight, kwidth, highlight)

		local midhalf = midheight / 2
		local flarehalf = flareheight / 2
		local kcenter = kwidth * 0.6

		local key = wrapNum(note + 1, 1, 12)
		local octave = math.floor(note / 12)
		local oanchor = math.floor(data.np / 12) * 12
		local shape = data.pianometa[key][1]

		-- Change flag for key coloration, based on key's keyboard-piano position
		local kind = false
		if rangeCheck(note, oanchor, oanchor + (#data.pianokeys - 1)) then
			kind = true
		end

		local intab = {
			color = (kind and data.color.piano.active_light) or data.color.piano.inactive_light,
			tcolor = (kind and data.color.piano.text_active_light) or data.color.piano.text_inactive_light,
			kind = (kind and "white") or "black",
			l = left,
			t = center - midhalf,
			b = center + midhalf,
			fl = kcenter, -- Left key-text offset
			fr = kwidth - kcenter, -- Right key-text limit
		}

		-- If the piano-font is smaller than the key size, print the key-name onto the key
		if data.font.piano.height <= (midhalf * 2) then
			intab.text = data.pianometa[key][2] .. "-" .. octave
		end

		-- Insert color type and rectangle polygon, based on key type
		if shape == 0 then -- Black note poly
			intab.color = (kind and data.color.piano.active_dark) or data.color.piano.inactive_dark
			intab.tcolor = (kind and data.color.piano.text_active_dark) or data.color.piano.text_inactive_dark
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

		-- If a highlight command has been received, highlight the key's colors
		if highlight then
			intab.color = data.color.piano.highlight
			intab.tcolor = data.color.piano.text_highlight
		end

		-- Simplify the possibly-concave polygon into triangles
		intab.tri = love.math.triangulate(intab.poly)

		-- Put the key-table into either end of the draw-table, to preserve correct draw-ordering
		table.insert(data.gui.piano, (kind and 1) or (#data.gui.piano + 1), intab)

	end,

}
