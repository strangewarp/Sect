
return {
	
	-- Build the window's background
	buildBackground = function(width, height)
		love.graphics.setColor(data.color.window.dark)
		love.graphics.rectangle("fill", 0, 0, width, height)
	end,

	-- Build the entire GUI
	buildGUI = function(width, height)

		buildBackground(width, height)
		buildSidebar(0, 2, 100, height - 4, width, height)
		buildSeqFrame(100, 0, width, height)

	end,

	-- Draw the contents of the sequence-frame
	buildSeqFrame = function(left, top, width, height)

		-- If no sequences are loaded, terminate the function
		if data.active == false then
			return nil
		end

		-- Piano-roll width (based on window size)
		local kwidth = roundNum(width / 10, 0)

		-- Piano-key height (based on zoom)
		local cellheight = (height / 12) / data.zoomy

		-- Sequence grid's left border position
		local seqleft = left + (kwidth / 2)

		-- Draw the sequence-grid
		drawSeqGrid(seqleft, top, width, height, cellheight)

		-- Draw the vertical piano-roll
		drawPianoRoll(left, kwidth, cellheight, width, height)

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
