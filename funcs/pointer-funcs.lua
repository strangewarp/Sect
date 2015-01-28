return {
	
	-- Normalize all pointers (e.g. after a command that changes seq length)
	normalizePointers = function()
	
		local tlimit = (D.active and D.seq[D.active].total) or 1

		-- Normalize tick and note pointers
		D.tp = (rangeCheck(D.tp, 1, tlimit) and D.tp) or 1
		D.np = (rangeCheck(D.np, D.bounds.np) and D.np) or 1

		-- Normalize Cmd Mode pointer
		if D.active and (D.cmdmode == 'cmd') then
			local allcmds = getContents(D.seq[D.active].tick, {D.tp, 'cmd', pairs})
			D.cmdp = (rangeCheck(D.cmdp, 1, #allcmds) and D.cmdp) or 1
		end

		-- Normalize selection-pointers
		if D.sel.l ~= false then
			D.seltop.x = math.min(D.seltop.x, tlimit)
			D.selbot.x = math.min(D.selbot.x, tlimit)
			D.sel.l = D.seltop.x
			D.sel.r = D.selbot.x
		end

		-- Turn off Play Mode if all sequences have been removed
		if not D.active then
			D.playing = false
		end

	end,

	-- Move the Cmd Mode command-pointer to an adjacent note on the active tick
	moveCmdPointer = function(dist)

		-- If no sequences are loaded, abort the function
		if D.active == false then
			print("moveCmdPointer: warning: no active sequence!")
			return nil
		end

		local allcmds = getContents(D.seq[D.active].tick, {D.tp, "cmd", pairs})

		D.cmdp = wrapNum(D.cmdp + dist, 1, math.max(1, #allcmds))

		print("moveCmdPointer: active command: " .. D.cmdp)

	end,

	-- Move the tick pointer, based on spacing, bounded to the current seq's ticks
	moveTickPointer = function(dist)

		-- If no sequences are loaded, abort the function
		if D.active == false then
			print("moveTickPointer: warning: no active sequence!")
			return nil
		end

		D.tp = wrapNum(D.tp + (dist * D.spacing), 1, D.seq[D.active].total)

		print("moveTickPointer: moved to tick " .. D.tp)

	end,

	-- Move the tick pointer to a beat-tick, in the given direction
	moveTickPointerToBeat = function(dist)

		-- If no sequences are loaded, abort the function
		if D.active == false then
			print("moveTickPointerToBeat: warning: no active sequence!")
			return nil
		end

		local oldpos, pos = D.tp, D.tp
		local dir = math.max(-1, math.min(1, dist))

		-- Shift the position in the given dist's direction (negative/positive),
		-- until it reaches a beat-position,
		-- for a number of repetitions equal to the given dist's absoute value.
		repeat
			repeat
				pos = wrapNum(pos + dir, 1, D.seq[D.active].total)
			until ((pos - 1) % (D.tpq * 4)) == 0
			dist = dist - dir
		until dist == 0

		-- Put the new tick-value into the tick-pointer.
		D.tp = pos

		print("moveTickPointerToBeat: moved from tick " .. oldpos .. " to " .. pos)

	end,

	-- Move the tick and note pointers to an adjacent note, in the given direction
	moveTickPointerByNote = function(dist)

		-- If no sequences are loaded, abort the function
		if D.active == false then
			return nil
		end

		local tick = D.tp
		local note = D.np

		local ticks = D.seq[D.active].total
		local dir = math.max(-1, math.min(1, dist)) 
		local goal = math.abs(dist)

		-- While fewer notes have been passed than the distance-goal,
		-- and fewer loops have been made than there are ticks in the active seq,
		-- continue looking for more notes.
		local offset = 0
		local loops = 0
		local passed = 0
		while (loops <= ticks) and (passed < goal) do

			local higher, lower = {}, {}
			local found = false

			-- Get the current offset-tick
			tick = wrapNum(D.tp + offset, 1, ticks)

			-- Populate the lower-notes and higher-notes tabs, based on the tick's notes
			local ntab = getContents(D.seq[D.active].tick, {tick, "note", pairs, pairs})
			for _, n in pairs(ntab) do
				if n[5] < note then
					table.insert(lower, n[5])
				elseif n[5] > note then
					table.insert(higher, n[5])
				end
			end

			-- Get the next-closest note in the given direction
			if dir == 1 then
				if #lower > 0 then
					table.sort(lower)
					note = lower[#lower]
					found = true
				end
			else
				if #higher > 0 then
					table.sort(higher)
					note = higher[1]
					found = true
				end
			end

			-- If a note wasn't found in the given direction in the current tick,
			-- change the tick-offset, and set note-val just outside the range.
			if not found then
				offset = offset + dir
				note = D.bounds.np[clampNum(dist, 0, 1) + 1] + dir
			else
				passed = passed + 1
			end

			-- Keep counting the number of loops
			loops = loops + 1

		end

		-- If the note-val is still in a pre-notes-found state, reset it
		if not rangeCheck(note, D.bounds.np) then
			note = D.np
		end

		-- Update global tick and note pointers with new positions
		D.tp = tick
		D.np = note

	end,

	-- Move tick-pointer to top of sequence
	moveTickPointerToTop = function()
		D.tp = 1
	end,

	-- Move tick-pointer to opposite side of sequence
	moveTickPointerOpposite = function()
		local total = D.seq[D.active].total
		D.tp = wrapNum(D.tp + roundNum(total / 2, 0), 1, total)
	end,

	-- Shift the Cmd Mode command-type pointer, bounded to the number of possible commands
	shiftCmdType = function(dist)

		D.cmdtype = wrapNum(D.cmdtype + dist, 1, #D.cmdtypes)

		print("shiftCmdType: command " .. D.cmdtype .. ": " .. table.concat(D.cmdtypes[D.cmdtype], " "))

	end,

	-- Shift an internal bounded value, additively or multiplicatively, by a given distance
	shiftInternalValue = function(vname, multi, dist, emptyabort)

		local bds = D.bounds[vname]

		-- Add or multiply the value with the internal var (and round off floats)
		D[vname] = (multi and math.floor(D[vname] * dist)) or (D[vname] + dist)

		-- Wrap or clamp the value to a given range
		D[vname] = (bds[3] and wrapNum(D[vname], bds)) or clampNum(D[vname], bds)

		print("shiftInternalValue: " .. vname .. " to " .. D[vname])

	end,

	-- Tab the hotseat-pointer to a given hotseat
	tabToHotseat = function(seat)
		D.activeseat = seat
	end,

}