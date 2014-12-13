
return {

	-- If a note is on either of the pointer axes,
	-- apply highlights to its note and border colors.
	applyNoteHighlight = function(n, c1, c2)

		local nindex = n[D.acceptmidi[n[1]][1]]
		local linecolor = deepCopy(D.color.note.border)
		local highlight = D.color.note.highlight

		-- If the note is on both axes, highlight it distinctly
		if ((n[2] + 1) == D.tp) and (nindex == D.np) then

			c1, c2 = mixColors(c1, highlight, 0.6), mixColors(c2, highlight, 0.6)
			linecolor = deepCopy(D.color.note.lightborder)

		-- Else if the note is on one axis, highlight it moderately
		elseif (n.tick == D.tp) or (nindex == D.np) then

			c1, c2 = mixColors(c1, highlight, 0.25), mixColors(c2, highlight, 0.25)
			linecolor = deepCopy(D.color.note.adjborder)

		end

		return c1, c2, linecolor

	end,

	-- Sort two items based first upon channel, and second upon tick position
	drawChanTickSort = function(a, b)
		if a[3][4] == b[3][4] then
			return a[3][2] < b[3][2]
		else
			return a[3][4] > b[3][4]
		end
	end,

	-- Draw a given table of render-notes
	drawNoteTable = function(notes)

		local c1, c2, linecolor = {}, {}, {}

		local fontheight = D.font.note.raster:getHeight()
		love.graphics.setFont(D.font.note.raster)

		-- If Cmd Mode is active, set all the active seq's NOTE commands to Shadow Mode
		if D.cmdmode == "cmd" then
			for i = 1, #notes do
				if notes[i][3][1] == 'note' then
					if notes[i][2] == D.active then
						notes[i][1] = 'other-chan'
					end
				end
			end
		else -- If Cmd Mode is inactive, de-prioritize the rendering of all non-NOTE commands
			for i = #notes, 1, -1 do
				if notes[i][3][1] ~= 'note' then
					notes[i][1] = 'cmd-shadow'
				end
			end
		end

		-- Seperate notes into tables, which will be used to divide render ordering
		local shadownotes = {}
		local cmdnotes = {}
		local sbordernotes = {}
		local sbselectnotes = {}
		local othernotes = {}
		for _, v in pairs(notes) do
			if v[1] == 'cmd-shadow' then
				table.insert(cmdnotes, v)
			elseif v[1] == 'shadow' then
				table.insert(shadownotes, v)
			elseif v[1] == 'other-chan' then
				table.insert(sbordernotes, v)
			elseif v[1] == 'other-chan-select' then
				table.insert(sbselectnotes, v)
			else
				table.insert(othernotes, v)
			end
		end

		-- Sort notes by channel and tick position
		table.sort(shadownotes, drawChanTickSort)
		table.sort(cmdnotes, drawChanTickSort)
		table.sort(sbordernotes, drawChanTickSort)
		table.sort(sbselectnotes, drawChanTickSort)
		table.sort(othernotes, drawChanTickSort)

		-- Recombine the sorted tables, to render them in the order of:
		-- shadow, other-chan, shadow-select, other.
		notes = tableCombine(cmdnotes, shadownotes)
		notes = tableCombine(notes, sbordernotes)
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
				c1 = deepCopy(D.color.note.overlay_quiet)
				c2 = deepCopy(D.color.note.overlay_loud)
			elseif kind == 'cmd-shadow' then
				c1 = deepCopy(D.color.note.cmd_bg1)
				c2 = deepCopy(D.color.note.cmd_bg2)
			elseif kind == 'select' then
				c1 = deepCopy(D.color.note.select_quiet)
				c2 = deepCopy(D.color.note.select_loud)
			elseif kind == 'other-chan-select' then
				c1 = deepCopy(D.color.note.overlay_select_quiet)
				c2 = deepCopy(D.color.note.overlay_select_loud)
			else
				c1 = deepCopy(D.color.note.quiet)
				c2 = deepCopy(D.color.note.loud)
			end

			-- Highlight note-colors for notes on the tp/np axes
			if (D.cmdmode ~= 'cmd') and (n[1] == 'note') then
				c1, c2, linecolor = applyNoteHighlight(n, c1, c2)
			else
				c1 = deepCopy(D.color.note.cmd_bg1)
				c2 = deepCopy(D.color.note.cmd_bg2)
				linecolor = deepCopy(D.color.note.cmd_border)
			end

			-- Get the note's velocity-color
			local notecolor = getVelocityColor(n, c1, c2)

			-- Draw the note-rectangle
			love.graphics.setColor(notecolor)
			love.graphics.rectangle("fill", nleft, ntop, nx, ny)

			-- If the note isn't to be rendered in shadow mode...
			if kind ~= 'shadow' then

				-- If the note isn't other-chan, or cmd in non-cmd-mode, then draw a border around the note
				if (kind ~= 'other-chan')
				and (not ((D.cmdmode ~= 'cmd') and (kind == 'cmd-shadow')))
				then
					love.graphics.setColor(linecolor)
					love.graphics.rectangle("line", nleft, ntop, nx, ny)
				end

				-- Draw the note's velocity-bar
				local barcomp = getVelocityColor(
					n,
					D.color.note.bar_quiet,
					D.color.note.bar_loud
				)
				local bartop = ny - (ny * (n[D.acceptmidi[n[1]][2]] / D.bounds.velo[2]))
				love.graphics.setColor(barcomp)
				love.graphics.line(
					nleft, ntop + bartop,
					nleft + nx, ntop + bartop
				)

				-- If chanview mode is enabled, print the note's channel number.
				if D.chanview and (n[1] == 'note') then

					local notename = tostring(n[4])
					local textleft = (nleft + (nx / 2)) - (D.font.note.raster:getWidth(tostring(n[4])) / 2)
					local texttop = (ntop + (ny / 2)) - (fontheight / 2)

					-- Draw the text's shadow
					love.graphics.setColor(D.color.font.note_shadow)
					love.graphics.print(notename, textleft, texttop - 1)
					love.graphics.print(notename, textleft, texttop + 1)
					love.graphics.print(notename, textleft - 1, texttop)
					love.graphics.print(notename, textleft + 1, texttop)

					-- Draw the text itself
					love.graphics.setColor(barcomp)
					love.graphics.print(notename, textleft, texttop)

				elseif (D.cmdmode == "cmd") and ((n[2] + 1) == D.tp) then

					local outstr = ""
					for ck, cv in pairs(D.cmdtypes) do
						if cv[3] == n[1] then
							outstr = cv[2]
							break
						end
					end
					outstr = outstr .. " " .. n[3]
					if n[4] ~= nil then
						outstr = outstr .. " " .. n[4]
						if n[5] ~= nil then
							outstr = outstr .. " " .. n[5]
						end
					end

					love.graphics.setColor(D.color.font.cmd_shadow)
					love.graphics.rectangle(
						"fill",
						nleft - 1,
						(ntop + (ny / 2)) - (fontheight / 2),
						D.font.note.raster:getWidth(outstr) + 1,
						D.font.note.raster:getHeight()
					)

					love.graphics.setColor(D.color.font.cmd)
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

		local veloval = n[D.acceptmidi[n[1]][2]]
		local velomap = veloval / D.bounds.velo[2]
		local velorev = (D.bounds.velo[2] - veloval) / D.bounds.velo[2]

		return mixColors(c2, c1, velorev)

	end,

	-- Build a render-table for a given sequence of notes, wrapped to the screen
	makeNoteRenderTable = function(
		kind,
		seq, ntab,
		left, top,
		xfull, yfull,
		xranges, yranges
	)

		local notes = {}
		local tally = {}
		local cmdtally = {}

		for _, two in pairs(ntab) do

			local hist, n = unpack(two)

			-- Get the pitch-value, or pitch-corresponding value, of a given note
			local vp = n[D.acceptmidi[n[1]][1]]

			-- Duplicate the kind-of-note val, in case of changes
			local render = kind

			-- Pick out selected notes, and other-chan notes, from within normal notes
			if kind ~= 'shadow' then

				-- If the note is within the select-table, set it to render as selected
				if getIndex(D.seldat, {n[2] + 1, n[4], n[5]}) then
					render = 'select'
				end

				-- If the note isn't on the active channel...
				if (n[1] == 'note')
				and (n[4] ~= D.chan)
				then

					-- If the note is selected, render as other-chan-select.
					if render == 'select' then
						render = 'other-chan-select'
					else -- If the note isn't selected, render as other-chan.
						render = 'other-chan'
					end

				end

			end

			if n[1] == 'note' then
				tally[n[2] + 1] = (tally[n[2] + 1] and (tally[n[2] + 1] + 1)) or 0
			else
				cmdtally[n[2] + 1] = (cmdtally[n[2] + 1] and (cmdtally[n[2] + 1] + 1)) or 0
			end

			-- For every combination of on-screen X-ranges and Y-ranges,
			-- check the note's visibility there, and render if visible.
			for _, xr in pairs(xranges) do
				for _, yr in pairs(yranges) do

					-- Get note's width, via duration, or default to 1 for non-note cmds
					local xwidth = ((n[1] == 'note') and (D.cellwidth * n[3])) or D.cellwidth

					-- Get note's inner-grid-concrete and absolute left offsets
					local ol = xr.a + (n[2] * D.cellwidth)
					local cl = left + ol
					local ot

					-- If Cmd Mode is active, render the note with a "stacked" top-offset
					if D.cmdmode == 'cmd' then
						if n[1] == 'note' then
							ot = yr.b + ((tally[n[2] + 1] + 1) * D.cellheight)
						else
							ot = yr.b - (((cmdtally[n[2] + 1] + 1) - D.cmdp) * D.cellheight)
						end
					else -- Else, render the note with a "wrapping grid" top-offset
						if n[1] == 'note' then
							ot = yr.b - ((vp - yr.o) * D.cellheight)
						else
							ot = yr.b - ((tally[n[2] + 1] + D.np - yr.o) * D.cellheight)
						end
					end
					local ct = top + ot

					-- If the note is onscreen in this chunk, display it
					if collisionCheck(left, top, xfull, yfull, cl, ct, xwidth, D.cellheight) then

						-- If the note's leftmost boundary falls outside of frame,
						-- clip its left-position, and its width to match.
						if cl < left then
							xwidth = xwidth + ol
							cl = left
						end

						-- Add the note to the draw-table
						table.insert(notes, {render, seq, n, cl, ct, xwidth, D.cellheight})

					end

				end
			end

		end

		return notes

	end,

}
