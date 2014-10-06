
return {

	-- Parse an incoming MIDI-over-UDP command
	getMidiMessage = function(m)

		print("UDP-MIDI IN: " .. m)

		-- If there's no active sequence, or recording is off, then abort function
		if (not data.active) or (not data.recording) then
			return nil
		end

		-- Split the incoming message into a command-table
		local t = {}
		for unit in string.gmatch(m, "%S+") do
			t[#t + 1] = ((#t == 0) and unit) or tonumber(unit)
		end

		-- Convert the Pd MIDI-command format into Sect's score-based format
		local n = {
			tick = data.tp,
			note = deepCopy(t),
		}
		n.note[2] = data.tp - 1

		-- Depending on command-type, trigger a setNotes or setCmds function
		if n.note[1] == 'note' then

			-- If velocity is 0, for silly Pd note-off command reasons, abort function
			if n.note[6] == 0 then
				return nil
			end

			n.note[3] = data.dur -- Replace the dummy duration value

			-- Call setNotes from within executeFunction, to spawn a new undo chunk
			executeFunction("setNotes", data.active, {n}, false)

		else

			-- Call setCmds from within executeFunction, to spawn a new undo chunk
			executeFunction("setCmds", data.active, {n}, false)

		end

		moveTickPointer(1) -- Move ahead by one spacing unit

		print("DYE: " .. table.concat(n.note, " ")) -- debugging

	end,

	-- Send a note, with current BPM/TPQ information, over UDP to the MIDI-OUT apparatus
	sendMidiMessage = function(n)

		local d = data.bpm .. " " .. data.tpq .. " " .. table.concat(n, " ")

		print("UDP-MIDI OUT: " .. d)

		data.udpout:send(d)

	end,

	-- Set up the UDP sockets
	setupUDP = function()

		data.udpout = socket.udp()
		data.udpin = socket.udp()

		data.udpin:settimeout(0)
		data.udpin:setsockname('*', data.udpreceive)

		data.udpout:settimeout(0)
		data.udpout:setpeername("localhost", data.udpsend)

	end,

}