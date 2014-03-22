return {
	
	-- DATA VARS --
	seq = {}, -- Sequence-data table
	keys = {}, -- Keystroke-tracking table

	active = false, -- Currently active sequence (false if nothing loaded)
	tp = false, -- Current tick-pointer position (false if nothing loaded)
	np = false, -- Current note-pointer position (false if nothing loaded)

	tick = 1, -- Current tick occupied by the play-line position
	playing = false, -- Toggles whether the tickline is playing or not

	-- HOTSEAT VARS --
	activeseat = 1, -- Currently active hotseat-name

	-- MIDI VARS --
	bpm = 120, -- Beats per minute
	tpq = 32, -- Ticks per quarter-note
	chan = 0, -- Channel
	velo = 127, -- Velocity
	dur = 8, -- Duration
	spacing = 8, -- Spacing

	-- ZOOM VARS --
	zoomx = 4, -- Multiplier for X-axis zoom
	zoomy = 4, -- Multiplier for Y-axis zoom

	-- UNDO VARS --
	undo = {}, -- Undo-function stack
	redo = {}, -- Redo-function stack
	dotarget = "undo", -- Toggles whether undo-funcs go into undo- or redo-table

	-- CANVAS VARS --
	update = true, -- Tracks whether the GUI should be redrawn

	-- SELECTION VARS --
	ls = { -- Left selection-pointer
		x = false,
		y = false,
	},
	rs = { -- Right selection-pointer
		x = false,
		y = false,
	},
	sel = { -- Holds the boundaries of the currently selected area
		l = false, -- Left
		r = false, -- Right
		t = false, -- Top
		b = false, -- Bottom
	},
	copy = { -- Holds the boundaries of all combined additive copy commands
		l = false, -- Left
		r = false, -- Right
		t = false, -- Top
		b = false, -- Bottom
	},
	copyrel = { -- Holds the x,y boundaries of combined relative copy commands
		x = false,
		y = false,
	},
	movedat = {}, -- Holds the notes that were selected for movement
	copydat = {}, -- Concrete positions of all copied notes
	reldat = {}, -- Relative positions of all copied notes

	-- Baseline contents for new sequences
	baseseq = {
		point = 1, -- Internal pointer, for playing decoupled from global tick
		mute = false, -- If sequence is muted, none of its notes will play
		tick = {}, -- Table that holds all ticks (each holds its own notes)
	},

	-- Boundaries for user-shiftable control variables
	bounds = {
		bpm = {1, false, false}, -- Beats per minute
		tpq = {1, 1000, false}, -- Ticks per quarter-note
		np = {0, 127, true}, -- Note-pointer (active pitch)
		chan = {0, 15, true}, -- Channel
		velo = {0, 127, true}, -- Velocity
		dur = {1, false, false}, -- Duration
		spacing = {0, false, false}, -- Spacing
		zoomx = {1, 16, false}, -- X-axis zoom (tick axis)
		zoomy = {1, 16, false}, -- Y-axis zoom (note axis)
	},

	-- Types of MIDI commands that are accepted in a sequence
	acceptmidi = {
		note = true,
		channel_after_touch = true,
		control_change = true,
		patch_change = true,
		key_after_touch = true,
		pitch_wheel_change = true,
		set_tempo = true,
	},

	-- Names of keys that start with "l"/"r", which collapse into single keys
	sidekeys = {
		"lshift", "rshift",
		"lctrl", "rctrl",
		"lalt", "ralt",
	},

	-- Shapes and names of piano-keys
	pianometa = {
		{1, "C"},
		{0, "Cs"},
		{2, "D"},
		{0, "Ds"},
		{3, "E"},
		{1, "F"},
		{0, "Fs"},
		{2, "G"},
		{0, "Gs"},
		{2, "A"},
		{0, "As"},
		{3, "B"},
	},

	-- Links between command-names and functions (with args as needed)
	cmdfuncs = {

		LOAD_FILE = {"loadFile", {false, false, true}},
		SAVE_FILE = {"saveFile"},
		LOAD_DIALOG = {"loadViaDialog", {false, false, true}},
		SAVE_DIALOG = {"saveViaDialog"},
		HOTSEAT_UP = {"moveHotseatPointer", -1},
		HOTSEAT_DOWN = {"moveHotseatPointer", 1},

		UNDO = {"traverseUndo", "undo"},
		REDO = {"traverseUndo", "redo"},

		INSERT_NOTE = {"insertNote", {false, false, true}},
		DELETE_NOTE = {"deleteNote", {false, false, true}},
		DELETE_TICK_NOTES = {"deleteTickNotes", {false, false, true}},
		DELETE_BEAT_NOTES = {"deleteBeatNotes", {false, false, true}},

		INSERT_SEQ = {"addActiveSequence", {false, false, true}},
		REMOVE_SEQ = {"removeActiveSequence", {false, false, true}},

		TOGGLE_SELECTION = {"toggleSelectMode"},
		COPY_RELATIVE_ADD = {"copySelection", true, true},
		COPY_RELATIVE = {"copySelection", true, false},
		COPY_ABSOLUTE_ADD = {"copySelection", false, true},
		COPY_ABSOLUTE = {"copySelection", false, false},
		CUT_RELATIVE_ADD = {"cutSelection", true, true, {false, false, true}},
		CUT_RELATIVE = {"cutSelection", true, {false, false, true}},
		CUT_ABSOLUTE_ADD = {"cutSelection", false, true, {false, false, true}},
		CUT_ABSOLUTE = {"cutSelection", false, {false, false, true}},
		PASTE_RELATIVE = {"pasteSelection", true, {false, false, true}},
		PASTE = {"pasteSelection", false, {false, false, true}},

		CHANNEL_UP = {"shiftInternalValue", "chan", false, 1},
		CHANNEL_DOWN = {"shiftInternalValue", "chan", false, -1},

		VELOCITY_UP = {"shiftInternalValue", "velo", false, 1},
		VELOCITY_DOWN = {"shiftInternalValue", "velo", false, -1},
		VELOCITY_UP_10 = {"shiftInternalValue", "velo", false, 10},
		VELOCITY_DOWN_10 = {"shiftInternalValue", "velo", false, -10},

		DURATION_UP = {"shiftInternalValue", "dur", false, 1},
		DURATION_DOWN = {"shiftInternalValue", "dur", false, -1},
		DURATION_UP_MULTI = {"shiftInternalValue", "dur", true, 2},
		DURATION_DOWN_MULTI = {"shiftInternalValue", "dur", true, 0.5},

		SPACING_UP = {"shiftInternalValue", "spacing", false, 1},
		SPACING_DOWN = {"shiftInternalValue", "spacing", false, -1},
		SPACING_UP_MULTI = {"shiftInternalValue", "spacing", true, 2},
		SPACING_DOWN_MULTI = {"shiftInternalValue", "spacing", true, 0.5},

		BPM_UP = {"shiftInternalValue", "bpm", false, 1},
		BPM_DOWN = {"shiftInternalValue", "bpm", false, -1},
		BPM_UP_10 = {"shiftInternalValue", "bpm", false, 10},
		BPM_DOWN_10 = {"shiftInternalValue", "bpm", false, -10},

		TPQ_UP = {"shiftTicksAndRebalance", false, 1, {false, false, true}},
		TPQ_DOWN = {"shiftTicksAndRebalance", false, -1, {false, false, true}},
		TPQ_UP_MULTI = {"shiftTicksAndRebalance", true, 2, {false, false, true}},
		TPQ_DOWN_MULTI = {"shiftTicksAndRebalance", true, 0.5, {false, false, true}},

		MOD_CHANNEL_UP = {"modActiveNoteChannel", 1, {false, false, true}},
		MOD_CHANNEL_DOWN = {"modActiveNoteChannel", -1, {false, false, true}},

		MOD_VELOCITY_UP = {"modActiveNoteVelocity", 1, {false, false, true}},
		MOD_VELOCITY_DOWN = {"modActiveNoteVelocity", -1, {false, false, true}},
		MOD_VELOCITY_UP_10 = {"modActiveNoteVelocity", 10, {false, false, true}},
		MOD_VELOCITY_DOWN_10 = {"modActiveNoteVelocity", -10, {false, false, true}},

		MOD_NOTE_UP = {"moveActiveNote", 0, 1, {false, false, true}},
		MOD_NOTE_DOWN = {"moveActiveNote", 0, -1, {false, false, true}},
		MOD_NOTE_LEFT = {"moveActiveNote", -1, 0, {false, false, true}},
		MOD_NOTE_RIGHT = {"moveActiveNote", 1, 0, {false, false, true}},

		MOD_SEQ_UP = {"moveActiveSeq", -1, {false, false, true}},
		MOD_SEQ_DOWN = {"moveActiveSeq", 1, {false, false, true}},

		POINTER_UP = {"shiftInternalValue", "np", false, 1},
		POINTER_DOWN = {"shiftInternalValue", "np", false, -1},
		POINTER_UP_OCTAVE = {"shiftInternalValue", "np", false, 12},
		POINTER_DOWN_OCTAVE = {"shiftInternalValue", "np", false, -12},
		POINTER_LEFT = {"moveTickPointer", -1},
		POINTER_RIGHT = {"moveTickPointer", 1},
		POINTER_LEFT_BEAT = {"moveTickPointerToBeat", -1},
		POINTER_RIGHT_BEAT = {"moveTickPointerToBeat", 1},

		X_ZOOM_INC = {"shiftInternalValue", "zoomx", true, 2},
		X_ZOOM_DEC = {"shiftInternalValue", "zoomx", true, 0.5},
		Y_ZOOM_INC = {"shiftInternalValue", "zoomy", true, 2},
		Y_ZOOM_DEC = {"shiftInternalValue", "zoomy", true, 0.5},

		SEQ_TAB_UP = {"tabToSeq", -1},
		SEQ_TAB_DOWN = {"tabToSeq", 1},

		TOGGLE_PLAYING = {"togglePlaying"},

		MIDI_PANIC = {"haltAllSustains"},

		EXTROVERT_PLAY_NOTE = {"sendExtrovertTestNote", "testnote"},
		EXTROVERT_LOAD_FILE = {"sendExtrovertCommand", "loadmidi"},

	},

}