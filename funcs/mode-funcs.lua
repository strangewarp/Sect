
return {

	-- Toggle the rendering of channel-numbers onto the notes
	toggleChanNumView = function()
		data.chanview = not data.chanview
	end,

	-- Toggle between Generator Mode and Entry Mode
	toggleGeneratorMode = function()
		data.cmdmodes.gen = not data.cmdmodes.gen
		data.cmdmodes.entry = not data.cmdmodes.gen
	end,

	-- Toggle whether mouse-clicks will move the tick and note pointers
	toggleMouseMove = function()

		data.mousemove = not data.mousemove

		-- Toggle between cursor images
		if data.mousemove and data.cursor.active.file then
			love.mouse.setCursor(data.cursor.active.c)
		elseif data.cursor.inactive.file then
			love.mouse.setCursor(data.cursor.inactive.c)
		end

	end,

	-- Toggle whether to draw the active sequence's notes
	toggleNoteDraw = function()
		data.drawnotes = not data.drawnotes
	end,

	-- Toggle whether to be actively playing through the sequence's ticks
	togglePlayMode = function()
		data.playing = not data.playing
		if data.playing then
			data.updatespeed = 60 / (data.bpm * data.tpq * 4)
		else
			data.updatespeed = 0.01
		end
	end,

	-- Toggle whether note-recording commands are accepted
	toggleRecording = function()
		data.recording = not data.recording
	end,
	
	-- Toggle a given sequence's overlay activity
	toggleSeqOverlay = function()
		data.seq[data.active].overlay = not data.seq[data.active].overlay
	end,

}
