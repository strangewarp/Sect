
local D = {}

-- DATA VARS --
D.seq = {} -- Sequence-data table
D.keys = {} -- Keystroke-tracking table
D.overlay = {} -- Overlay-render tracking table
D.drawnotes = true -- Toggles whether to draw notes
D.recording = true -- Toggles whether note-recording is enabled

D.active = false -- Currently active sequence (false if nothing loaded)
D.tp = false -- Current tick-pointer position (false if nothing loaded)
D.np = false -- Current note-pointer position (false if nothing loaded)

D.tick = 1 -- Current tick occupied by the play-line position
D.playing = false -- Toggles whether the tickline is playing or not

-- LOADING VARS --
D.loadcmds = {} -- Holds all loading-screen messages
D.loadtext = "" -- Holds text from finished and active loading-screen cmds
D.loadnum = 1 -- Iterates through loading-screen cmds
D.loading = true -- True while loading; false after loading is done

-- HOTSEAT VARS --
D.activeseat = 1 -- Currently active hotseat-name

-- MIDI VARS --
D.bpm = 120 -- Beats per minute
D.tpq = 32 -- Ticks per quarter-note
D.chan = 0 -- Channel
D.velo = 127 -- Velocity
D.dur = 8 -- Duration
D.spacing = 8 -- Spacing

-- ZOOM VARS --
D.zoomx = 4 -- Multiplier for X-axis zoom
D.zoomy = 4 -- Multiplier for Y-axis zoom

-- UNDO VARS --
D.undo = {} -- Holds the stack of command-pairs accessed by undo
D.redo = {} -- Holds the stack of command-pairs accessed by redo

-- CANVAS VARS --
D.update = true -- Tracks whether the GUI should be redrawn

-- SELECTION VARS --
D.selbool = false -- Toggles whether a selection is active
D.seltop = { -- Top selection-pointer
	x = false,
	y = false,
}
D.selbot = { -- Bottom selection-pointer
	x = false,
	y = false,
}
D.sel = { -- Holds the boundaries of the currently selected area
	l = false, -- Left
	r = false, -- Right
	t = false, -- Top
	b = false, -- Bottom
}
D.seldat = {} -- Holds the notes that were selected for commands
D.copydat = {} -- Table for copied notes
D.selindex = {} -- Selected notes, indexed by [tick][note]

-- WHEEL VARS --
D.scales = {} -- All possible scales (built in wheel-funcs)
D.wheels = {} -- All possible wheels (built in wheel-funcs)

-- Baseline contents for new sequences
D.baseseq = {
	point = 1, -- Internal pointer, for playing decoupled from global tick
	overlay = false, -- Toggles whether the seq shadows other seqs
	tick = {}, -- Table that holds all ticks (each holds its own notes)
}

-- Boundaries for user-shiftable control variables
D.bounds = {
	bpm = {1, false, false}, -- Beats per minute
	tpq = {1, 1000, false}, -- Ticks per quarter-note
	np = {0, 127, true}, -- Note-pointer (active pitch)
	chan = {0, 15, true}, -- Channel
	velo = {0, 127, true}, -- Velocity
	dur = {1, false, false}, -- Duration
	spacing = {0, false, false}, -- Spacing
	zoomx = {1, 16, false}, -- X-axis zoom (tick axis)
	zoomy = {1, 16, false}, -- Y-axis zoom (note axis)
}

-- Types of MIDI commands that are accepted in a sequence,
-- and the corresponding values to display.
D.acceptmidi = {
	note = {5, 6},
	channel_after_touch = {4, 4},
	control_change = {4, 5},
	patch_change = {4, 4},
	key_after_touch = {4, 5},
	pitch_wheel_change = {4, 4},
	set_tempo = {3, 4},
}

-- Names of keys that start with "l"/"r", which collapse into single keys
D.sidekeys = {
	"lshift", "rshift",
	"lctrl", "rctrl",
	"lalt", "ralt",
}

-- Shapes and names of piano-keys
D.pianometa = {
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
}

-- Links between command-names and functions (with args as needed)
D.cmdfuncs = {

	LOAD_FILE = {"loadFile", false},
	SAVE_FILE = {"saveFile"},

	HOTSEAT_UP = {"moveHotseatPointer", -1},
	HOTSEAT_DOWN = {"moveHotseatPointer", 1},

	TOGGLE_SEQ_OVERLAY = {"toggleSeqOverlay"},
	TOGGLE_NOTE_DRAW = {"toggleNoteDraw"},

	TOGGLE_RECORDING = {"toggleRecording"},

	TOGGLE_WHEEL_MODE = {"toggleWheelMode"},
	TOGGLE_CHORDWHEEL_MODE = {"toggleChordWheelMode"},

	UNDO = {"traverseUndo", true},
	REDO = {"traverseUndo", false},

	INSERT_NOTE = {"insertNote", false, false},
	DELETE_NOTE = {"deleteNote", false},
	DELETE_TICK_NOTES = {"deleteTickNotes", false},
	DELETE_PITCH_NOTES = {"deletePitchNotes", false},
	DELETE_BEAT_NOTES = {"deleteBeatNotes", false},

	INSERT_TICKS = {"insertSpacingTicks", false},
	REMOVE_TICKS = {"removeSpacingTicks", false},

	INSERT_SEQ = {"addActiveSequence", false},
	REMOVE_SEQ = {"removeActiveSequence", false},

	TOGGLE_TOP = {"toggleSelect", "top"},
	TOGGLE_BOT = {"toggleSelect", "bottom"},
	CLEAR_SELECT_RANGE = {"toggleSelect", "clear"},
	CLEAR_SELECT_MEMORY = {"clearSelectMemory"},
	SELECT_ALL = {"toggleSelect", "all"},

	COPY = {"copySelection", false},
	COPY_ADD = {"copySelection", true},
	CUT = {"cutSelection", false, false},
	CUT_ADD = {"cutSelection", true, false},
	PASTE = {"pasteSelection", false},

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

	TPQ_UP = {"shiftInternalValue", "tpq", false, 1},
	TPQ_DOWN = {"shiftInternalValue", "tpq", false, -1},
	TPQ_UP_MULTI = {"shiftInternalValue", "tpq", false, 10},
	TPQ_DOWN_MULTI = {"shiftInternalValue", "tpq", false, -10},

	MOD_CHANNEL_UP = {"modActiveNoteChannel", 1, false},
	MOD_CHANNEL_DOWN = {"modActiveNoteChannel", -1, false},

	MOD_VELOCITY_UP = {"modActiveNoteVelocity", 1, false},
	MOD_VELOCITY_DOWN = {"modActiveNoteVelocity", -1, false},
	MOD_VELOCITY_UP_10 = {"modActiveNoteVelocity", 10, false},
	MOD_VELOCITY_DOWN_10 = {"modActiveNoteVelocity", -10, false},

	MOD_NOTE_UP = {"moveActiveNote", 0, 1, false},
	MOD_NOTE_DOWN = {"moveActiveNote", 0, -1, false},
	MOD_NOTE_LEFT = {"moveActiveNote", -1, 0, false},
	MOD_NOTE_RIGHT = {"moveActiveNote", 1, 0, false},

	MOD_SEQ_UP = {"moveActiveSeq", -1, false},
	MOD_SEQ_DOWN = {"moveActiveSeq", 1, false},

	POINTER_UP = {"shiftInternalValue", "np", false, 1},
	POINTER_DOWN = {"shiftInternalValue", "np", false, -1},
	POINTER_UP_OCTAVE = {"shiftInternalValue", "np", false, 12},
	POINTER_DOWN_OCTAVE = {"shiftInternalValue", "np", false, -12},
	POINTER_LEFT = {"moveTickPointer", -1},
	POINTER_RIGHT = {"moveTickPointer", 1},
	POINTER_LEFT_BEAT = {"moveTickPointerToBeat", -1},
	POINTER_RIGHT_BEAT = {"moveTickPointerToBeat", 1},

	X_ZOOM_INC = {"shiftInternalValue", "zoomx", true, 0.5},
	X_ZOOM_DEC = {"shiftInternalValue", "zoomx", true, 2},
	Y_ZOOM_INC = {"shiftInternalValue", "zoomy", true, 0.5},
	Y_ZOOM_DEC = {"shiftInternalValue", "zoomy", true, 2},

	SEQ_TAB_UP = {"tabActiveSeq", -1},
	SEQ_TAB_DOWN = {"tabActiveSeq", 1},

	MIDI_PANIC = {"haltAllSustains"},

	EXTROVERT_PLAY_NOTE = {"sendExtrovertTestNote", "testnote"},
	EXTROVERT_LOAD_FILE = {"sendExtrovertCommand", "loadmidi"},

}

return D
