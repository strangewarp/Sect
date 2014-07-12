
-- Most of these functions were adapted from loveOSC:
-- https://github.com/headchant/loveOSC

return {

	-- Iterate through a table two items at a time
	iterPairwise = function(atable, startvalue)
		local index = startvalue - 2
		return function()
			index = index + 2
			return atable[index], atable[index + 1]
		end
	end,

	-- Collect an encoded piece of data for a given message
	collectEncodingForMessage = function(t, data)
		if t == 'i' then
			return encodeInt(data)
		elseif t == 'f' then
			return encodeFloat(data)
		elseif t == 's' then
			return encodeString(data)
		elseif t == 'b' then
			return encodeBlob(data)
		end
	end,

	-- Decode an OSC message
	decodeOSC = function(data)
		if #data == 0 then
			return nil
		end
		if string.match(data, "^#bundle") then
			return decodeBundle(data)
		else
			return decodeMessage(data)
		end
	end,

	decodeMessage = function(data)
		local types, addr, tmp_data = nil
		local message = {}
		addr, tmp_data = getAddrFromData(data)
		types, tmp_data = getTypesFromData(tmp_data)
		if addr == nil or types == nil then
			return nil
		end
		for _,t in base.ipairs(types) do
			tmp_data = collectDecodingFromMessage(t, tmp_data, message)
		end
		return message
	end,

	decodeBundle = function(data) 
		local match, last = nextString(data)
		local tmp_data = nil
		local msg = {}
		local sec, frac
		-- skip first string data since it will only contian #bundle
		tmp_data = string.sub(data, 9)
		-- check that there is a part of the message left
		if not tmp_data then
			return nil
		end
		table.insert(msg, "#bundle")	
		_, sec, frac = upack("> u4 > u4", {string.sub(tmp_data, 1, 8)})
		-- note this is an awful way of decoding to a bin string and
		-- then decoding the frac again TODO: make this nicer
		frac = numberstring(frac, 2)
		if sec == 0 and frac == IMMEDIATE then
			table.insert(msg, 0)
		else
			table.insert(msg, sec - ADJUSTMENT_FACTOR + decode_frac(frac) )
		end
		tmp_data = string.sub(tmp_data, 9)
		while #tmp_data > 0 do
			local length = decodeInt(string.sub(tmp_data,1,4))
			table.insert(msg, decodeOSC(string.sub(tmp_data, 5, 4 + length)))
			tmp_data = string.sub(tmp_data, 9 + length)
		end
		return msg
	end,

	decodeFrac = function(bin)
		local frac = 0
		for i = #bin, 1 do
			frac = (frac + string.sub(bin, i - 1, i)) / 2
		end
		return frac
	end,

	decodeFloat = function(bin)
		local pos, res = upack("> f4", {bin})
		return res
	end,

	decodeInt = function(bin)
		local pos, res = upack("> i4", {bin} )
		return res
	end,

	-- Encode OSC string
	encodeString = function(astring) 
		local fillbits = (4 - #astring % 4)
		return astring .. string.rep('\0', fillbits)
	end,

	-- Encode OSC integer
	encodeInt = function(num)
		return pack("> i4", {num}) 
	end,

	-- Encode OSC blob
	encodeBlob = function(blob)
		return encodeInt(#blob) .. encodeString(#blob)
	end,

	-- Encode OSC timetag
	encodeTimetag = function(tpoint)
		if tpoint == 0 then
			return string.rep('0', 31) .. '1'
		else
			local sec = math.floor(tpoint)
			local frac = tpoint - sec
			return pack("> u4 > u4", {sec + 2208988800, encodeFrac(frac)})
		end
	end,

	-- Encode OSC fractional
	encodeFrac = function(num) 
		local bin = ""
		local frac = num
		while #bin < 32 do
			bin = bin .. math.floor(frac * 2)
			frac = (frac * 2) - math.floor(frac * 2)
		end
		return bin
	end,

	-- Encode OSC float
	encodeFloat = function(num)
		return pack("> f4", {num})
	end,

	-- Encode an OSC message
	encodeOSC = function(data)

		local msg = ""
		local idx = 1

		if data == nil then
			return nil
		end

		if data[1] == "#bundle" then

			msg = msg .. encodeString(data[1])
			msg = msg .. encodeTimetag(data[2])
			idx = 3

			while idx <= #data do
				local submsg = encodeOSC(data[idx])
				msg = msg .. encodeInt(#submsg) .. submsg 
				idx = idx + 1
			end

			return msg

		else

			local typestring = ","
			local encodings = ""

			idx = idx + 1
			msg = msg .. encodeString(data[1])

			for t, d in iterPairwise(data, idx) do
				typestring = typestring .. t
				encodings = encodings .. collectEncodingForMessage(t, d)
			end

			return msg .. encodeString(typestring) .. encodings

		end

	end,

	-- Send a note over OSC to the Extrovert listener apparatus
	sendExtrovertNote = function(note)

		local bundle = {
			"#bundle",
			os.time(),
			{
				"/extrovert",
				"s", note[1],
				"i", data.bpm,
				"i", data.tpq,
			},
		}

		for i = 2, #note do
			table.insert(bundle[3], "i")
			table.insert(bundle[3], note[i])
		end

		local message = encodeOSC(bundle)

		data.udpout:send(message)

	end,

	-- Send a command over OSC to the Extrovert listener apparatus
	sendExtrovertHotseat = function()

		local bundle = {
			"#bundle",
			os.time(),
			{
				"/extrovert",
				"s", "loadmidi",
				"s", data.hotseats[data.activeseat],
			}
		}

		local message = encodeOSC(bundle)

		data.udpout:send(message)

	end,

	-- Set up the UDP sockets
	setupUDP = function()

		data.udpout = socket.udp()
		data.udpin = socket.udp()

		data.udpout:settimeout(0)
		data.udpout:setpeername("localhost", data.osc.send)

		data.udpin:settimeout(0)
		data.udpin:setpeername("localhost", data.osc.receive)

	end,

}
