
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

		-- If linecolor was not given, keep a note of that
		local line = not (linecolor == nil)

		-- For every note in the render-table...
		for k, v in pairs(notes) do

			-- Unpack the note-vars and render-vars
			local kind, n, nleft, ntop, nx, ny = unpack(v)

			-- Set quiet/loud colors differently, for shadow and active notes
			if kind == 'shadow' then
				c1 = deepCopy(data.color.note.overlay_quiet)
				c2 = deepCopy(data.color.note.overlay_loud)
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

			-- If a linecolor was given, draw a border around the note
			if kind == 'active' then
				love.graphics.setColor(linecolor)
				love.graphics.rectangle("line", nleft, ntop, nx, ny)
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
		n, kind,
		left, top,
		xfull, yfull,
		cellwidth, cellheight,
		xranges, yranges
	)

		local notes = {}

		for k, v in pairs(n) do
			for kk, vv in pairs(v) do

				-- Get the pitch-value, or pitch-corresponding value, of a given note
				local vp = vv.note[data.acceptmidi[vv.note[1]][1]]

				-- Get note's width, via duration, or default to 1 for non-note cmds
				local xwidth = ((vv.note[1] == 'note') and (cellwidth * vv.note[3])) or cellwidth

				-- For every combination of on-screen X-ranges and Y-ranges,
				-- check the note's visibility there, and render if visible.
				for _, xr in pairs(xranges) do
					for _, yr in pairs(yranges) do

						-- Get note's inner-grid-concrete and absolute left and top offsets
						local ol = xr.a + ((vv.tick - 1) * cellwidth)
						local ot = yr.b - ((vp - yr.o) * cellheight)
						local cl = left + ol
						local ct = top + ot

						-- If the note is onscreen in this chunk, display it
						if collisionCheck(left, top, xfull, yfull, cl, ct, xwidth, cellheight) then

							-- If the note's leftmost boundary falls outside of frame,
							-- clip its left-position, and its width to match.
							if cl < left then
								xwidth = xwidth - (left - cl)
								cl = left
							end

							-- Add the note to the draw-table
							table.insert(notes, {kind, vv, cl, ct, xwidth, cellheight})

						end

					end
				end

			end
		end

		return notes

	end,

}
