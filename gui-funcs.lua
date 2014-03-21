return {
	
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

	-- Called by love.graphics.setStencil to set the render boundaries of the sequence-frame
	frameStencil = function(left, top, width, height)
		love.graphics.rectangle("fill", left, top, width, height)
	end,

}