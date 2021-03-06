
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
			table.insert(D.keys, key)
		end

		local match = false -- Flags whether there is a command-match

		-- Discern whether the only currently-held keys are piano-keyboard keys
		for k, v in pairs(D.keys) do

			local c = checkKeyChord({v})

			if c then

				-- Set a fallback match to the newest key
				if v == key then
					match = c
				end

			end

		end

		-- Seek out the command that matches currently-active keys and modes,
		-- or if such a command doesn't exist, stick to the already-existing match.
		match = checkKeyChord(D.keys) or match

		-- If no acceptable match was found, then abort function
		if not match then
			return nil
		end

		-- Get the function that is linked to the keycommand, and invoke it
		if D.cmdfuncs[match] ~= nil then

			print("addKeystroke: received command '" .. match .. "'!")

			D.funcactive = match ~= 'TOGGLE_PLAY_MODE'
			executeFunction(unpack(D.cmdfuncs[match]))
			D.funcactive = false

		end

	end,

	-- Remove a key from the keystroke-tracking table
	removeKeystroke = function(key)

		key = stripSidedness(key)

		-- Remove the key from the currently-held-keys table
		for i = 1, #D.keys do
			if key == D.keys[i] then
				table.remove(D.keys, i)
				break
			end
		end

	end,

	-- Remove all keystrokes from the keystroke-tracking table
	removeAllKeystrokes = function()
		D.keys = {}
	end,

	-- Build the keychord-commands for tabbing between hotseat names
	buildHotseatCommands = function()

		-- For every item in the user-defined hotseats table...
		for i = 1, math.min(30, #D.hotseats) do

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
			D.cmds[cmdname] = buttons
			D.cmdgate[cmdname] = {"entry", "gen", "cmd"}
			D.cmdfuncs[cmdname] = {"tabToHotseat", i}

		end

	end,

	-- Convert user-defined keyboard-buttons into piano-keys,
	-- and attach commands to them in the command-tables.
	buildPianoKeyCommands = function(keys)

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
				D.cmds[cmdname] = {button}
				D.cmdgate[cmdname] = {"entry", "gen"}
				D.cmdfuncs[cmdname] = {"insertNote", k - 1, false}

				iter = iter + 1

			end

		end

	end,

	-- Seek out a command that perfectly matches a given keychord.
	checkKeyChord = function(keytab)

		for k, v in pairs(D.cmds) do
			if crossCompare(keytab, v) then
				for kk, vv in pairs(D.cmdgate[k]) do
					if vv == D.cmdmode then
						return k
					end
				end
			end
		end

		return false
		
	end,

	-- Sort all key-command tables, to allow simple comparison
	sortKeyComboTables = function()
		for i = 1, #D.cmds do
			table.sort(D.cmds[i])
		end
	end,

	-- Strip left/right sidedness information from specific keys
	stripSidedness = function(key)

		for k, v in pairs(D.sidekeys) do
			if key == v then
				return key:sub(2)
			end
		end

		return key

	end,
	
}
