
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

	local defaultprefs, _ = love.filesystem.read('prefs-table.lua')

	-- If the userprefs file doesn't exist, create it in the savefile folder,
	-- require it like a regular module, and then add it to data-table context.
	if not love.filesystem.exists("userprefs.lua") then

		local uf = love.filesystem.newFile("userprefs.lua")
		uf:open('w')
		uf:write(defaultprefs)
		uf:close()
		prefs = require('prefs-table')

	else -- If userprefs exist, simply require them.
		prefs = require('userprefs')
	end

	-- Put the prefs into the data object
	tableToNewContext(data, prefs)

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
		executeLoadingFuncAndDraw(canvas, width, height)
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
		shiftInternalValue("cellwidth", false, -1)
	elseif button == 'wu' then -- Shit tick-zoom up
		shiftInternalValue("cellwidth", false, 1)
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
