
return {

	-- Toggle the rendering of channel-numbers onto the notes
	toggleChanNumView = function()
		D.chanview = not D.chanview
	end,

	-- Toggle Command Mode, where non-note MIDI commands can be entered.
	toggleCmdMode = function()

		-- Reset command-pointer on tabbing in or out, to avoid null pointer errors
		D.cmdp = 1

		if D.cmdmode == "cmd" then
			D.cmdmode = "entry"
		else
			D.cmdmode = "cmd"
		end

	end,

	-- Toggle the entry-quantize flag, which controls whether note-entry snaps to global factor values
	toggleEntryQuantize = function()
		D.entryquant = not D.entryquant
	end,

	-- Toggle between Generator Mode and Entry Mode
	toggleGeneratorMode = function()
		if D.cmdmode == "gen" then
			D.cmdmode = "entry"
		else
			D.cmdmode = "gen"
		end
	end,

	-- Toggle whether to draw the active sequence's notes
	toggleNoteDraw = function()
		D.drawnotes = not D.drawnotes
	end,

	-- Toggle whether to be actively playing through the sequence's ticks
	togglePlayMode = function()
		D.playing = not D.playing
		D.playskip = 0
		if D.playing then
			D.updatespeed = 60 / (D.bpm * D.tpq * 4)
		else
			D.updatespeed = 0.01
		end
	end,

	-- Toggle whether note-recording commands are accepted
	toggleRecording = function()
		D.recording = not D.recording
	end,

	-- Toggle the Saveload panel, and its corresponding data-mode
	toggleSaveLoad = function()

		D.playing = false
		D.recording = false

		D.savestring = ""
		D.sfsp = 1
		D.savevalid = false

		-- If in saveload mode, toggle out of it.
		if D.cmdmode == "saveload" then

			-- Disallow text-input events
			love.keyboard.setTextInput(false)

			-- Toggle into entry mode
			D.cmdmode = "entry"

		else -- If out of saveload mode, prepare to toggle into it

			-- Allow text-input events
			love.keyboard.setTextInput(true)

			-- Toggle into saveload mode
			D.cmdmode = "saveload"

		end

	end,
	
	-- Toggle a given sequence's overlay activity
	toggleSeqOverlay = function()
		D.seq[D.active].overlay = not D.seq[D.active].overlay
	end,

}
