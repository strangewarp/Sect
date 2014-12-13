
return {
	
	-- Draw a table of wrapped visible selection-positions
	drawSelectionTable = function(sels)

		for k, v in pairs(sels) do

			local l, t, w, h = unpack(v)

			love.graphics.setColor(D.color.selection.fill)
			love.graphics.rectangle("fill", l, t, w, h)

			love.graphics.setColor(D.color.selection.line)
			love.graphics.rectangle("line", l, t, w, h)

		end

	end,

	-- Make a wrapping render-table of all visible positions of the selection
	makeSelectionRenderTable = function(
		left, top, xfull, yfull,
		selleft, seltop, selwidth, selheight,
		xranges, yranges
	)

		local sels = {}

		-- For every combination of on-screen X-ranges and Y-ranges,
		-- check the selection's visibility there, and render if visible.
		for _, xr in pairs(xranges) do
			for _, yr in pairs(yranges) do

				local sw = selwidth

				-- Get the concrete offsets of the wrapped selection position
				local l = left + xr.a + selleft
				local t = top + yr.a + seltop + (D.cellheight * yr.o)

				-- Clip the portion of the selection that would overflow the left border
				if l < left then
					sw = sw - (left - l)
					l = left
				end

				-- If the selection is onscreen in this chunk, table it for display
				if collisionCheck(left, top, xfull, yfull, l, t, sw, selheight) then
					table.insert(sels, {l, t, sw, selheight})
				end

			end
		end

		return sels

	end,

}
