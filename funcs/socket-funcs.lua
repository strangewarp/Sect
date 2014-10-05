
return {

	-- Parse an incoming MIDI-over-UDP command
	getMidiMessage = function(m)

		print("UDP IN: " .. m) -- debugging

		-- If there's no active sequence, or recording is off, then abort function
		if (not data.active) or (not data.recording) then
			return nil
		end

		-- Split the incoming message into a command-table
		for unit in string.gmatch(m, "%S+") do
			t[#t + 1] = ((#t == 0) and unit) or tonumber(unit)
		end

		-- Convert the Pd MIDI-command format into Sect's score-based format
		local n = {
			tick = data.tp,
			note = deepCopy(t),
		}
		local temp = table.remove(n.note, #n.note)
		table.insert(n.note, 2, data.tp - 1)
		table.insert(n.note, 3, temp)

		-- Depending on command-type, trigger a setNotes or setCmds function
		if n.note[1] == 'note' then
			table.insert(n.note, 3, data.dur) -- Insert the duration into any NOTE command
			setNotes(data.active, {n}, false)
		else
			setCmds(data.active, {n}, false)
		end

		print("MIDI IN: " .. table.concat(t, " ")) -- debugging

	end,

	-- Send a note, with current BPM/TPQ information, over UDP to the MIDI-OUT apparatus
	sendMidiMessage = function(n)
		local d = data.bpm .. " " .. data.tpq .. " " .. table.concat(n, " ")
		print("UDP OUT: " .. d) -- debugging
		data.udpout:send(d)
	end,

	-- Set up the UDP sockets
	setupUDP = function()

		data.udpout = socket.udp()
		data.udpin = socket.udp()

		data.udpin:settimeout(0)
		data.udpin:setpeername("localhost", data.udpreceive)

		data.udpout:settimeout(0)
		data.udpout:setpeername("localhost", data.udpsend)

	end,

}