
return {

	-- If a note is on either of the pointer axes,
	-- apply highlights to its note and border colors.
	applyNoteHighlight = function(n, c1, c2)

		local nindex = n.note[data.acceptmidi[n.note[1]][1]]
		local linecolor = deepCopy(data.color.note.border)
		local highlight = data.color.note.highlight

		-- If the note is on both axes, highlight it distinctly
		if (n.tick == data.tp) and (nindex == data.np) then

			c1, c2 = mixColors(c1, highlight, 0.6), mixColors(c2, highlight, 0.6)
			linecolor = deepCopy(data.color.note.lightborder)

		-- Else if the note is on one axis, highlight it moderately
		elseif (n.tick == data.tp) or (nindex == data.np) then

			c1, c2 = mixColors(c1, highlight, 0.25), mixColors(c2, highlight, 0.25)
			linecolor = deepCopy(data.color.note.adjborder)

		end

		return c1, c2, linecolor

	end,

	-- Draw a given table of render-notes
	drawNoteTable = function(notes)

		local c1, c2, linecolor = {}, {}, {}

		local fontheight = data.font.note.raster:getHeight()
		love.graphics.setFont(data.font.note.raster)

		-- If linecolor was not given, keep a note of that
		local line = not (linecolor == nil)

		-- Sort shadow notes to the beginning of the render-table,
		-- in order to prevent Z-fighting.
		table.sort(notes, function(a, b) return (a[1] == 'shadow') and (b[1] ~= 'shadow') end)

		-- For every note in the render-table...
		for k, v in pairs(notes) do

			-- Unpack the note-vars and render-vars
			local kind, seq, n, nleft, ntop, nx, ny = unpack(v)
			local nxhalf = nx / 2
			local nyhalf = ny / 2

			-- Set quiet/loud colors differently, for shadow/select/active notes
			if kind == 'shadow' then
				c1 = deepCopy(data.color.note.overlay_quiet)
				c2 = deepCopy(data.color.note.overlay_loud)
			elseif kind == 'select' then
				c1 = deepCopy(data.color.note.select_quiet)
				c2 = deepCopy(data.color.note.select_loud)
			else
				c1 = deepCopy(data.color.note.quiet)
				c2 = deepCopy(data.color.note.loud)
			end

			-- Highlight note-colors for notes on the tp/np axes
			c1, c2, linecolor = applyNoteHighlight(n, c1, c2)

			-- Get the note's velocity-color
			local notecolor = getVelocityColor(n, c1, c2)

			-- Draw the note-rectangle
			love.graphics.setColor(notecolor)
			love.graphics.rectangle("fill", nleft, ntop, nx, ny)

			-- If a linecolor was given...
			if kind ~= 'shadow' then

				-- Draw a border around the note
				love.graphics.setColor(linecolor)
				love.graphics.rectangle("line", nleft, ntop, nx, ny)

				-- Draw the note's velocity-bar
				local barcomp = getVelocityColor(
					n,
					data.color.note.bar_quiet,
					data.color.note.bar_loud
				)
				local bartop = ny - (ny * (n.note[data.acceptmidi[n.note[1]][2]] / data.bounds.velo[2]))
				love.graphics.setColor(barcomp)
				love.graphics.line(
					nleft, ntop + bartop,
					nleft + nx, ntop + bartop
				)

				-- If chanview mode is enabled,
				-- draw channel numbers and velocity-bars onto notes.
				if data.chanview and (n.note[1] == 'note') then

					love.graphics.print(
						tostring(n.note[4]),
						(nleft + (nx / 2)) - (data.font.note.raster:getWidth(tostring(n.note[4])) / 2),
						(ntop + (ny / 2)) - (fontheight / 2)
					)

				end

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

	-- Build a render-table for a given sequence of notes, wrapped to the screen
	makeNoteRenderTable = function(
		kind,
		seq, n,
		left, top,
		xfull, yfull,
		xranges, yranges
	)

		local notes = {}

		for k, v in pairs(n) do
			for kk, vv in pairs(v) do

				-- Get the pitch-value, or pitch-corresponding value, of a given note
				local vp = vv.note[data.acceptmidi[vv.note[1]][1]]

				-- Duplicate the kind-of-note val, in case of changes
				local render = kind

				-- Pick out selected notes from within normal notes
				if (kind ~= 'shadow')
				and (data.selindex[vv.tick] ~= nil)
				and (data.selindex[vv.tick][vp] == true)
				then
					render = 'select'
				end

				-- For every combination of on-screen X-ranges and Y-ranges,
				-- check the note's visibility there, and render if visible.
				for _, xr in pairs(xranges) do
					for _, yr in pairs(yranges) do

						-- Get note's width, via duration, or default to 1 for non-note cmds
						local xwidth = ((vv.note[1] == 'note') and (data.cellwidth * vv.note[3])) or data.cellwidth

						-- Get note's inner-grid-concrete and absolute left and top offsets
						local ol = xr.a + ((vv.tick - 1) * data.cellwidth)
						local ot = yr.b - ((vp - yr.o) * data.cellheight)
						local cl = left + ol
						local ct = top + ot

						-- If the note is onscreen in this chunk, display it
						if collisionCheck(left, top, xfull, yfull, cl, ct, xwidth, data.cellheight) then

							-- If the note's leftmost boundary falls outside of frame,
							-- clip its left-position, and its width to match.
							if cl < left then
								xwidth = xwidth + ol
								cl = left
							end

							-- Add the note to the draw-table
							table.insert(notes, {render, seq, vv, cl, ct, xwidth, data.cellheight})

						end

					end
				end

			end
		end

		return notes

	end,

}
