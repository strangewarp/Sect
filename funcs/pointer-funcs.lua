return {
	
	-- Normalize all pointers (e.g. after a command that changes seq length)
	normalizePointers = function()
	
		local tlimit = (data.active and #data.seq[data.active].tick) or 1

		-- Normalize tick and note pointers
		data.tp = (rangeCheck(data.tp, 1, tlimit) and data.tp) or 1
		data.np = (rangeCheck(data.np, data.bounds.np) and data.np) or 1

		-- Normalize Cmd Mode pointer
		if data.active and (data.cmdmode == 'cmd') then
			data.cmdp = (rangeCheck(data.cmdp, 1, #data.seq[data.active].tick[data.tp]) and data.cmdp) or 1
		end

		-- Normalize selection-pointers
		if data.sel.l ~= false then
			data.seltop.x = math.min(data.seltop.x, tlimit)
			data.selbot.x = math.min(data.selbot.x, tlimit)
			data.sel.l = data.seltop.x
			data.sel.r = data.selbot.x
		end

		-- Turn off Play Mode if all sequences have been removed
		if not data.active then
			data.playing = false
		end

	end,

	-- Move the Cmd Mode command-pointer to an adjacent note on the active tick
	moveCmdPointer = function(dist)

		-- If no sequences are loaded, abort the function
		if data.active == false then
			print("moveCmdPointer: warning: no active sequence!")
			return nil
		end

		data.cmdp = wrapNum(data.cmdp + dist, 1, math.max(1, #data.seq[data.active].tick[data.tp]))

		print("moveCmdPointer: active command: " .. data.cmdp)

	end,

	-- Move the tick pointer, based on spacing, bounded to the current seq's ticks
	moveTickPointer = function(dist)

		-- If no sequences are loaded, abort the function
		if data.active == false then
			print("moveTickPointer: warning: no active sequence!")
			return nil
		end

		data.tp = wrapNum(data.tp + (dist * data.spacing), 1, #data.seq[data.active].tick)

		print("moveTickPointer: moved to tick " .. data.tp)

	end,

	-- Move the tick pointer to a beat-tick, in the given direction
	moveTickPointerToBeat = function(dist)

		-- If no sequences are loaded, abort the function
		if data.active == false then
			print("moveTickPointerToBeat: warning: no active sequence!")
			return nil
		end

		local oldpos, pos = data.tp, data.tp
		local dir = math.max(-1, math.min(1, dist))

		-- Shift the position in the given dist's direction (negative/positive),
		-- until it reaches a beat-position,
		-- for a number of repetitions equal to the given dist's absoute value.
		repeat
			repeat
				pos = wrapNum(pos + dir, 1, #data.seq[data.active].tick)
			until ((pos - 1) % (data.tpq * 4)) == 0
			dist = dist - dir
		until dist == 0

		-- Put the new tick-value into the tick-pointer.
		data.tp = pos

		print("moveTickPointerToBeat: moved from tick " .. oldpos .. " to " .. pos)

	end,

	-- Move the tick and note pointers to an adjacent note, in the given direction
	moveTickPointerByNote = function(dist)

		-- If no sequences are loaded, abort the function
		if data.active == false then
			return nil
		end

		local tick = data.tp
		local note = data.np

		local ticks = #data.seq[data.active].tick
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
			tick = wrapNum(data.tp + offset, 1, ticks)

			-- Populate the lower-notes and higher-notes tabs, based on the tick's notes
			local ntab = getContents(data.seq[data.active].tick[tick], {"note", pairs, pairs})
			for _, n in pairs(n) do
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
				note = data.bounds.np[clampNum(dist, 0, 1) + 1] + dir
			else
				passed = passed + 1
			end

			-- Keep counting the number of loops
			loops = loops + 1

		end

		-- If the note-val is still in a pre-notes-found state, reset it
		if not rangeCheck(note, data.bounds.np) then
			note = data.np
		end

		-- Update global tick and note pointers with new positions
		data.tp = tick
		data.np = note

	end,

	-- Shift the Cmd Mode command-type pointer, bounded to the number of possible commands
	shiftCmdType = function(dist)

		data.cmdtype = wrapNum(data.cmdtype + dist, 1, #data.cmdtypes)

		print("shiftCmdType: command " .. data.cmdtype .. ": " .. table.concat(data.cmdtypes[data.cmdtype], " "))

	end,

	-- Shift an internal bounded value, additively or multiplicatively, by a given distance
	shiftInternalValue = function(vname, multi, dist, emptyabort)

		local bds = data.bounds[vname]

		-- Add or multiply the value with the internal var (and round off floats)
		data[vname] = (multi and math.floor(data[vname] * dist)) or (data[vname] + dist)

		-- Wrap or clamp the value to a given range
		data[vname] = (bds[3] and wrapNum(data[vname], bds)) or clampNum(data[vname], bds)

		print("shiftInternalValue: " .. vname .. " to " .. data[vname])

	end,

	-- Tab the hotseat-pointer to a given hotseat
	tabToHotseat = function(seat)
		data.activeseat = seat
	end,

}