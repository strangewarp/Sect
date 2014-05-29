
function love.load()

	MIDI = require('MIDI')

	datafuncs = require('data-funcs')
	filefuncs = require('file-funcs')
	guigridfuncs = require('gui-grid-funcs')
	guinotefuncs = require('gui-note-funcs')
	guimiscfuncs = require('gui-misc-funcs')
	guisidebarfuncs = require('gui-sidebar-funcs')
	keyfuncs = require('key-funcs')
	modefuncs = require('mode-funcs')
	notefuncs = require('note-funcs')
	pointerfuncs = require('pointer-funcs')
	selectfuncs = require('select-funcs')
	undofuncs = require('undo-funcs')
	utilfuncs = require('util-funcs')

	data = require('data-table')

	utilfuncs.tableToNewContext(
		_G,
		datafuncs,
		filefuncs,
		guigridfuncs,
		guinotefuncs,
		guimiscfuncs,
		guisidebarfuncs,
		keyfuncs,
		modefuncs,
		notefuncs,
		pointerfuncs,
		selectfuncs,
		undofuncs,
		utilfuncs
	)

	-- If the userprefs file doesn't exist, create it in the savefile folder,
	-- require it like a regular module, and then add it to data-table context.
	local defaultprefs, _ = love.filesystem.read('prefs-table.lua')
	if not love.filesystem.exists("userprefs.lua") then
		f = love.filesystem.newFile("userprefs.lua")
		f:open('w')
		f:write(defaultprefs)
		f:close()
		prefs = require('prefs-table')
	else
		prefs = require('userprefs')
	end
	tableToNewContext(data, prefs)

	local width, height = love.graphics.getDimensions()
	canvas = love.graphics.newCanvas(width, height)

	fontsmall = love.graphics.newFont("Milavregarian.ttf", 8)

	love.keyboard.setKeyRepeat(true)

	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	
	-- Attach user-defined keyboard-buttons to commands
	buttonsToPianoKeys(data.pianokeys)

	sortKeyComboTables()

	print("love.load: Launched!")

end

function love.update(dt)

end

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

function love.mousepressed(x, y, button)

end

function love.mousereleased(x, y, button)

end

function love.keypressed(key, isrepeat)
	key = tostring(key)
	addKeystroke(key, isrepeat)
end

function love.keyreleased(key)
	removeKeystroke(key)
end
