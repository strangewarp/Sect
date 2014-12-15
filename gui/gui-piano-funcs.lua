
return {
	
	-- Draw a table of piano-key rectangles, with text overlay
	drawPianoRoll = function()

		love.graphics.setFont(D.font.piano.raster)

		local tab = D.gui.piano

		local fontheight = D.font.piano.raster:getHeight()

		-- Draw the filled piano-polygons
		for _, v in pairs(tab) do

			-- Draw the triangles that comprise the piano-key polygon
			love.graphics.setColor(v.color)
			for _, t in pairs(v.tri) do
				love.graphics.polygon("fill", t)
			end

		end

		-- Draw the polygons' outlines and text on top of the filled polygons
		for _, v in pairs(tab) do

			love.graphics.setColor(D.color.piano.border)
			love.graphics.polygon("line", v.poly)

			-- If text was given, print the key-name onto the key
			if v.text then
				local kh = v.b - v.t
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

		D.gui.piano = {} -- Empty the old piano-roll table

		local left = D.size.sidebar.width
		local kwidth = D.size.piano.basewidth + (D.width / 40)
		local width = D.width - left
		local height = D.height - D.size.track.height

		-- Get key heights, and half-key heights, and note-row heights
		local yflare = D.cellheight * 1.5
		local yflarehalf = yflare / 2
		local ymid = D.cellheight
		local khalf = D.cellheight / 2

		-- Get the center-point, on which the sequence grid (and by extension, the piano-roll) are fixed
		local ycenter = height * D.size.anchor.y

		-- Add the active note, in center position, with highlighted color, to the gui-table
		pianoNoteToDrawTable(D.np, left, ycenter, ymid, yflare, kwidth, true)

		-- Moving outwards from center, add piano-keys to the gui-table, until fully passing the stencil border
		local upkey, downkey, uppos, downpos = D.np, D.np, ycenter, ycenter
		while uppos >= (0 - khalf) do

			-- Update position and pointer values
			upkey = wrapNum(upkey + 1, D.bounds.np)
			downkey = wrapNum(downkey - 1, D.bounds.np)
			uppos = uppos - D.cellheight
			downpos = downpos + D.cellheight

			-- Add the two outermost notes, with normal color, to the gui-table
			pianoNoteToDrawTable(upkey, left, uppos, ymid, yflare, kwidth, false)
			if (downpos - yflarehalf) < height then
				pianoNoteToDrawTable(downkey, left, downpos, ymid, yflare, kwidth, false)
			end

		end

	end,

	-- Convert a note, and various positioning data, into an item in the two drawtables
	pianoNoteToDrawTable = function(note, left, center, midheight, flareheight, kwidth, highlight)

		local midhalf = midheight / 2
		local flarehalf = flareheight / 2
		local kcenter = kwidth * 0.6

		local key = wrapNum(note + 1, 1, 12)
		local octave = math.floor(note / 12)
		local oanchor = math.floor(D.np / 12) * 12
		local shape = D.pianometa[key][1]

		-- Change flag for key coloration, based on key's keyboard-piano position
		local kind = false
		if rangeCheck(note, oanchor, oanchor + (#D.pianokeys - 1)) then
			kind = true
		end

		local intab = {
			color = (kind and D.color.piano.active_light) or D.color.piano.inactive_light,
			tcolor = (kind and D.color.piano.text_active_light) or D.color.piano.text_inactive_light,
			kind = (kind and "white") or "black",
			l = left,
			t = center - midhalf,
			b = center + midhalf,
			fl = kcenter, -- Left key-text offset
			fr = kwidth - kcenter, -- Right key-text limit
		}

		-- If the piano-font is smaller than the key size, print the key-name onto the key
		if D.font.piano.height <= (midhalf * 2) then
			intab.text = D.pianometa[key][2] .. "-" .. octave
		end

		-- Insert color type and rectangle polygon, based on key type
		if shape == 0 then -- Black note poly
			intab.color = (kind and D.color.piano.active_dark) or D.color.piano.inactive_dark
			intab.tcolor = (kind and D.color.piano.text_active_dark) or D.color.piano.text_inactive_dark
			intab.fl = 0
			intab.fr = kcenter
			intab.poly = {
				left, center + midhalf,
				left, center - midhalf,
				left + kcenter, center - midhalf,
				left + kcenter, center + midhalf,
			}
		elseif (shape == 3) or (note == D.bounds.np[2]) then -- White note poly 3 (E, B)
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
			intab.color = D.color.piano.highlight
			intab.tcolor = D.color.piano.text_highlight
		end

		-- Simplify the possibly-concave polygon into triangles
		intab.tri = love.math.triangulate(intab.poly)

		-- Put the key-table into either end of the draw-table, to preserve correct draw-ordering
		table.insert(D.gui.piano, (kind and 1) or (#D.gui.piano + 1), intab)

	end,

}
