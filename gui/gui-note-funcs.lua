
return {

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

		for _, v in ipairs(D.gui.seq.note) do -- For every note in the render-table...

			local ncolor, tcolor, text, n, nleft, ntop, nwidth, tleft, ttop, border = unpack(v)

			-- Draw the note-rectangle
			love.graphics.setColor(ncolor)
			love.graphics.rectangle("fill", nleft, ntop, nwidth, D.cellheight)

			if border then -- If a border exists, draw it
				love.graphics.setColor(D.color.note.border)
				love.graphics.rectangle("line", nleft, ntop, nwidth, D.cellheight)
			end

			if text then -- If text exists, draw it
				love.graphics.setColor(D.color.note.text)
				love.graphics.print(text, tleft, ttop)
			end

		end

	end,

	-- Build a table of GUI-notes
	buildNoteTable = function()

		D.gui.seq.note = {} -- Empty out old render-notes

		local left = D.c.sqleft
		local top = D.c.sqtop
		local right = left + D.c.sqwidth
		local width = D.c.sqwidth
		local height = D.c.sqheight

		local fontheight = D.font.note.raster:getHeight()

		-- Get all notes' height and text-top-positions
		local nheight = D.cellheight
		local tyoffset = (nheight - fontheight) / 2

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

					-- Get the note's start-position in 1-indexed format
					local nplus = n[2] + 1

					-- Duplicate the kind-of-note val, in case of changes
					local render = kind

					local color
					local border = false
					local text = false

					-- Pick out selected notes, and other-chan notes, from within normal notes
					if kind ~= 'shadow' then
						if getIndex(D.seldat, {n[2] + 1, n[4], n[5]}) then -- If the note is selected, set it to render as such
							render = 'sel'
						end
						if n[1] == 'note' then -- If the note is a NOTE...
							if n[4] ~= D.chan then -- If the note isn't on the active channel...
								if render == 'sel' then -- If the note is selected, render as other-chan-select.
									render = 'other_chan_select'
								else -- If the note isn't selected, render as other-chan.
									render = 'other_chan'
								end
							end
						end
					end

					if D.cmdmode == "cmd" then -- If Cmd Mode is active, set NOTE-render type to Shadow Mode
						if n[1] == 'note' then
							render = 'shadow'
						end
					else -- If Cmd Mode is inactive, de-prioritize the rendering of all non-NOTE commands
						if n[1] ~= 'note' then
							render = 'cmd_shadow'
						end
					end

					-- Get note's width
					local nwidth = ((n[1] == 'note') and (D.cellwidth * n[3])) or D.cellwidth

					if n[1] == 'note' then -- If the note is a NOTE...

						if D.chanview then -- If chan-view is toggled, set the text to the note's channel
							text = tostring(n[4])
						end

						if nplus == D.tp then -- If the note starts on the active tick, highlight it
							render = "highlight"
						end

						-- Get a shade of gradient-color based on the note's velocity
						color = D.color.note[render .. "_gradient"][math.floor(n[6] / 8)]
						border = true -- Set the note's border-rendering to true

						-- Count an offset-tally for notes in cmd-mode, or cmds in note-mode
						tally[nplus] = (tally[nplus] and (tally[nplus] + 1)) or 0

					else -- Else, if the note isn't a NOTE...

						if D.chanview then -- If chan-view is toggled, set the text to the note's channel
							if nplus == D.tp then -- If cmd is on active tick, expand its contents
								for _, cv in pairs(D.cmdtypes) do
									if cv[3] == n[1] then
										text = cv[2]
										break
									end
								end
								text = table.concat({n[3], text, n[4] or nil, n[5] or nil}, ",")
								nwidth = D.font.note.raster:getWidth(text) -- Replace note-width with text-width
							else -- Else, leave contents collapsed to chan-number
								text = tostring(n[3])
							end
						end

						-- Set the color plainly, to a non-gradient render-type
						color = D.color.note[render]

						-- Count an offset-tally for cmds in cmd-mode
						cmdtally[nplus] = (cmdtally[nplus] and (cmdtally[nplus] + 1)) or 0

					end

					-- Get note's text-width and text-X-offset
					local twidth = D.font.note.raster:getWidth(text)
					local txoffset = text and ((nwidth - twidth) / 2)

					-- For every combination of on-screen X-ranges and Y-ranges,
					-- check the note's visibility there, and render if visible.
					for _, xr in pairs(tempxr) do
						for _, yr in pairs(yranges) do

							-- Get note's inner-grid-concrete and absolute left offsets
							local cl = left + xr.a + (n[2] * D.cellwidth)
							local ct
							if D.cmdmode == 'cmd' then -- If Cmd Mode is active...
								if n[1] == 'note' then -- Render notes with a "down-stacked" top-offset
									ct = yr.b + ((tally[nplus] + 1) * D.cellheight)
								else -- Render cmds with an "up-stacked" top-offset
									ct = yr.b - (((cmdtally[nplus] + 1) - D.cmdp) * D.cellheight)
								end
							else -- Else, if Cmd Mode is inactive...
								if n[1] == 'note' then -- Render notes with a "wrapping-grid" top-offset
									ct = yr.b - ((vp - yr.o) * D.cellheight)
								else -- Render cmds with an "up-stacked" top offset
									ct = yr.b - ((tally[nplus] + D.np - yr.o) * D.cellheight)
								end
							end
							ct = top + ct

							-- If the note is onscreen in this chunk, display it
							if collisionCheck(left, top, width, height, cl, ct, nwidth, D.cellheight) then

								local otext = text

								-- If text goes beyond the seq-panel border, remove it
								if text then
									if ((cl + txoffset) < left)
									or ((cl + txoffset + twidth) > right)
									then
										otext = false
									end
								end

								-- If the note's X-boundary falls outside of frame, clip its left-position and/or width.
								if cl < left then
									local diff = left - cl
									nwidth = nwidth - diff
									cl = left
								elseif (cl + nwidth) > right then
									local diff = cl - right
									nwidth = right - cl
									txoffset = otext and (txoffset - (diff / 2))
								end

								print(cl)--debugging

								-- If note has text, get note-text position
								local tleft = otext and (cl + txoffset)
								local ttop = otext and (ct + tyoffset)

								-- Add the note to the meta-notes-table, to be sorted and combined later
								local onote = {color, text and D.color.note[render .. "_text"], otext, n, cl, ct, nwidth, tleft, ttop, border}
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

	end,

}
