
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

		if love.timer then love.timer.sleep(D.updatespeed) end

	end

end

---------------
--- ON LOAD ---
---------------
function love.load()

	-- Set text-input commands to false
	love.keyboard.setTextInput(false)

	MIDI = require('midi/MIDI')

	socket = require('socket')

	cmdfuncs = require('funcs/cmd-funcs')
	datafuncs = require('funcs/data-funcs')
	factorfuncs = require('funcs/factor-funcs')
	filefuncs = require('funcs/file-funcs')
	generatorfuncs = require('funcs/generator-funcs')
	guigridfuncs = require('gui/gui-grid-funcs')
	guiloadingfuncs = require('gui/gui-loading-funcs')
	guimiscfuncs = require('gui/gui-misc-funcs')
	guinotefuncs = require('gui/gui-note-funcs')
	guipianofuncs = require('gui/gui-piano-funcs')
	guisaveloadfuncs = require('gui/gui-saveload-funcs')
	guiseqfuncs = require('gui/gui-seq-funcs')
	guisidebarfuncs = require('gui/gui-sidebar-funcs')
	guitrackfuncs = require('gui/gui-track-funcs')
	indexfuncs = require('funcs/index-funcs')
	keyfuncs = require('funcs/key-funcs')
	modefuncs = require('funcs/mode-funcs')
	modifyfuncs = require('funcs/modify-funcs')
	mousefuncs = require('funcs/mouse-funcs')
	notefuncs = require('funcs/note-funcs')
	playfuncs = require('funcs/play-funcs')
	pointerfuncs = require('funcs/pointer-funcs')
	selectfuncs = require('funcs/select-funcs')
	socketfuncs = require('funcs/socket-funcs')
	undofuncs = require('funcs/undo-funcs')
	utilfuncs = require('funcs/util-funcs')
	wheelfuncs = require('funcs/wheel-funcs')

	D = require('data/data-table')

	utilfuncs.tableToNewContext(
		_G,
		cmdfuncs,
		datafuncs,
		factorfuncs,
		filefuncs,
		generatorfuncs,
		guigridfuncs,
		guiloadingfuncs,
		guimiscfuncs,
		guinotefuncs,
		guipianofuncs,
		guisaveloadfuncs,
		guiseqfuncs,
		guisidebarfuncs,
		guitrackfuncs,
		indexfuncs,
		keyfuncs,
		modefuncs,
		modifyfuncs,
		mousefuncs,
		notefuncs,
		playfuncs,
		pointerfuncs,
		selectfuncs,
		socketfuncs,
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
		vf:write("return { version = \"" .. D.version .. "\" }")
		vf:close()
	end

	-- Get the default prefs data, and set it as a global table
	prefs = require('prefs-table')
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
		if (not version) or (D.version ~= version) then

			-- Write outdated prefs to an "oldprefs.lua" file, with version number
			local oldf = love.filesystem.newFile("oldprefs-" .. (version or "old") .. ".lua")
			oldf:open('w')
			oldf:write(uptext)
			oldf:close()

			-- Update the local version.lua with the current version number
			local vf = love.filesystem.newFile("version.lua")
			vf:open('w')
			vf:write("return { version = \"" .. D.version .. "\" }")
			vf:close()

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
	tableToNewContext(D, prefs)

	-- Check whether the savepath exists
	checkUserSavePath()

	-- Initialize a global Love canvas
	local width, height = love.graphics.getDimensions()
	canvas = love.graphics.newCanvas(width, height)
	love.graphics.setCanvas(canvas)

	-- Preload all complex GUI elements
	preloadFonts()
	preloadImages()
	preloadCursors()
	preloadGradients()

	-- Load the mousemove-inactive cursor
	love.mouse.setCursor(D.cursor.default.c)

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
			D.loadcmds,
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
				{{"saveScalesAndWheels"}, "Saving scale and wheel D..."},
			}
		)

	else -- Else, if combinatoric tables exist, load them
		tableCombine(
			D.loadcmds,
			{
				{{"loadScalesAndWheels"}, "Loading scale and wheel D..."},
			}
		)
	end

	-- Enable keyboard commands after completing all other load-funcs
	tableCombine(
		D.loadcmds,
		{
			{{"setupUDP"}, "Setting up MIDI-over-UDP apparatus..."},
			{{"buildPianoKeyCommands", D.pianokeys}, "Assigning computer-piano keys..."},
			{{"buildHotseatCommands"}, "Building hotseat commands..."},
			{{"sortKeyComboTables"}, "Sorting key-command tables..."},
		}
	)

end

-----------------
--- ON UPDATE ---
-----------------
function love.update(dt)

	-- If still loading, abort function
	if D.loading then
		return nil
	end

	-- Check for incoming MIDI commands
	repeat
		local d, msg = D.udpin:receive()
		if d then
			getMidiMessage(d) -- Send incoming MIDI to a parsing function
		end
	until not d

	-- If Play Mode is active, iterate by one tick
	if D.playing then
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
	if D.loading then
		executeLoadingFuncAndDraw(width, height)
		return nil
	end

	-- If redraw has been flagged, or width or height has been resized, rebuild the visible GUI elements accordingly
	if D.redraw
	or (width ~= D.width)
	or (height ~= D.height)
	then
		D.redraw = false
		D.width = width
		D.height = height
		canvas = love.graphics.newCanvas(D.width, D.height)
		buildGUI()
		drawGUI()
	end

	-- If the mouse is being dragged, check drag boundaries
	if D.dragging then

		-- Get positioning vars
		local left = D.size.sidebar.width
		local top = 0
		local middle = height - D.size.track.height

		-- Get the mouse's concrete position
		local x, y = love.mouse.getPosition()

		-- Check the cursor for dragging behavior
		checkMouseDrag(
			left, top,
			width, middle,
			x - left, y - top
		)

	end

	-- In play-mode, rebuild and redraw the seq-panel and sidebar on every frame
	if D.playing then
		buildSidebar()
		buildMetaSeqPanel()
		drawMetaSeqPanel()
		drawSidebar()
		drawPianoRoll()
	end

	-- Draw canvas to screen
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(canvas, 0, 0)

	degradeSavePopup() -- Gradually degrade any active save-popup's activity
	drawSavePopup() -- Redraw the save-popup on top of itself

end

----------------------
--- ON MOUSE PRESS ---
----------------------
function love.mousepressed(x, y, button)

	-- Ignore mouse activity in Saveload Mode
	if D.cmdmode == "saveload" then
		return nil
	end

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

	-- Ignore mouse activity in Saveload Mode
	if D.cmdmode == "saveload" then
		return nil
	end

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
	if D.loading then
		return nil
	end

	key = tostring(key)
	addKeystroke(key, isrepeat)

end

----------------------
--- ON KEY RELEASE ---
----------------------
function love.keyreleased(key)

	-- If still on the loading screen, do nothing
	if D.loading then
		return nil
	end

	removeKeystroke(key)

end

---------------------
--- ON TEXT-INPUT ---
---------------------
function love.textinput(t)

	-- If any commands are being chorded with ctrl or tab, abort function
	for k, v in pairs(D.keys) do
		if (v == "ctrl") or (v == "tab") then
			return nil
		end
	end

	if t == "backspace" then
		removeSaveChar(-1)
	elseif t == "delete" then
		removeSaveChar(1)
	else
		addSaveChar(t)
	end

end

-----------------------
--- ON FOCUS CHANGE ---
-----------------------
function love.focus(f)

	-- If any keys are held down during focus-change, remove their keystrokes
	removeAllKeystrokes()

end
