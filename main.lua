
---------------
--- ON LOAD ---
---------------
function love.load()

	MIDI = require('midi/MIDI')

	-- Serial and Compress are third-party libraries,
	-- and load into global namespace in a different way.
	require('serial/serial')
	require('serial/compress')

	datafuncs = require('data-funcs')
	filefuncs = require('file-funcs')
	guigridfuncs = require('gui-grid-funcs')
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

		generateCombinatorics()

		-- Serialize and compress scale and wheel data
		local serialscales = serialize(data.scales)
		local serialwheels = serialize(data.wheels)

		-- Save compressed scale data
		local sf = love.filesystem.newFile("scales.lua")
		sf:open('w')
		sf:write(serialscales)
		sf:close()

		-- Save compressed wheel data		
		local wf = love.filesystem.newFile("wheels.lua")
		wf:open('w')
		wf:write(serialwheels)
		wf:close()
		
	else -- Else, if combinatoric tables exist, load them
		data.scales = require('scales')
		data.wheels = require('wheels')
	end

	-- Initialize GUI miscellany
	local width, height = love.graphics.getDimensions()
	canvas = love.graphics.newCanvas(width, height)
	fontsmall = love.graphics.newFont("Milavregarian.ttf", 8)
	sectlogo = love.graphics.newImage("img/biglogo.png", "normal")
	love.graphics.setFont(fontsmall)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	
	-- Attach user-defined keyboard-buttons to commands
	buttonsToPianoKeys(data.pianokeys)
	sortKeyComboTables()

	love.keyboard.setKeyRepeat(true)

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
	key = tostring(key)
	addKeystroke(key, isrepeat)
end

----------------------
--- ON KEY RELEASE ---
----------------------
function love.keyreleased(key)
	removeKeystroke(key)
end
