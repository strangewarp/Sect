
return {

	-- Sort two render-note items based first upon channel, and second upon tick position
	drawChanTickSort = function(a, b)
		if a[4][4] == b[4][4] then
			return a[4][2] < b[4][2]
		else
			return a[4][4] > b[4][4]
		end
	end,

	-- Check whether a given item is in the seq-panel, and add it to a given metaseq render-table
	checkOnScreen = function(metanotes, color, text, kind, render, border, n, cl, ct, nwidth, twidth, txoffset, tyoffset, otext, otxoffset)

		local left = D.c.sqleft
		local top = D.c.sqtop
		local width = D.c.sqwidth
		local height = D.c.sqheight

		-- If the note is onscreen in this chunk, display it
		if collisionCheck(left, top, width, height, cl, ct, nwidth, D.cellheight) then

			local otext = text
			local owidth = nwidth
			local otxoffset = txoffset

			-- If the note's X-boundary falls outside the left boundary, clip its left-position and width.
			if cl < 0 then
				owidth = owidth + cl
				if text then
					otxoffset = (owidth + twidth + cl) / 2
				end
				cl = 0
			end

			-- If text goes beyond the seq-panel border, remove it
			if text then
				if ((cl + otxoffset) < 0)
				or ((cl + otxoffset) > D.width)
				then
					otext = false
				end
			end

			-- If note has text, get note-text position
			local tleft = otext and (cl + otxoffset)
			local ttop = otext and (ct + tyoffset)

			-- Add the note to the meta-notes-table, to be sorted and combined later
			local onote = {color, text and D.color.note[render .. "_text"], otext, n, cl, ct, owidth, tleft, ttop, border}
			table.insert(metanotes[D.renderorder[kind]], onote)

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
		local width = D.c.sqwidth
		local height = D.c.sqheight
		local right = left + width

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
		local xranges = D.c.xwrap
		local yranges = D.c.ywrap

		-- Anchor-points for sequence-reticule
		local xanchor = D.c.xanchor
		local yanchor = D.c.yanchor

		local cyanchor = yanchor - D.c.ycellhalf

		local metanotes = {{},{},{},{}}

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
					tempxr = getTileAxisBounds(0, width, tboundary, D.cellwidth * s.total)
				end
			end

			-- If the sequence has a render-type...
			if kind then

				-- Get all notes from the relevant section of the active sequence
				local ntab = getContents(s.tick, {pairs, 'note', pairs, pairs}, false)
				local cmdtab = getContents(s.tick, {pairs, 'cmd', pairs}, false)
				ntab = tableCombine(ntab, cmdtab)

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

					-- If this isn't a shadow-note...
					if kind ~= 'shadow' then

						border = true

						-- If the note is selected, render it as such; else, if it's on another channel, render it as an other-chan-note
						if getIndex(D.seldat, {n[2] + 1, n[4], n[5]}) then
							render = 'sel'
						elseif (n[1] == 'note') and (n[4] ~= D.chan) then
							render = 'other_chan'
						end

						-- If the note-type is from the opposite mode, render it as shadow
						if ((D.cmdmode == 'cmd') and (n[1] == 'note'))
						or ((D.cmdmode ~= 'cmd') and (n[1] ~= 'note'))
						then
							render = 'shadow'
							border = false
						end

					end

					-- Get note's width
					local nwidth = ((n[1] == 'note') and (D.cellwidth * n[3])) or D.cellwidth

					if n[1] == 'note' then -- If the note is a NOTE...

						if D.chanview and (snum == D.active) then -- If chan-view is toggled, and this note is from the active-seq, set the text to the note's channel
							text = tostring(n[4])
						end

						if nplus == D.tp then -- If the note starts on the active tick, and is normal or other-chan, highlight it
							if (render == 'normal') or (render == 'other_chan') then
								render = "highlight"
							end
						end

						-- Get a shade of gradient-color based on the note's velocity
						color = D.color.note[render .. "_gradient"][math.floor(n[6] / 8)]

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
					local twidth = text and D.font.note.raster:getWidth(text)
					local txoffset = text and ((nwidth - twidth) / 2)

					-- For every on-screen X-range, check the note's visibility there, and render if visible.
					for _, xr in pairs(tempxr) do

						local cl = left + xr.a + (n[2] * D.cellwidth)
						local ct
						if D.cmdmode == 'cmd' then -- If Cmd Mode is active...
							if n[1] == 'note' then -- Render notes with a "down-stacked" top-offset
								ct = cyanchor + ((tally[nplus] + D.cmdp) * D.cellheight)
							else -- Render cmds with an "up-stacked" top-offset
								ct = cyanchor - (((cmdtally[nplus] + 1) - D.cmdp) * D.cellheight)
							end
							checkOnScreen(metanotes, color, text, kind, render, border, n, cl, ct, nwidth, twidth, txoffset, tyoffset, otext, otxoffset)
						else -- Else, if Cmd Mode is inactive...
							if n[1] ~= 'note' then -- Render cmds with a "down-stacked" top offset
								ct = cyanchor + ((cmdtally[nplus] + 1) * D.cellheight)
								checkOnScreen(metanotes, color, text, kind, render, border, n, cl, ct, nwidth, twidth, txoffset, tyoffset, otext, otxoffset)
							else -- If this is a note, then for every combination of on-screen X-ranges and Y-ranges, check note visibility and render.
								for _, yr in pairs(yranges) do
									if D.cmdmode ~= 'cmd' then -- Else, if Cmd Mode is inactive...
										if n[1] == 'note' then -- Render notes with a "wrapping-grid" top-offset
											ct = yr.b - ((vp - yr.o) * D.cellheight)
										end
									end
									ct = top + ct
									checkOnScreen(metanotes, color, text, kind, render, border, n, cl, ct, nwidth, twidth, txoffset, tyoffset, otext, otxoffset)
								end
							end
						end

					end

				end

			end

		end

		-- Sort the top 3 metanotes tables by channel and tick,
		-- and put all metanotes into the GUI-note table, for later rendering.
		for k, v in ipairs(metanotes) do
			if k ~= 1 then
				table.sort(v, drawChanTickSort)
			end
			for _, vv in ipairs(v) do
				table.insert(D.gui.seq.note, vv)
			end
		end

	end,

}
