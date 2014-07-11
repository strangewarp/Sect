
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
	end,

	-- Flip whether to draw the active sequence's notes
	toggleNoteDraw = function()
		data.drawnotes = not data.drawnotes
	end,

	-- Toggle whether note-recording commands are accepted
	toggleRecording = function()
		data.recording = not data.recording
	end,
	
	-- Flip a given sequence's overlay activity
	toggleSeqOverlay = function()
		data.seq[data.active].overlay = not data.seq[data.active].overlay
	end,

}
