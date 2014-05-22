
return {

	-- Flip whether to draw the active sequence's notes
	toggleNoteDraw = function(data)
		data.drawnotes = not data.drawnotes
		print("toggleNoteDraw: " .. ((data.drawnotes and "on") or "off"))
	end,

	-- Toggle whether note-recording commands are accepted
	toggleRecording = function(data)
		data.recording = not data.recording
		print("toggleRecording: " .. ((data.recording and "on") or "off"))
	end,
	
	-- Flip a given sequence's overlay activity
	toggleSeqOverlay = function(data)
		data.seq[data.active].overlay = not data.seq[data.active].overlay
	end,

}