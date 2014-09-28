
-----------------------
--- CUSTOM RUN-LOOP ---
-----------------------
function love.run()

	if love.math then
		love.math.setRandomSeed(os.time())
	end

	if love.event then
		love.event.pump()
	end

	if love.load then love.load(arg) end

	if love.timer then love.timer.step() end

	local dt = 0

	while true do

		if love.event then
			love.event.pump()
			for e,a,b,c,d in love.event.poll() do
				if e == "quit" then
					if not love.quit or not love.quit() then
						if love.audio then
							love.audio.stop()
						end
						return
					end
				end
				love.handlers[e](a,b,c,d)
			end
		end

		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end

		if love.update then love.update(dt) end

		if love.window and love.graphics and love.window.isCreated() then
			love.graphics.clear()
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
		end

		if love.timer then love.timer.sleep(data.updatespeed) end

	end

end

---------------
--- ON LOAD ---
---------------
function love.load()

	-- Set user-input to false, for duration of loading
	love.keyboard.setTextInput(false)

	MIDI = require('midi/MIDI')

	socket = require('socket')

	vstruct = require('vstruct')
	pack = vstruct.pack
	upack = vstruct.unpack

	datafuncs = require('funcs/data-funcs')
	filefuncs = require('funcs/file-funcs')
	generatorfuncs = require('funcs/generator-funcs')
	guigridfuncs = require('gui/gui-grid-funcs')
	guiloadingfuncs = require('gui/gui-loading-funcs')
	guimiscfuncs = require('gui/gui-misc-funcs')
	guinotefuncs = require('gui/gui-note-funcs')
	guisidebarfuncs = require('gui/gui-sidebar-funcs')
	keyfuncs = require('funcs/key-funcs')
	modefuncs = require('funcs/mode-funcs')
	mousefuncs = require('funcs/mouse-funcs')
	notefuncs = require('funcs/note-funcs')
	oscfuncs = require('funcs/osc-funcs')
	playfuncs = require('funcs/play-funcs')
	pointerfuncs = require('funcs/pointer-funcs')
	selectfuncs = require('funcs/select-funcs')
	undofuncs = require('funcs/undo-funcs')
	utilfuncs = require('funcs/util-funcs')
	wheelfuncs = require('funcs/wheel-funcs')

	data = require('data/data-table')

	utilfuncs.tableToNewContext(
		_G,
		datafuncs,
		filefuncs,
		generatorfuncs,
		guigridfuncs,
		guiloadingfuncs,
		guimiscfuncs,
		guinotefuncs,
		guisidebarfuncs,
		keyfuncs,
		modefuncs,
		mousefuncs,
		notefuncs,
		oscfuncs,
		playfuncs,
		pointerfuncs,
		selectfuncs,
		undofuncs,
		utilfuncs,
		wheelfuncs
	)

	-- If a version.lua exists, grab its version-number contents.
	-- Else, if there's no version.lua, create one with the current version.
	local version = false
	if love.filesystem.exists("version.lua") then
		local v = require('version')
		version = v.version
	else
		local vf = love.filesystem.newFile("version.lua")
		vf:open('w')
		vf:write("return { version = \"" .. data.version .. "\" }")
		vf:close()
	end

	-- Get the default prefs data
	local prefs = require('prefs-table')
	local preftext, _ = love.filesystem.read('prefs-table.lua')

	-- If the userprefs file doesn't exist, create it in the savefile folder
	if not love.filesystem.exists("userprefs.lua") then

		-- Write this version's default prefs to userprefs.lua
		local uf = love.filesystem.newFile("userprefs.lua")
		uf:open('w')
		uf:write(preftext)
		uf:close()

	else -- If userprefs exist, require them, and compare versions.

		local userprefs = require('userprefs')
		local uptext, _ = love.filesystem.read('userprefs.lua')

		-- If userprefs contain no version number,
		-- or are from an old version, then replace them.
		if (not version) or (data.version ~= version) then

			-- Write outdated prefs to an "oldprefs.lua" file, with version number
			local oldf = love.filesystem.newFile("oldprefs-" .. (version or "old") .. ".lua")
			oldf:open('w')
			oldf:write(uptext)
			oldf:close()

			-- Write this version's default prefs to userprefs.lua
			local uf = love.filesystem.newFile("userprefs.lua")
			uf:open('w')
			uf:write(preftext)
			uf:close()

		else -- Else if userprefs were the right version, overwrite prefs with them
			prefs = deepCopy(userprefs)
		end

	end

	-- Put the prefs into the data object
	tableToNewContext(data, prefs)

	-- Check whether the savepath exists by opening a dummy file.
	-- If the savepath exists, enable saving, and delete dummy file.
	local savetestpath = data.savepath .. "sect_filepath_test.txt"
	local pathf = io.open(savetestpath, "w")
	if pathf ~= nil then
		data.saveok = true
		pathf:close()
		_ = love.filesystem.remove(savetestpath)
	end

	-- Preload all complex GUI elements
	preloadFonts()
	preloadImages()
	preloadCursors()

	-- Load the mousemove-inactive cursor
	love.mouse.setCursor(data.cursor.default.c)

	-- Get a new time-based random-seed for the entire session
	math.randomseed(os.time())

	-- Initialize GUI miscellany
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	love.keyboard.setKeyRepeat(true)
	
	-- If combinatoric data tables don't exist, generate and store them
	if (not love.filesystem.exists("scales.lua"))
	or (not love.filesystem.exists("wheels.lua"))
	then

		-- Append combinatoric generation commands to loading-cmd table
		tableCombine(
			data.loadcmds,
			{
				{{"buildDataScales"}, "Building scales..."},
				{{"anonymizeScaleKeys"}, "Indexing scales..."},
				{{"purgeIdenticalScales"}, "Purging identical scales..."},
				{{"rotateScalesToFilledPosition"}, "Rotating scales..."},
				{{"buildIntervalSpectrum"}, "Building interval spectra..."},
				{{"indexScalesByNoteQuantity"}, "Indexing scales by k-species..."},
				{{"purgeEmptyScales"}, "Purging empty scales..."},
				{{"buildConsonanceRatings"}, "Building consonance ratings..."},
				{{"buildWheels"}, "Building wheels..."},
				{{"saveScalesAndWheels"}, "Saving scale and wheel data..."},
			}
		)

	else -- Else, if combinatoric tables exist, load them
		tableCombine(
			data.loadcmds,
			{
				{{"loadScalesAndWheels"}, "Loading scale and wheel data..."},
			}
		)
	end

	-- Enable keyboard commands after completing all other load-funcs
	tableCombine(
		data.loadcmds,
		{
			{{"setupUDP"}, "Setting up OSC-UDP apparatus..."},
			{{"buttonsToPianoKeys", data.pianokeys}, "Assigning computer-piano keys..."},
			{{"buildHotseatCommands"}, "Building hotseat commands..."},
			{{"sortKeyComboTables"}, "Sorting key-command tables..."},
		}
	)

end

-----------------
--- ON UPDATE ---
-----------------
function love.update(dt)

	-- If Play Mode is active, iterate by one tick
	if data.playing then
		iteratePlayMode(dt)
	end

end

---------------
--- ON DRAW ---
---------------
function love.draw()

	-- Get window dimensions
	local width, height = love.graphics.getDimensions()

	-- If still loading, render a loading screen
	if data.loading then
		executeLoadingFuncAndDraw(width, height)
		return nil
	end

	-- Update the piano-bar width, based on window width
	data.pianowidth = data.size.piano.basewidth + (width / 50)

	-- If the mouse is being dragged, check drag boundaries
	if data.dragging then

		-- Get positioning vars
		local left = data.size.sidebar.width
		local top = 0
		local pianoleft = left + (data.pianowidth / 2)
		local middle = height - data.size.botbar.height

		-- Get the mouse's concrete position
		local x, y = love.mouse.getPosition()

		-- Check the cursor for dragging behavior
		checkMouseDrag(
			pianoleft, top,
			width, middle,
			x - pianoleft, y - top
		)

	end

	-- Build the GUI
	buildGUI(width, height)

end

----------------------
--- ON MOUSE PRESS ---
----------------------
function love.mousepressed(x, y, button)

	-- Get window dimensions
	local width, height = love.graphics.getDimensions()

	mouseCursorChange(button, true)

	if (button == 'l')
	or (button == 'r')
	then -- Call the mouse-picking function
		mousePick(x, y, width, height, button)
	elseif button == 'wd' then -- Shift tick-zoom down
		shiftInternalValue("cellwidth", false, -0.25)
	elseif button == 'wu' then -- Shit tick-zoom up
		shiftInternalValue("cellwidth", false, 0.25)
	end

end

------------------------
--- ON MOUSE RELEASE ---
------------------------
function love.mousereleased(x, y, button)

	-- Set the mouse cursor back to its default appearance
	if (button == 'l') or (button == 'r') then
		mouseCursorChange(button, false)
	end

end

--------------------
--- ON KEY PRESS ---
--------------------
function love.keypressed(key, isrepeat)

	-- If still on the loading screen, do nothing
	if data.loading then
		return nil
	end

	key = tostring(key)
	addKeystroke(key, isrepeat)

end

----------------------
--- ON KEY RELEASE ---
----------------------
function love.keyreleased(key)
	removeKeystroke(key)
end
