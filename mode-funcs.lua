
return {

	-- Flip whether to draw the active sequence's notes
	toggleNoteDraw = function()
		data.drawnotes = not data.drawnotes
		print("toggleNoteDraw: " .. ((data.drawnotes and "on") or "off"))
	end,

	-- Toggle whether note-recording commands are accepted
	toggleRecording = function()
		data.recording = not data.recording
		print("toggleRecording: " .. ((data.recording and "on") or "off"))
	end,
	
	-- Flip a given sequence's overlay activity
	toggleSeqOverlay = function()
		data.seq[data.active].overlay = not data.seq[data.active].overlay
	end,

	-- Toggle scale-mode, and turn off chord-mode regardless
	toggleScaleMode = function()
		data.scalemode = not data.scalemode
		data.chordmode = false
	end,

	-- Toggle chord-mode, and turn off scale-mode regardless
	toggleChordMode = function()
		data.chordmode = not data.chordmode
		data.scalemode = false
	end,

}
