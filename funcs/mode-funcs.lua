
return {

	-- Toggle the rendering of channel-numbers onto the notes
	toggleChanNumView = function()
		data.chanview = not data.chanview
	end,

	-- Toggle Command Mode, where non-note MIDI commands can be entered.
	toggleCmdMode = function()

		-- Reset command-pointer on tabbing in or out, to avoid null pointer errors
		data.cmdp = 1

		if data.cmdmode == "cmd" then
			data.cmdmode = "entry"
		else
			data.cmdmode = "cmd"
		end

	end,

	-- Toggle the entry-quantize flag, which controls whether note-entry snaps to global factor values
	toggleEntryQuantize = function()
		data.entryquant = not data.entryquant
	end,

	-- Toggle between Generator Mode and Entry Mode
	toggleGeneratorMode = function()
		if data.cmdmode == "gen" then
			data.cmdmode = "entry"
		else
			data.cmdmode = "gen"
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

	-- Toggle the Saveload panel, and its corresponding data-mode
	toggleSaveLoad = function()

		-- If the save-dir is not correctly set, abort function
		if not data.saveok then
			return nil
		end

		data.playing = false
		data.recording = false

		data.savestring = ""
		data.sfsp = 1
		data.savevalid = false

		-- If in saveload mode, toggle out of it.
		if data.cmdmode == "saveload" then

			-- Disallow text-input events
			love.keyboard.setTextInput(false)

			-- Toggle into entry mode
			data.cmdmode = "entry"

		else -- If out of saveload mode, prepare to toggle into it

			-- Allow text-input events
			love.keyboard.setTextInput(true)

			-- Toggle into saveload mode
			data.cmdmode = "saveload"

		end

	end,
	
	-- Toggle a given sequence's overlay activity
	toggleSeqOverlay = function()
		data.seq[data.active].overlay = not data.seq[data.active].overlay
	end,

}
