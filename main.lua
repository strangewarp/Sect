
function love.load()

	MIDI = require('MIDI')

	guifuncs = require('gui-funcs')
	keyfuncs = require('key-funcs')
	utilfuncs = require('util-funcs')

	selfdatafuncs = require('self-data-funcs')
	selffilefuncs = require('self-file-funcs')
	selfguifuncs = require('self-gui-funcs')
	selfkeyfuncs = require('self-key-funcs')
	selfnotefuncs = require('self-note-funcs')
	selfpointerfuncs = require('self-pointer-funcs')
	selfselectfuncs = require('self-select-funcs')
	selfundofuncs = require('self-undo-funcs')
	selfutilfuncs = require('self-util-funcs')

	data = require('data-table')

	utilfuncs:tableToNewContext(_G)
	tableToNewContext(keyfuncs, _G)
	tableToNewContext(guifuncs, _G)

	tableToNewContext(selfdatafuncs, data)
	tableToNewContext(selffilefuncs, data)
	tableToNewContext(selfguifuncs, data)
	tableToNewContext(selfkeyfuncs, data)
	tableToNewContext(selfnotefuncs, data)
	tableToNewContext(selfpointerfuncs, data)
	tableToNewContext(selfselectfuncs, data)
	tableToNewContext(selfundofuncs, data)
	tableToNewContext(selfutilfuncs, data)

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
	tableToNewContext(prefs, data)

	local width, height = love.graphics.getDimensions()
	canvas = love.graphics.newCanvas(width, height)

	fontsmall = love.graphics.newFont("Milavregarian.ttf", 8)
	fontlarge = love.graphics.newFont("Milavregarian.ttf", 12)

	love.keyboard.setKeyRepeat(true)

	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	
	data:sortKeyComboTables()

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
	data:buildGUI(canvas, width, height)

end

function love.mousepressed(x, y, button)

end

function love.mousereleased(x, y, button)

end

function love.keypressed(key, isrepeat)
	key = tostring(key)
	data:addKeystroke(key, isrepeat)
end

function love.keyreleased(key)
	data:removeKeystroke(key)
end
