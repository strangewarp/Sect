
---------------
--- ON LOAD ---
---------------
function love.load()

	-- Set user-input to false, for duration of loading
	love.keyboard.setTextInput(false)

	MIDI = require('midi/MIDI')

	-- Serial and Compress are third-party libraries,
	-- and load into global namespace in a different way.
	require('serial/serial')
	require('serial/compress')

	datafuncs = require('data-funcs')
	filefuncs = require('file-funcs')
	guigridfuncs = require('gui-grid-funcs')
	guiloadingfuncs = require('gui-loading-funcs')
	guimiscfuncs = require('gui-misc-funcs')
	guinotefuncs = require('gui-note-funcs')
	guisidebarfuncs = require('gui-sidebar-funcs')
	keyfuncs = require('key-funcs')
	modefuncs = require('mode-funcs')
	notefuncs = require('note-funcs')
	pointerfuncs = require('pointer-funcs')
	selectfuncs = require('select-funcs')
	undofuncs = require('undo-funcs')
	utilfuncs = require('util-funcs')
	wheelfuncs = require('wheel-funcs')

	data = require('data-table')

	utilfuncs.tableToNewContext(
		_G,
		datafuncs,
		filefuncs,
		guigridfuncs,
		guiloadingfuncs,
		guimiscfuncs,
		guinotefuncs,
		guisidebarfuncs,
		keyfuncs,
		modefuncs,
		notefuncs,
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

	tableToNewContext(data, prefs)

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
				{{"buildConsonanceRatings"}, "Building consonance ratings..."},
				{{"buildWheels"}, "Building wheels..."},
				{{"indexScalesByBin"}, "Re-indexing scales by binary identity..."},
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

	-- Initialize GUI miscellany
	local width, height = love.graphics.getDimensions()
	canvas = love.graphics.newCanvas(width, height)
	fontsmall = love.graphics.newFont("Milavregarian.ttf", 8)
	sectlogo = love.graphics.newImage("img/biglogo.png", "normal")
	loadingbg = love.graphics.newImage("img/loadingbg.png", "normal")
	love.graphics.setFont(fontsmall)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	love.keyboard.setKeyRepeat(true)
	
	-- Attach user-defined keyboard-buttons to commands
	buttonsToPianoKeys(data.pianokeys)
	sortKeyComboTables()

	-- Enable keyboard commands after completing all other load-funcs
		tableCombine(
			data.loadcmds,
			{
				{{"buttonsToPianoKeys", data.pianokeys}, "Assigning computer-piano keys..."},
				{{"sortKeyComboTables"}, "Sorting key-command tables..."},
			}
		)

end

-----------------
--- ON UPDATE ---
-----------------
function love.update(dt)

end

---------------
--- ON DRAW ---
---------------
function love.draw()

	-- Get window dimensions
	local width, height = love.graphics.getDimensions()

	-- If the canvas-dimensions don't match the window-dimensions,
	-- change the dimensions of the canvas
	local cwidth, cheight = canvas:getDimensions()
	if (width ~= cwidth) or (height ~= cheight) then
		canvas = love.graphics.newCanvas(width, height)
	end

	-- If still loading, render a loading screen
	if data.loading then
		executeLoadingFuncAndDraw(canvas, width, height)
		return nil
	end

	-- Build the GUI
	buildGUI(canvas, width, height)

end

----------------------
--- ON MOUSE PRESS ---
----------------------
function love.mousepressed(x, y, button)

end

------------------------
--- ON MOUSE RELEASE ---
------------------------
function love.mousereleased(x, y, button)

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
