
return {

	-- If a note is on either of the pointer axes,
	-- apply highlights to its note and border colors.
	applyNoteHighlight = function(n, c1, c2)

		-- TODO: Simplify and move into draw function

		local linecolor = deepCopy(D.color.note.border)
		local highlight = D.color.note.highlight

		if ((n[2] + 1) == D.tp) and (n[5] == D.np) then -- If the note is on both axes, highlight it distinctly
			c1 = D.color.note.highlight_bg_bright
			c2 = D.color.note.highlight_text_bright
			linecolor = D.color.note.highlight_border_bright
		elseif (n.tick == D.tp) or (n[5] == D.np) then -- Else if the note is on one axis, highlight it moderately
			c1 = D.color.note.highlight_bg
			c2 = D.color.note.highlight_text
			linecolor = D.color.note.highlight_border
		end

		return c1, c2, linecolor

	end,

	-- Sort two render-note items based first upon channel, and second upon tick position
	drawChanTickSort = function(a, b)
		if a[4][4] == b[4][4] then
			return a[4][2] < b[4][2]
		else
			return a[4][4] > b[4][4]
		end
	end,

	-- Draw a table of GUI notes
	drawNoteTable = function()

		love.graphics.setFont(D.font.note.raster)



	end,

	-- Build a table of GUI-notes
	buildNoteTable = function()

		D.gui.seq.note = {} -- Empty out old render-notes

		-- Left/top boundaries of sequence's current, non-wrapped chunk
		local tboundary = D.c.tboundary
		local nboundary = D.c.nboundary

		-- Sequence's full width and height, in pixels
		local fullwidth = D.c.fullwidth
		local fullheight = D.c.fullheight

		-- All boundaries for wrapping the sequence's display
		local xranges = deepCopy(D.c.xwrap)
		local yranges = deepCopy(D.c.ywrap)

		-- Anchor-points for sequence-reticule
		local xanchor = D.c.xanchor
		local yanchor = D.c.yanchor

		local metanotes = {{},{},{},{},{}}

		-- If Cmd Mode is active, use only one vertical render-range, and change getContents path type
		local path = {pairs, 'note', pairs, pairs} -- Path for note-table's getContents call
		if D.cmdmode == "cmd" then
			yranges = {{a = -math.huge, b = yanchor - ycellhalf, o = 0}}
			path = {pairs, 'cmd', pairs}
		end

		-- Get render-note data from all visible sequences
		for snum, s in pairs(D.seq) do

			local kind = false

			-- Assign kind type based on notedraw and shadow activity
			if D.drawnotes then
				if snum == D.active then
					kind = 'normal'
				elseif s.overlay then
					kind = 'shadow'
				end
			else
				if s.overlay then
					kind = 'shadow'
				end
			end

			-- If the shadow-seq is a different length than the active seq,
			-- wrap the shadow-seq onto the active-seq accordingly.
			local tempxr = deepCopy(xranges)
			if snum ~= D.active then
				if s.total ~= ticks then
					tempxr = getTileAxisBounds(0, xfull, tboundary, D.cellwidth * s.total)
				end
			end

			-- If the sequence has a render-type...
			if kind then

				-- Get all notes from the relevant section of the active sequence
				local ntab = getContents(s.tick, path, false)

				local tally, cmdtally = {}, {}

				for _, n in pairs(ntab) do

					-- Get the pitch-value, or pitch-corresponding value, of a given note
					local vp = n[D.acceptmidi[n[1]][1]]

					-- Duplicate the kind-of-note val, in case of changes
					local render = kind

					local color

					-- Pick out selected notes, and other-chan notes, from within normal notes
					if kind ~= 'shadow' then

						-- If the note is within the select-table, set it to render as selected
						if getIndex(D.seldat, {n[2] + 1, n[4], n[5]}) then
							render = 'select'
						end

						-- If the note isn't on the active channel...
						if (n[1] == 'note') and (n[4] ~= D.chan) then
							if render == 'select' then -- If the note is selected, render as other-chan-select.
								render = 'other_chan_select'
							else -- If the note isn't selected, render as other-chan.
								render = 'other_chan'
							end
						end

					end

					-- If Cmd Mode is active, set NOTE-render type to Shadow Mode
					if D.cmdmode == "cmd" then
						if n[1] == 'note' then
							render = 'shadow'
						end
					else -- If Cmd Mode is inactive, de-prioritize the rendering of all non-NOTE commands
						if n[1] ~= 'note' then
							render = 'cmd_shadow'
						end
					end

					if n[1] == 'note' then -- If the note is a NOTE...

						-- Get a shade of gradient-color based on the note's velocity
						color = D.color.note[render .. "_gradient"][math.floor(n[6] / 8)]

						-- Count an offset-tally for notes in cmd-mode, or cmds in note-mode
						tally[n[2] + 1] = (tally[n[2] + 1] and (tally[n[2] + 1] + 1)) or 0

					else -- Else, if the note isn't a NOTE...

						-- Set the color plainly, to a non-gradient render-type
						color = D.color.note[render]

						-- Count an offset-tally for cmds in cmd-mode
						cmdtally[n[2] + 1] = (cmdtally[n[2] + 1] and (cmdtally[n[2] + 1] + 1)) or 0

					end

					-- For every combination of on-screen X-ranges and Y-ranges,
					-- check the note's visibility there, and render if visible.
					for _, xr in pairs(tempxr) do
						for _, yr in pairs(yranges) do

							-- Get note's width, via duration, or default to 1 for non-note cmds
							local xwidth = ((n[1] == 'note') and (D.cellwidth * n[3])) or D.cellwidth

							-- Get note's inner-grid-concrete and absolute left offsets
							local ol = xr.a + (n[2] * D.cellwidth)
							local cl = left + ol
							local ot
							if D.cmdmode == 'cmd' then -- If Cmd Mode is active...
								if n[1] == 'note' then -- Render notes with a "down-stacked" top-offset
									ot = yr.b + ((tally[n[2] + 1] + 1) * D.cellheight)
								else -- Render cmds with an "up-stacked" top-offset
									ot = yr.b - (((cmdtally[n[2] + 1] + 1) - D.cmdp) * D.cellheight)
								end
							else -- Else, if Cmd Mode is inactive...
								if n[1] == 'note' then -- Render notes with a "wrapping-grid" top-offset
									ot = yr.b - ((vp - yr.o) * D.cellheight)
								else -- Render cmds with an "up-stacked" top offset
									ot = yr.b - ((tally[n[2] + 1] + D.np - yr.o) * D.cellheight)
								end
							end
							local ct = top + ot

							-- If the note is onscreen in this chunk, display it
							if collisionCheck(left, top, fullwidth, fullheight, cl, ct, xwidth, D.cellheight) then

								-- If the note's leftmost boundary falls outside of frame,
								-- clip its left-position, and its width to match.
								if cl < left then
									xwidth = xwidth + ol
									cl = left
								end

								-- Add the note to the meta-notes-table, to be sorted and combined later
								local onote = {color, text and D.color.note[render .. "_text"], text, n, cl, ct, xwidth}
								table.insert(metanotes[D.renderorder[kind]], onote)

							end

						end
					end

				end

			end

		end

		-- Sort the top 3 metanotes tables by channel and tick,
		-- and put all metanotes into the GUI-note table, for later rendering.
		for k, v in ipairs(metanotes) do
			if k >= 3 then
				table.sort(v, drawChanTickSort)
			end
			for _, vv in ipairs(v) do
				table.insert(D.gui.seq.note, vv)
			end
		end








		local c1, c2, linecolor = {}, {}, {}

		local fontheight = D.font.note.raster.height


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

}
