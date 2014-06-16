
---------------
--- ON LOAD ---
---------------
function love.load()

	-- Set user-input to false, for duration of loading
	love.keyboard.setTextInput(false)

	MIDI = require('midi/MIDI')

	datafuncs = require('funcs/data-funcs')
	filefuncs = require('funcs/file-funcs')
	guigridfuncs = require('gui/gui-grid-funcs')
	guiloadingfuncs = require('gui/gui-loading-funcs')
	guimiscfuncs = require('gui/gui-misc-funcs')
	guinotefuncs = require('gui/gui-note-funcs')
	guisidebarfuncs = require('gui/gui-sidebar-funcs')
	guiwheelfuncs = require('gui/gui-wheel-funcs')
	keyfuncs = require('funcs/key-funcs')
	modefuncs = require('funcs/mode-funcs')
	notefuncs = require('funcs/note-funcs')
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
		guigridfuncs,
		guiloadingfuncs,
		guimiscfuncs,
		guinotefuncs,
		guisidebarfuncs,
		guiwheelfuncs,
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
				{{"purgeEmptyScales"}, "Purging empty scales..."},
				{{"buildConsonanceRatings"}, "Building consonance ratings..."},
				{{"buildWheels"}, "Building wheels..."},
				--{{"indexScalesByBin"}, "Re-indexing scales by binary identity..."},
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
	fontsmall = love.graphics.newFont("img/Milavregarian.ttf", 8)
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

	-- If still loading, render a loading screen
	if data.loading then
		executeLoadingFuncAndDraw(canvas, width, height)
		return nil
	end

	-- Build the GUI
	buildGUI(width, height)

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
