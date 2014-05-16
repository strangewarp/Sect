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

	-- Get all boundaries of a repeating 1D range,
	-- as tiled inside a larger range, starting at an origin point.
	getTileAxisBounds = function(base, size, origin, extent)

		local out = {}

		--print("FULL RANGE: "..base.." "..size.." "..origin.." "..extent) -- DEBUGGING

		-- If base-size range is not fully contained by origin-extent range,
		-- search for origin-extent sub-ranges.
		local oc = rangeCheck(origin, base, size)
		local oec = rangeCheck(origin + extent, base, size)
		if ((origin + extent) < (base + size))
		or (oc ~= oec)
		then

			local invalid, outside, offset = 0, 0, 0
			local bool = true

			-- Until invalid inner-range chunks have been reached on both sides,
			-- add inner-range boundaries to the outgoing table.
			while invalid < 2 do

				local asub = origin + (extent * offset)
				local bsub = asub + extent

				--if collisionCheck(base, 0, size, 1, asub, 0, bsub, 1) then
				if rangeCheck(asub, base, size)
				or rangeCheck(bsub, base, size)
				then
					--print("RANGE "..offset..": "..asub.." "..bsub) -- DEBUGGING
					out[#out + 1] = {
						o = offset,
						a = asub,
						b = bsub,
					}
					offset = offset + ((bool and -1) or 1)
				else
					--print("INVALID RANGE "..offset..": "..asub.." "..bsub) -- DEBUGGING
					invalid = invalid + 1
					offset = 1
					bool = false
				end

			end

		else -- If base-size range is contained, return origin-extent range.

			--print("RANGE 0: "..origin.." "..extent) -- DEBUGGING
			out[1] = {
				o = 0,
				a = origin,
				b = origin + extent,
			}

		end

		return out

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