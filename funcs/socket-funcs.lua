
return {

	-- Parse an incoming MIDI-over-UDP command
	getMidiMessage = function(m)

		print("UDP-MIDI IN: " .. m)

		-- If there's no active sequence, or recording is off, then abort function
		if (not data.active) or (not data.recording) then
			return nil
		end

		-- Split the incoming message into a command-table
		local n = {}
		for unit in string.gmatch(m, "%S+") do
			n[#n + 1] = ((#n == 0) and unit) or tonumber(unit)
		end

		-- Set the note's tick to the location of the tick-pointer
		n[2] = data.tp - 1

		-- Depending on command-type, trigger a setNotes or setCmds function
		if n[1] == 'note' then

			if data.cmdmode == 'entry' then

				-- If velocity is 0, for silly Pd note-off command reasons, abort function
				if n[6] == 0 then
					return nil
				end

				-- Replace the dummy duration value
				n[3] = data.dur

				-- Call setNotes from within executeFunction, to spawn a new undo chunk
				executeFunction("setNotes", data.active, {'insert', n}, false)

				moveTickPointer(1) -- Move ahead by one spacing unit

				-- Set the note-pointer to the bottom of the incoming note's octave
				data.np = n[5] - (n[5] % 12)

			end

		else

			if data.cmdmode == "cmd" then

				-- Get insertion-position for new command
				local cmdpos = #data.seq[data.active].tick[data.tp][data.chan].cmd + 1

				-- Call setCmd from within executeFunction, to spawn a new undo chunk
				executeFunction("setCmd", data.active, {'insert', cmdpos, n}, false)

			end

		end

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