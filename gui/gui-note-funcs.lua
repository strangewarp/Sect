
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

		-- If Cmd Mode is active, set all the active seq's NOTE commands to Shadow Mode
		if data.cmdmode == "cmd" then
			for i = 1, #notes do
				if notes[i][3].note[1] == 'note' then
					if notes[i][2] == data.active then
						notes[i][1] = "other-chan"
					end
				end
			end
		else -- If Cmd Mode is inactive, remove all non-NOTE commands from rendering
			for i = #notes, 1, -1 do
				if notes[i][3].note[1] ~= 'note' then
					table.remove(notes, i)
				end
			end
		end

		-- Seperate notes into tables, which will be used to divide render ordering
		local shadownotes = {}
		local sbordernotes = {}
		local sbselectnotes = {}
		local othernotes = {}
		for _, v in pairs(notes) do
			if v[1] == 'shadow' then
				table.insert(shadownotes, v)
			elseif v[1] == 'other-chan' then
				table.insert(sbordernotes, v)
			elseif v[1] == 'other-chan-select' then
				table.insert(sbselectnotes, v)
			else
				table.insert(othernotes, v)
			end
		end

		-- Sort notes by tick position
		table.sort(shadownotes, function(a, b) return a[3].tick < b[3].tick end)
		table.sort(sbordernotes, function(a, b) return a[3].tick < b[3].tick end)
		table.sort(sbselectnotes, function(a, b) return a[3].tick < b[3].tick end)
		table.sort(othernotes, function(a, b) return a[3].tick < b[3].tick end)

		-- Recombine the sorted tables, to render them in the order of:
		-- shadow, other-chan, shadow-select, other.
		notes = tableCombine(shadownotes, sbordernotes)
		notes = tableCombine(notes, sbselectnotes)
		notes = tableCombine(notes, othernotes)

		-- For every note in the render-table...
		for k, v in pairs(notes) do

			-- Unpack the note-vars and render-vars
			local kind, seq, n, nleft, ntop, nx, ny = unpack(v)
			local nxhalf = nx / 2
			local nyhalf = ny / 2

			-- Set quiet/loud colors differently, for shadow/select/active notes
			if (kind == 'shadow') or (kind == 'other-chan') then
				c1 = deepCopy(data.color.note.overlay_quiet)
				c2 = deepCopy(data.color.note.overlay_loud)
			elseif kind == 'select' then
				c1 = deepCopy(data.color.note.select_quiet)
				c2 = deepCopy(data.color.note.select_loud)
			elseif kind == 'other-chan-select' then
				c1 = deepCopy(data.color.note.overlay_select_quiet)
				c2 = deepCopy(data.color.note.overlay_select_loud)
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

			-- If the note isn't to be rendered in shadow mode...
			if kind ~= 'shadow' then

				-- If the note isn't other-chan, draw a border around the note
				if kind ~= 'other-chan' then
					love.graphics.setColor(linecolor)
					love.graphics.rectangle("line", nleft, ntop, nx, ny)
				end

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

				elseif (data.cmdmode == "cmd") and (n.tick == data.tp) then

					local outstr = ""
					for ck, cv in pairs(data.cmdtypes) do
						if cv[3] == n.note[1] then
							outstr = cv[2]
							break
						end
					end
					outstr = outstr .. " " .. n.note[4]
					if n.note[5] ~= nil then
						outstr = outstr .. " " .. n.note[5]
					end

					love.graphics.setColor(data.color.font.cmd_shadow)
					love.graphics.rectangle(
						"fill",
						nleft - 1,
						(ntop + (ny / 2)) - (fontheight / 2),
						data.font.note.raster:getWidth(outstr) + 1,
						data.font.note.raster:getHeight()
					)

					love.graphics.setColor(data.color.font.cmd)
					love.graphics.print(
						outstr,
						nleft,
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

			for kk, vv in ipairs(v) do

				-- Get the pitch-value, or pitch-corresponding value, of a given note
				local vp = vv.note[data.acceptmidi[vv.note[1]][1]]

				-- Duplicate the kind-of-note val, in case of changes
				local render = kind

				-- Pick out selected notes, and other-chan notes, from within normal notes
				if kind ~= 'shadow' then

					-- If the note is within the select-tables, set it to render as selected
					if (data.selindex[vv.tick] ~= nil)
					and (data.selindex[vv.tick][vp] == true)
					then
						render = 'select'
					end

					-- If the note isn't on the active channel...
					if (vv.note[1] == 'note')
					and (vv.note[4] ~= data.chan)
					then

						-- If the note is selected, render as other-chan-select.
						if render == 'select' then
							render = 'other-chan-select'
						else -- If the note isn't selected, render as other-chan.
							render = 'other-chan'
						end

					end

				end

				-- For every combination of on-screen X-ranges and Y-ranges,
				-- check the note's visibility there, and render if visible.
				for _, xr in pairs(xranges) do
					for _, yr in pairs(yranges) do

						-- Get note's width, via duration, or default to 1 for non-note cmds
						local xwidth = ((vv.note[1] == 'note') and (data.cellwidth * vv.note[3])) or data.cellwidth

						-- Get note's inner-grid-concrete and absolute left offsets
						local ol = xr.a + ((vv.tick - 1) * data.cellwidth)
						local cl = left + ol
						local ot

						-- If Cmd Mode is active, render the note with a "stacked" top-offset
						if data.cmdmode == "cmd" then
							ot = yr.b - (data.cellheight * (data.cmdp - kk))
						else -- Else, render the note with a "wrapping grid" top-offset
							ot = yr.b - ((vp - yr.o) * data.cellheight)
						end
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
