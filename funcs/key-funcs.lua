return {
	
	-- Add a keystroke to the keystroke-tracking table, check for matching commands, and call said commands
	addKeystroke = function(key, isrepeat)

		key = stripSidedness(key)

		-- If this is a repeating key...
		if isrepeat then

			-- If the key in question is a chord-key, abort function
			if (key == "ctrl") or (key == "shift") or (key == "tab") then
				return nil
			end

		else -- If this isn't a repeating key, add the key to the keypress table
			table.insert(data.keys, key)
		end

		local mixed = false -- Flags whether piano-keys are mixed with non-piano keys
		local match = false -- Flags whether there is a command-match

		-- Discern whether the only currently-held keys are piano-keyboard keys
		for k, v in pairs(data.keys) do

			local c = checkKeyChord({v})

			if c then

				-- Set a fallback match to the newest key
				if v == key then
					match = c
				end

				-- Check for non-piano-command keystrokes
				if c:sub(1, 10) ~= "PIANO_KEY_" then
					mixed = true
				end

			end

		end

		-- Seek out the command that matches currently-active keys and modes,
		-- or if such a command doesn't exist, stick to the already-existing match.
		match = checkKeyChord(data.keys) or match

		-- If no acceptable match was found, then abort function
		if not match then
			return nil
		end

		-- Get the function that is linked to the keycommand, and invoke it
		if data.cmdfuncs[match] ~= nil then

			print("addKeystroke: received command '" .. match .. "'!")

			executeFunction(unpack(data.cmdfuncs[match]))

		end

	end,

	-- Seek out a command that perfectly matches a given keychord.
	checkKeyChord = function(keytab)

		for k, v in pairs(data.cmds) do
			if crossCompare(keytab, v) then
				for kk, vv in pairs(data.cmdgate[k]) do
					if vv == data.cmdmode then
						return k
					end
				end
			end
		end

		return false
		
	end,

	-- Remove a key from the keystroke-tracking table
	removeKeystroke = function(key)

		key = stripSidedness(key)

		-- Remove the key from the currently-held-keys table
		for i = 1, #data.keys do
			if key == data.keys[i] then
				table.remove(data.keys, i)
				break
			end
		end

	end,

	-- Remove all keystrokes from the keystroke-tracking table
	removeAllKeystrokes = function()
		data.keys = {}
	end,

	-- Convert user-defined keyboard-buttons into piano-keys,
	-- and attach commands to them in the command-tables.
	buttonsToPianoKeys = function(keys)

		local iter = 0

		for k, v in pairs(keys) do

			-- Format single keys in the same manner as multiple keys
			v = ((type(v) == "table") and v) or {v}

			-- For every button that corresponds to a piano-key,
			-- put corresponding commands into the command-tables.
			for _, button in pairs(v) do

				-- Make a unique command name
				local cmdname = "PIANO_KEY_" .. iter

				-- Insert a key-command and its active contexts into the command-tables
				data.cmds[cmdname] = {button}
				data.cmdgate[cmdname] = {"entry", "gen"}
				data.cmdfuncs[cmdname] = {"insertNote", k - 1, false}

				iter = iter + 1

			end

		end

	end,

	-- Build the keychord-commands for tabbing between hotseat names
	buildHotseatCommands = function()

		-- For every item in the user-defined hotseats table...
		for i = 1, math.min(30, #data.hotseats) do

			local buttons = {}
			local cmdname = "HOTSEAT_" .. i

			-- Change the chording key based on hotseat number
			if i <= 10 then
				table.insert(buttons, "ctrl")
			elseif i <= 20 then
				table.insert(buttons, "shift")
			else
				table.insert(buttons, "tab")
			end

			-- Get the seat's corresponding number-key
			local seat = tostring(i % 10)

			-- Put the number into the keychord-table
			table.insert(buttons, seat)

			-- Insert a key-command and its active contexts into the command-tables
			data.cmds[cmdname] = buttons
			data.cmdgate[cmdname] = {"entry", "gen", "cmd"}
			data.cmdfuncs[cmdname] = {"tabToHotseat", i}

		end

	end,

	-- Sort all key-command tables, to allow simple comparison
	sortKeyComboTables = function()
		for i = 1, #data.cmds do
			table.sort(data.cmds[i])
		end
	end,

	-- Strip left/right sidedness information from specific keys
	stripSidedness = function(key)

		for k, v in pairs(data.sidekeys) do
			if key == v then
				return key:sub(2)
			end
		end

		return key

	end,
	
}