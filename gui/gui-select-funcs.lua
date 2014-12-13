
return {
	
	-- Draw a table of wrapped visible selection-positions
	drawSelectionTable = function()
		for k, v in pairs(D.gui.sel) do
			local l, t, w, h = unpack(v)
			love.graphics.setColor(D.color.selection.fill)
			love.graphics.rectangle("fill", l, t, w, h)
			love.graphics.setColor(D.color.selection.line)
			love.graphics.rectangle("line", l, t, w, h)
		end
	end,

	-- Make a wrapping render-table of all visible positions of the selection
	buildSelectionTable = function()

		-- If there is no selection range, abort function
		if not D.sel.l then
			return nil
		end

		local left = D.size.sidebar.width
		local top = 0
		local width = D.width - left
		local height = D.height - top

		local xranges = D.c.wrap.x
		local yranges = D.c.wrap.y

		local selleft = ((D.sel.l - 1) * D.cellwidth)
		local seltop = (D.bounds.np[2] - D.sel.t) * D.cellheight

		local selwidth = D.cellwidth * ((D.sel.r - D.sel.l) + 1)
		local selheight = D.cellheight * ((D.sel.t - D.sel.b) + 1)

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
				if collisionCheck(left, top, width, height, l, t, sw, selheight) then
					table.insert(sels, {l, t, sw, selheight})
				end

			end
		end

		return sels

	end,

}
