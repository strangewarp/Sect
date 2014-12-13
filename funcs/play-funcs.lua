
return {

	-- Iterate through one step of the currently active tick	
	iteratePlayMode = function(dt)

		-- If there's no active sequence, abort function
		if not D.active then
			return nil
		end

		-- Get number of ticks in sequence
		local ticks = D.seq[D.active].total

		-- Adjust delta-time by remainder-time-offset from previous iteration
		local dtadj = D.playoffset + dt

		-- Get the number of steps contained in the adjusted delta-time
		local steps = roundNum(dtadj / D.updatespeed, 0)

		-- Get the remainder-time-offset for next iteration
		D.playoffset = dtadj - (D.updatespeed * steps)

		-- Get the current ideal update-speed
		D.updatespeed = 60 / (D.bpm * D.tpq * 4)

		-- Iterate through a "steps" number of ticks, if applicable
		if steps >= 1 then
			for i = 1, steps do

				-- For every sequence...
				for s, seq in pairs(D.seq) do

					-- If the seq is set as an overlay, or is the active seq...
					if seq.overlay or (s == D.active) then

						-- Wrap the tick-pointer to the sequence's size
						local twrap = wrapNum(D.tp, 1, seq.total)

						-- Send the tick's items to the MIDI-listener via MIDI-over-UDP,
						-- in the order of: cmds first, then notes.
						local cmds = getContents(seq.tick, {twrap, 'cmd', pairs})
						local notes = getContents(seq.tick, {twrap, 'note', pairs, pairs})
						for _, n in pairs(cmds) do sendMidiMessage(n) end
						for _, n in pairs(notes) do sendMidiMessage(n) end

					end

				end

				-- Increment the tick-pointer
				D.tp = wrapNum(D.tp + 1, 1, ticks)

			end
		end

	end,

}
