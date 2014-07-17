
return {

	-- Iterate through one step of the currently active tick	
	iteratePlayMode = function(dt)

		-- If there's no active sequence, abort function
		if not data.active then
			return nil
		end

		-- Get number of ticks in sequence
		local ticks = #data.seq[data.active].tick

		-- Adjust delta-time by remainder-time-offset from previous iteration
		local dtadj = data.playoffset + dt

		-- Get the number of steps contained in the adjusted delta-time
		local steps = roundNum(dtadj / data.updatespeed, 0)

		-- Get the remainder-time-offset for next iteration
		data.playoffset = dtadj - (data.updatespeed * steps)

		-- Get the current ideal update-speed
		data.updatespeed = 60 / (data.bpm * data.tpq * 4)

		-- Iterate through a "steps" number of ticks, if applicable
		if steps >= 1 then
			for i = 1, steps do

				-- For every sequence...
				for s, seq in pairs(data.seq) do

					-- If the seq is set as an overlay, or is the active seq...
					if seq.overlay or (s == data.active) then

						-- If the given tick in the given sequence exists,
						-- then send its notes to Extrovert via MIDI-over-OSC.
						if seq.tick[data.tp] ~= nil then
							for _, n in ipairs(seq.tick[data.tp]) do
								sendExtrovertNote(n.note)
							end
						end

					end

				end

				-- Increment the tick-pointer
				data.tp = wrapNum(data.tp + 1, 1, ticks)

			end
		end

	end,

}
