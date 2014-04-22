
local D = {}

-- DATA VARS --
D.seq = {} -- Sequence-data table
D.keys = {} -- Keystroke-tracking table

D.active = false -- Currently active sequence (false if nothing loaded)
D.tp = false -- Current tick-pointer position (false if nothing loaded)
D.np = false -- Current note-pointer position (false if nothing loaded)

D.tick = 1 -- Current tick occupied by the play-line position
D.playing = false -- Toggles whether the tickline is playing or not

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
D.undo = {} -- Undo-function stack
D.redo = {} -- Redo-function stack
D.dotarget = "undo" -- Toggles whether undo-funcs go into undo- or redo-table
D.cmdundo = {false, false, true} -- Default undo-commands

-- CANVAS VARS --
D.update = true -- Tracks whether the GUI should be redrawn

-- SELECTION VARS --
D.ls = { -- Left selection-pointer
	x = false,
	y = false,
}
D.rs = { -- Right selection-pointer
	x = false,
	y = false,
}
D.sel = { -- Holds the boundaries of the currently selected area
	l = false, -- Left
	r = false, -- Right
	t = false, -- Top
	b = false, -- Bottom
}
D.copy = { -- Holds the boundaries of all combined additive copy commands
	l = false, -- Left
	r = false, -- Right
	t = false, -- Top
	b = false, -- Bottom
}
D.copyrel = { -- Holds the x,y boundaries of combined relative copy commands
	x = false,
	y = false,
}
D.movedat = {} -- Holds the notes that were selected for movement
D.copydat = {} -- Concrete positions of all copied notes
D.reldat = {} -- Relative positions of all copied notes

-- Baseline contents for new sequences
D.baseseq = {
	point = 1, -- Internal pointer, for playing decoupled from global tick
	mute = false, -- If sequence is muted, none of its notes will play
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

-- Types of MIDI commands that are accepted in a sequence
D.acceptmidi = {
	note = true,
	channel_after_touch = true,
	control_change = true,
	patch_change = true,
	key_after_touch = true,
	pitch_wheel_change = true,
	set_tempo = true,
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

	LOAD_FILE = {"loadFile", D.cmdundo},
	SAVE_FILE = {"saveFile"},
	LOAD_DIALOG = {"loadViaDialog", D.cmdundo},
	SAVE_DIALOG = {"saveViaDialog"},
	
	HOTSEAT_UP = {"moveHotseatPointer", -1},
	HOTSEAT_DOWN = {"moveHotseatPointer", 1},

	UNDO = {"traverseUndo", "undo"},
	REDO = {"traverseUndo", "redo"},

	INSERT_NOTE = {"insertNote", D.cmdundo},
	DELETE_NOTE = {"deleteNote", D.cmdundo},
	DELETE_TICK_NOTES = {"deleteTickNotes", D.cmdundo},
	DELETE_PITCH_NOTES = {"deletePitchNotes", D.cmdundo},
	DELETE_BEAT_NOTES = {"deleteBeatNotes", D.cmdundo},

	INSERT_TICKS = {"insertSpacingTicks", D.cmdundo},
	REMOVE_TICKS = {"removeSpacingTicks", D.cmdundo},

	INSERT_SEQ = {"addActiveSequence", D.cmdundo},
	REMOVE_SEQ = {"removeActiveSequence", D.cmdundo},

	TOGGLE_SELECTION = {"toggleSelectMode"},
	COPY_RELATIVE_ADD = {"copySelection", true, true},
	COPY_RELATIVE = {"copySelection", true, false},
	COPY_ABSOLUTE_ADD = {"copySelection", false, true},
	COPY_ABSOLUTE = {"copySelection", false, false},
	CUT_RELATIVE_ADD = {"cutSelection", true, true, D.cmdundo},
	CUT_RELATIVE = {"cutSelection", true, D.cmdundo},
	CUT_ABSOLUTE_ADD = {"cutSelection", false, true, D.cmdundo},
	CUT_ABSOLUTE = {"cutSelection", false, D.cmdundo},
	PASTE_RELATIVE = {"pasteSelection", true, D.cmdundo},
	PASTE = {"pasteSelection", false, D.cmdundo},

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

	TPQ_UP = {"shiftTicksAndRebalance", false, 1, D.cmdundo},
	TPQ_DOWN = {"shiftTicksAndRebalance", false, -1, D.cmdundo},
	TPQ_UP_MULTI = {"shiftTicksAndRebalance", true, 2, D.cmdundo},
	TPQ_DOWN_MULTI = {"shiftTicksAndRebalance", true, 0.5, D.cmdundo},

	MOD_CHANNEL_UP = {"modActiveNoteChannel", 1, D.cmdundo},
	MOD_CHANNEL_DOWN = {"modActiveNoteChannel", -1, D.cmdundo},

	MOD_VELOCITY_UP = {"modActiveNoteVelocity", 1, D.cmdundo},
	MOD_VELOCITY_DOWN = {"modActiveNoteVelocity", -1, D.cmdundo},
	MOD_VELOCITY_UP_10 = {"modActiveNoteVelocity", 10, D.cmdundo},
	MOD_VELOCITY_DOWN_10 = {"modActiveNoteVelocity", -10, D.cmdundo},

	MOD_NOTE_UP = {"moveActiveNote", 0, 1, D.cmdundo},
	MOD_NOTE_DOWN = {"moveActiveNote", 0, -1, D.cmdundo},
	MOD_NOTE_LEFT = {"moveActiveNote", -1, 0, D.cmdundo},
	MOD_NOTE_RIGHT = {"moveActiveNote", 1, 0, D.cmdundo},

	MOD_SEQ_UP = {"moveActiveSeq", -1, D.cmdundo},
	MOD_SEQ_DOWN = {"moveActiveSeq", 1, D.cmdundo},

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

}

return D
