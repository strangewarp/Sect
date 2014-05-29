return {
	
	-- Build the window's background
	buildBackground = function(width, height)
		love.graphics.setColor(data.color.window.dark)
		love.graphics.rectangle("fill", 0, 0, width, height)
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
		love.graphics.setFont(fontsmall)

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

	-- Get a note's color based on velocity.
	-- c1, c2: "quiet" and "loud" colors.
	getVelocityColor = function(n, c1, c2)

		local veloval = n.note[data.acceptmidi[n.note[1]][2]]
		local velomap = veloval / data.bounds.velo[2]
		local velorev = (data.bounds.velo[2] - veloval) / data.bounds.velo[2]

		return mixColors(c2, c1, velorev)

	end,

	-- Convert a note, and various positioning data, into an item in the two drawtables
	pianoNoteToDrawTables = function(whitedraw, blackdraw, note, left, center, midheight, flareheight, kwidth, highlight)

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

	-- Mix two colors, with the average biased in the given direction
	mixColors = function(c1, c2, bias)

		local outcolor = {}

		for hue, chroma in pairs(c1) do
			outcolor[hue] = (chroma + (c2[hue] * bias)) / (bias + 1)
		end

		return outcolor

	end,

	-- Given a table of strings, xy coordinates, and a line-height value, print out multiple stacked lines of text
	printMultilineText = function(atoms, x, y, w, align)

		love.graphics.printf(
			table.concat(atoms, "\n"),
			x,
			y,
			w,
			align
		)

	end,

}