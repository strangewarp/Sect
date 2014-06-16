return {
	
	-- Normalize all pointers (e.g. after a command that changes seq length)
	normalizePointers = function()
	
		-- If no sequences are loaded, do nothing
		if not data.active then
			return false
		end

		local tlimit = #data.seq[data.active].tick

		-- Normalize tick and note pointers
		data.tp = clampNum(data.tp, 1, tlimit)
		data.np = clampNum(data.np, data.bounds.np)

		-- Normalize selection-pointers
		if data.sel.l ~= false then
			data.seltop.x = math.min(data.seltop.x, tlimit)
			data.selbot.x = math.min(data.selbot.x, tlimit)
			data.sel.l = data.seltop.x
			data.sel.r = data.selbot.x
		end

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

	-- Shift an internal bounded value, additively or multiplicatively, by a given distance
	shiftInternalValue = function(vname, multi, dist)

		-- If no sequences are loaded, abort the function
		if data.active == false then
			print("shiftInternalValue: warning: no active sequence!")
			return nil
		end

		local bds = data.bounds[vname]

		-- Add or multiply the value with the internal var (and round off floats)
		data[vname] = (multi and roundNum(data[vname] * dist, 0)) or (data[vname] + dist)

		-- Wrap or clamp the value to a given range
		data[vname] = (bds[3] and wrapNum(data[vname], bds)) or clampNum(data[vname], bds)

		print("shiftInternalValue: " .. vname .. " to " .. data[vname])

	end,

}