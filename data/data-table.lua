
local T = {}

-- VERSIONING VARS --
T.version = "1.1-a108" -- Holds Sect's current version-number

-- LOVE ENGINE VARS --
T.updatespeed = 0.01 -- Speed at which to attempt to update program-state

-- DATA VARS --
T.seq = {} -- Sequence-data table
T.keys = {} -- Keystroke-tracking table
T.funcactive = false -- Keystroke-triggered-function-activity tracking flag
T.active = false -- Currently active sequence (false if nothing loaded)
T.tp = 0 -- Current tick-pointer position
T.np = 0 -- Current note-pointer position
T.cmdp = 1 -- Current Cmd Mode non-note-command pointer position
T.tick = 1 -- Current tick occupied by the play-line position

-- LOADING SCREEN VARS --
T.loadcmds = {} -- Holds all loading-screen messages
T.loadtext = "" -- Holds text from finished and active loading-screen cmds
T.loadnum = 1 -- Iterates through loading-screen cmds

-- SAVELOAD VARS --
T.saveok = false -- Controls whether it's OK to save to D.savepath
T.savemsg = "" -- Current save-popup message
T.savepopup = false -- Toggles whether a save-popup is visible
T.savedegrade = 0 -- Number of draw-updates before save popup vanishes
T.savestring = "" -- Holds user-entered savefile-name text
T.sfsp = 1 -- Pointer for text-entry into D.savestring
T.savevalid = false -- Tracks whether D.savestring matches a valid file

-- HOTSEAT VARS --
T.activeseat = 1 -- Currently active hotseat-name

-- MIDI VARS --
T.bpm = 120 -- Beats per minute
T.tpq = 24 -- Ticks per quarter-note
T.chan = 0 -- Channel
T.velo = 127 -- Velocity
T.dur = 24 -- Duration
T.spacing = 24 -- Spacing
T.cmdbyte1 = 0 -- First byte of non-NOTE commands
T.cmdbyte2 = 0 -- Second byte of non-NOTE commands
T.cmdtype = 1 -- Command type
T.cmdtypes = { -- Byte values, command names, and MIDI.lua key names
	{160, "aftertouch-key", "key_after_touch"},
	{176, "control", "control_change"},
	{192, "program", "patch_change"},
	{208, "aftertouch-chan", "channel_after_touch"},
	{224, "pitch-bend", "pitch_wheel_change"},
}

-- SOCKET VARS --
T.udpout = false -- Holds UDP-OUT socket
T.udpin = false -- Holds UDP-IN socket

-- ZOOM VARS --
T.cellwidth = 2 -- Horizontal pixels per cell
T.cellheight = 14 -- Vertical pixels per cell

-- UNDO VARS --
T.dostack = {} -- Holds all undo and redo command-blocks
T.undotarget = 0 -- Currently targeted undo-block

-- BEAT-FACTOR VARS --
T.factors = {} -- Factors of the current TPQ*4 value
T.fp = 1 -- Current factor-pointer position

-- SELECTION VARS --
T.selbool = false -- Toggles whether a selection is active
T.seltop = { -- Top selection-pointer
	x = false,
	y = false,
}
T.selbot = { -- Bottom selection-pointer
	x = false,
	y = false,
}
T.sel = { -- Holds the boundaries of the currently selected area
	l = false, -- Left
	r = false, -- Right
	t = false, -- Top
	b = false, -- Bottom
}
T.copyoffset = 0 -- Tick-distance that copydat is offset from D.tp
T.seldat = {} -- Holds the notes that were selected for commands
T.copydat = {} -- Table for copied notes

-- MOUSE VARS --
T.dragging = false -- True if mouse is dragging across screen
T.dragx = false -- Holds table of both x-bounds while dragging
T.dragy = false -- Holds table of both y-bounds while dragging

-- SCALE VARS --
T.scales = {} -- All possible scales (built in wheel-funcs)
T.wheels = {} -- All possible wheels (built in wheel-funcs)
T.scalenotes = {} -- Holds currently-used notes for scale comparison
T.threshbig = 0 -- Biggest note-consonance threshold

-- GENERATOR VARS --
T.kspecies = 7 -- Scale-size per 12 chromatic notes for melody generation
T.scalenum = 5 -- Number of scales to grab from the desired consonance-point
T.wheelnum = 2 -- Number of wheels to grab from the present wheel-species
T.consonance = 90 -- Melody scale consonance
T.scaleswitch = 20 -- Chance to switch scales, per note
T.wheelswitch = 20 -- Chance to switch wheels, per note
T.density = 60 -- Melody note-density
T.beatstick = 66 -- Likelihood for notes to favor major beats
T.beatlength = 24 -- Secondary beat length, decoupled from TPQ
T.beatbound = 1 -- Number of TPQ-based beats to fill with generated notes
T.beatgrain = 12 -- Smallest beatlength factor to which notes will stick
T.notegrain = 4 -- Minimum note size, in ticks

-- SEQ-PLAY VARS --
T.playoffset = 0 -- Holds the sub-delta time offset for tick-playing
T.playskip = 0 -- Holds the ticks to skip on the next frame of play-iterations

-- MODE VARS --
T.modenames = { -- Full names of the various mode types
	entry = "entry",
	gen = "generator",
	cmd = "cmd",
	saveload = "saveload",
}
T.cmdmode = "entry" -- Mode flag, for accepting certain command types
T.loading = true -- True while loading; false after loading is done
T.recording = true -- Toggles whether note-recording is enabled
T.playing = false -- Toggles whether to play through the seq's contents
T.drawnotes = true -- Toggles whether to draw notes
T.chanview = true -- Toggles rendering chan-nums on notes
T.entryquant = false -- Toggles auto-quantization of note-entry

-- GUI VARS --
T.width = 800 -- Global width
T.height = 600 -- Global height
T.rebuild = false -- Toggles whether to rebuild the GUI on next love.update tick
T.redraw = false -- Toggles whether to redraw the GUI to canvas on next love.draw tick
T.c = {} -- Holds various GUI constants
T.gui = { -- Table for saving pre-generated GUI elements
	piano = {}, -- Vertical piano-roll keys
	reticule = {}, -- Pointer-reticules and other reticule-layer polys
	save = {}, -- Saveload-panel elements
	sel = {}, -- Selection boxes
	seq = { -- Sequence-grid elements
		col = {}, -- Highlighted columns
		row = {}, -- Highlighted rows
		note = {}, -- Note-cells
		tri = {}, -- Beat-triangles
	},
	sidebar = { -- Sidebar elements
		text = {}, -- List of sidebar text-lines
	},
	track = { -- Track-bar elements
		cell = {}, -- Sequence-cells
		cursor = {}, -- Active-sequence reticule
	},
}
T.renderorder = { -- Render-order for GUI-note types. Higher numbers = rendered last.
	shadow = 1,
	other_chan = 2,
	normal = 3,
	sel = 4,
}
T.gradients = { -- Gradients to build within the D.color table
	{"note", "normal_quiet", "normal", "normal_gradient"},
	{"note", "highlight_quiet", "highlight", "highlight_gradient"},
	{"note", "sel_quiet", "sel", "sel_gradient"},
	{"note", "shadow_quiet", "shadow", "shadow_gradient"},
	{"note", "other_chan_quiet", "other_chan", "other_chan_gradient"},
	{"save", "background", "background_fade", "background_gradient"},
	{"seq", "beat_dark", "beat_light", "beat_gradient"},
	{"summary", "empty", "full", "gradient"},
}

-- Baseline contents for new sequences
T.baseseq = {
	overlay = false, -- Toggles whether the seq shadows other seqs
	tick = {}, -- Holds all populated ticks (each holds its own notes)
	total = 0, -- Tracks the total size of the sequence, in ticks
}

-- Boundaries for user-shiftable control vars
T.bounds = {

	-- Misc bounds --
	bpm = {1, math.huge, false}, -- Beats per minute
	tpq = {1, 1000, false}, -- Ticks per quarter-note
	spacing = {0, math.huge, false}, -- Movement spacing

	-- MIDI NOTE bounds --
	np = {0, 127, true}, -- Note-pointer (active pitch)
	chan = {0, 15, true}, -- Channel
	velo = {0, 127, true}, -- Velocity
	dur = {1, math.huge, false}, -- Duration

	-- MIDI non-NOTE bounds --
	cmdbyte1 = {0, 127, true}, -- First byte of non-NOTE commands
	cmdbyte2 = {0, 127, true}, -- Second byte of non-NOTE commands

	-- Zoom bounds --
	cellwidth = {0.25, 16, false}, -- X-axis zoom (tick axis)
	cellheight = {2, 32, false}, -- Y-axis zoom (note axis)

	-- Generator bounds --
	kspecies = {1, 7, true}, -- Filled scale notes
	scalenum = {1, math.huge, false}, -- Grab-scales in generator
	wheelnum = {1, math.huge, false}, -- Grab-wheels in generator
	consonance = {0, 100, true}, -- Target consonance for generator
	scaleswitch = {0, 100, true}, -- Likelihood to switch between scales
	wheelswitch = {0, 100, true}, -- Likelihood to switch between wheels
	density = {0, 100, true}, -- Density of note coverage
	beatstick = {0, 100, true}, -- Likelihood to stick to major beats
	beatgrain = {1, math.huge, false}, -- Smallest sticky beat
	beatlength = {1, math.huge, false}, -- Secondary beat length
	beatbound = {1, math.huge, false}, -- Number of TPQ-beats to fill
	notegrain = {1, math.huge, false}, -- Minimum note size

}

-- Note-bytes that correspond to modNote command names
T.notebytes = {
	tp = 2,
	dur = 3,
	chan = 4,
	np = 5,
	velo = 6,
}

-- Types of MIDI commands that are accepted in a sequence,
-- and the corresponding values to display.
T.acceptmidi = {
	note = {5, 6},
	channel_after_touch = {4, 4},
	control_change = {4, 5},
	patch_change = {4, 4},
	key_after_touch = {4, 5},
	pitch_wheel_change = {4, 4},
}

-- Names of keys that start with "l"/"r", which collapse into single keys
T.sidekeys = {
	"lshift", "rshift",
	"lctrl", "rctrl",
	"lalt", "ralt",
}

-- Shapes and names of piano-keys
T.pianometa = {
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
T.cmdfuncs = {

	LOAD_HOTSEAT_FILE = {"loadFile", false, false},
	SAVE_FILE_TO_HOTSEAT = {"saveFile", false},

	TOGGLE_SAVELOAD_MODE = {"toggleSaveLoad"},
	ESCAPE_SAVELOAD_MODE = {"toggleSaveLoad"},
	SL_POINTER_LEFT = {"moveSavePointer", -1},
	SL_POINTER_RIGHT = {"moveSavePointer", 1},
	SL_CHAR_BACKSPACE = {"removeSaveChar", -1},
	SL_CHAR_DELETE = {"removeSaveChar", 1},
	LOAD_SL_FILE = {"loadSLStringFile", false},
	SAVE_SL_FILE = {"saveSLStringFile"},
	SET_SAVE_PATH = {"setUserSavePath"},

	TOGGLE_SEQ_OVERLAY = {"toggleSeqOverlay"},
	TOGGLE_NOTE_DRAW = {"toggleNoteDraw"},
	TOGGLE_CHAN_NUM_VIEW = {"toggleChanNumView"},

	TOGGLE_RECORDING = {"toggleRecording"},

	TOGGLE_ENTRY_QUANTIZE = {"toggleEntryQuantize"},

	TOGGLE_PLAY_MODE = {"togglePlayMode"},
	TOGGLE_GENERATOR_MODE = {"toggleGeneratorMode"},
	TOGGLE_CMD_MODE = {"toggleCmdMode"},

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
	SELECT_ALL = {"toggleSelect", "all"},
	SELECT_CHAN = {"toggleSelect", "chan"},
	CLEAR_SELECT_RANGE = {"toggleSelect", "clear"},
	CLEAR_SELECT_MEMORY = {"clearSelectMemory"},

	COPY = {"copySelection"},
	CUT = {"cutSelection", false},
	PASTE = {"pasteSelection", false},
	PASTE_REPEATING = {"pasteRepeating", false},
	PASTE_FROM_TEXT_MONO = {"pasteFromText", "mono", false},
	PASTE_FROM_TEXT_POLY = {"pasteFromText", "poly", false},

	HUMANIZE = {"humanizeNotes", false},
	QUANTIZE = {"quantizeNotes", false},
	STRETCH = {"dynamicStretch", false},

	KSPECIES_UP = {"shiftInternalValue", "kspecies", false, 1},
	KSPECIES_DOWN = {"shiftInternalValue", "kspecies", false, -1},

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

	FACTOR_UP = {"shiftFactorKey", 1},
	FACTOR_DOWN = {"shiftFactorKey", -1},

	SCALENUM_UP = {"shiftInternalValue", "scalenum", false, 1},
	SCALENUM_DOWN = {"shiftInternalValue", "scalenum", false, -1},

	WHEELNUM_UP = {"shiftInternalValue", "wheelnum", false, 1},
	WHEELNUM_DOWN = {"shiftInternalValue", "wheelnum", false, -1},

	CONSONANCE_UP = {"shiftInternalValue", "consonance", false, 1},
	CONSONANCE_DOWN = {"shiftInternalValue", "consonance", false, -1},
	CONSONANCE_UP_10 = {"shiftInternalValue", "consonance", false, 10},
	CONSONANCE_DOWN_10 = {"shiftInternalValue", "consonance", false, -10},

	SCALE_SWITCH_UP = {"shiftInternalValue", "scaleswitch", false, 1},
	SCALE_SWITCH_DOWN = {"shiftInternalValue", "scaleswitch", false, -1},
	SCALE_SWITCH_UP_10 = {"shiftInternalValue", "scaleswitch", false, 10},
	SCALE_SWITCH_DOWN_10 = {"shiftInternalValue", "scaleswitch", false, -10},

	WHEEL_SWITCH_UP = {"shiftInternalValue", "wheelswitch", false, 1},
	WHEEL_SWITCH_DOWN = {"shiftInternalValue", "wheelswitch", false, -1},
	WHEEL_SWITCH_UP_10 = {"shiftInternalValue", "wheelswitch", false, 10},
	WHEEL_SWITCH_DOWN_10 = {"shiftInternalValue", "wheelswitch", false, -10},

	DENSITY_UP = {"shiftInternalValue", "density", false, 1},
	DENSITY_DOWN = {"shiftInternalValue", "density", false, -1},
	DENSITY_UP_10 = {"shiftInternalValue", "density", false, 10},
	DENSITY_DOWN_10 = {"shiftInternalValue", "density", false, -10},

	BEAT_STICK_UP = {"shiftInternalValue", "beatstick", false, 1},
	BEAT_STICK_DOWN = {"shiftInternalValue", "beatstick", false, -1},
	BEAT_STICK_UP_10 = {"shiftInternalValue", "beatstick", false, 10},
	BEAT_STICK_DOWN_10 = {"shiftInternalValue", "beatstick", false, -10},

	BEAT_LENGTH_UP = {"shiftInternalValue", "beatlength", false, 1},
	BEAT_LENGTH_DOWN = {"shiftInternalValue", "beatlength", false, -1},
	BEAT_LENGTH_UP_MULTI = {"shiftInternalValue", "beatlength", true, 2},
	BEAT_LENGTH_DOWN_MULTI = {"shiftInternalValue", "beatlength", true, 0.5},

	BEAT_BOUND_UP = {"shiftInternalValue", "beatbound", false, 1},
	BEAT_BOUND_DOWN = {"shiftInternalValue", "beatbound", false, -1},

	BEAT_GRAIN_UP = {"shiftInternalValue", "beatgrain", false, 1},
	BEAT_GRAIN_DOWN = {"shiftInternalValue", "beatgrain", false, -1},
	BEAT_GRAIN_UP_MULTI = {"shiftInternalValue", "beatgrain", true, 2},
	BEAT_GRAIN_DOWN_MULTI = {"shiftInternalValue", "beatgrain", true, 0.5},

	NOTE_GRAIN_UP = {"shiftInternalValue", "notegrain", false, 1},
	NOTE_GRAIN_DOWN = {"shiftInternalValue", "notegrain", false, -1},
	NOTE_GRAIN_UP_MULTI = {"shiftInternalValue", "notegrain", true, 2},
	NOTE_GRAIN_DOWN_MULTI = {"shiftInternalValue", "notegrain", true, 0.5},

	MOD_DUR_INCREASE = {"modSelectedNotes", "dur", 1, false},
	MOD_DUR_DECREASE = {"modSelectedNotes", "dur", -1, false},

	MOD_CHANNEL_UP = {"modSelectedNotes", "chan", 1, false},
	MOD_CHANNEL_DOWN = {"modSelectedNotes", "chan", -1, false},

	MOD_VELOCITY_UP = {"modSelectedNotes", "velo", 1, false},
	MOD_VELOCITY_DOWN = {"modSelectedNotes", "velo", -1, false},
	MOD_VELOCITY_UP_10 = {"modSelectedNotes", "velo", 10, false},
	MOD_VELOCITY_DOWN_10 = {"modSelectedNotes", "velo", -10, false},

	MOD_NOTE_UP = {"modSelectedNotes", "np", 1, false},
	MOD_NOTE_DOWN = {"modSelectedNotes", "np", -1, false},
	MOD_NOTE_LEFT = {"modSelectedNotes", "tp", -1, false},
	MOD_NOTE_RIGHT = {"modSelectedNotes", "tp", 1, false},

	MOD_SEQ_UP = {"moveActiveSequence", -1, false},
	MOD_SEQ_DOWN = {"moveActiveSequence", 1, false},

	POINTER_UP = {"shiftInternalValue", "np", false, 1},
	POINTER_DOWN = {"shiftInternalValue", "np", false, -1},
	POINTER_UP_OCTAVE = {"shiftInternalValue", "np", false, 12},
	POINTER_DOWN_OCTAVE = {"shiftInternalValue", "np", false, -12},
	POINTER_LEFT = {"moveTickPointer", -1},
	POINTER_RIGHT = {"moveTickPointer", 1},
	POINTER_LEFT_BEAT = {"moveTickPointerToBeat", -1},
	POINTER_RIGHT_BEAT = {"moveTickPointerToBeat", 1},
	POINTER_PREV_NOTE = {"moveTickPointerByNote", -1},
	POINTER_NEXT_NOTE = {"moveTickPointerByNote", 1},

	X_ZOOM_INC = {"shiftInternalValue", "cellwidth", false, 0.25},
	X_ZOOM_DEC = {"shiftInternalValue", "cellwidth", false, -0.25},
	Y_ZOOM_INC = {"shiftInternalValue", "cellheight", false, 1},
	Y_ZOOM_DEC = {"shiftInternalValue", "cellheight", false, -1},

	SEQ_TAB_UP = {"tabActiveSequence", -1},
	SEQ_TAB_DOWN = {"tabActiveSequence", 1},
	SEQ_TAB_UP_10 = {"tabActiveSequence", -10},
	SEQ_TAB_DOWN_10 = {"tabActiveSequence", 10},

	CMD_POINTER_UP = {"moveCmdPointer", 1},
	CMD_POINTER_DOWN = {"moveCmdPointer", -1},

	CMD_TYPE_UP = {"shiftCmdType", 1},
	CMD_TYPE_DOWN = {"shiftCmdType", -1},

	CMD_BYTE_1_UP = {"shiftInternalValue", "cmdbyte1", false, 1},
	CMD_BYTE_1_DOWN = {"shiftInternalValue", "cmdbyte1", false, -1},
	CMD_BYTE_1_UP_10 = {"shiftInternalValue", "cmdbyte1", false, 10},
	CMD_BYTE_1_DOWN_10 = {"shiftInternalValue", "cmdbyte1", false, -10},

	CMD_BYTE_2_UP = {"shiftInternalValue", "cmdbyte2", false, 1},
	CMD_BYTE_2_DOWN = {"shiftInternalValue", "cmdbyte2", false, -1},
	CMD_BYTE_2_UP_10 = {"shiftInternalValue", "cmdbyte2", false, 10},
	CMD_BYTE_2_DOWN_10 = {"shiftInternalValue", "cmdbyte2", false, -10},

}

-- Modes in which a given command will take effect
T.cmdgate = {

	LOAD_HOTSEAT_FILE = {"entry", "gen", "cmd"},
	SAVE_FILE_TO_HOTSEAT = {"entry", "gen", "cmd"},

	TOGGLE_SAVELOAD_MODE = {"entry", "gen", "cmd"},
	ESCAPE_SAVELOAD_MODE = {"saveload"},
	SL_POINTER_LEFT = {"saveload"},
	SL_POINTER_RIGHT = {"saveload"},
	SL_CHAR_BACKSPACE = {"saveload"},
	SL_CHAR_DELETE = {"saveload"},
	LOAD_SL_FILE = {"saveload"},
	SAVE_SL_FILE = {"saveload"},
	SET_SAVE_PATH = {"saveload"},

	TOGGLE_SEQ_OVERLAY = {"entry", "gen", "cmd"},
	TOGGLE_NOTE_DRAW = {"entry", "gen", "cmd"},
	TOGGLE_CHAN_NUM_VIEW = {"entry", "gen", "cmd"},

	TOGGLE_RECORDING = {"entry", "gen", "cmd"},

	TOGGLE_ENTRY_QUANTIZE = {"entry", "gen", "cmd"},

	TOGGLE_PLAY_MODE = {"entry", "gen", "cmd"},
	TOGGLE_GENERATOR_MODE = {"entry", "gen", "cmd"},
	TOGGLE_CMD_MODE = {"entry", "gen", "cmd"},

	UNDO = {"entry", "gen", "cmd"},
	REDO = {"entry", "gen", "cmd"},

	INSERT_NOTE = {"entry", "gen", "cmd"},
	DELETE_NOTE = {"entry", "gen", "cmd"},
	DELETE_TICK_NOTES = {"entry", "gen", "cmd"},
	DELETE_PITCH_NOTES = {"entry", "gen"},
	DELETE_BEAT_NOTES = {"entry", "gen", "cmd"},

	INSERT_TICKS = {"entry", "gen", "cmd"},
	REMOVE_TICKS = {"entry", "gen", "cmd"},

	INSERT_SEQ = {"entry", "gen", "cmd"},
	REMOVE_SEQ = {"entry", "gen", "cmd"},

	TOGGLE_TOP = {"entry", "gen"},
	TOGGLE_BOT = {"entry", "gen"},
	SELECT_ALL = {"entry", "gen"},
	SELECT_CHAN = {"entry", "gen"},
	CLEAR_SELECT_RANGE = {"entry", "gen"},
	CLEAR_SELECT_MEMORY = {"entry", "gen"},

	COPY = {"entry", "gen"},
	CUT = {"entry", "gen"},
	PASTE = {"entry", "gen"},
	PASTE_REPEATING = {"entry", "gen"},
	PASTE_FROM_TEXT_MONO = {"entry", "gen"},
	PASTE_FROM_TEXT_POLY = {"entry", "gen"},

	HUMANIZE = {"entry", "gen"},
	QUANTIZE = {"entry", "gen"},
	STRETCH = {"entry", "gen"},

	CHANNEL_UP = {"entry", "gen", "cmd"},
	CHANNEL_DOWN = {"entry", "gen", "cmd"},

	VELOCITY_UP = {"entry", "gen"},
	VELOCITY_DOWN = {"entry", "gen"},
	VELOCITY_UP_10 = {"entry", "gen"},
	VELOCITY_DOWN_10 = {"entry", "gen"},

	DURATION_UP = {"entry", "gen"},
	DURATION_DOWN = {"entry", "gen"},
	DURATION_UP_MULTI = {"entry", "gen"},
	DURATION_DOWN_MULTI = {"entry", "gen"},

	SPACING_UP = {"entry", "gen", "cmd"},
	SPACING_DOWN = {"entry", "gen", "cmd"},
	SPACING_UP_MULTI = {"entry", "gen", "cmd"},
	SPACING_DOWN_MULTI = {"entry", "gen", "cmd"},

	BPM_UP = {"entry", "gen", "cmd"},
	BPM_DOWN = {"entry", "gen", "cmd"},
	BPM_UP_10 = {"entry", "gen", "cmd"},
	BPM_DOWN_10 = {"entry", "gen", "cmd"},

	TPQ_UP = {"entry", "gen", "cmd"},
	TPQ_DOWN = {"entry", "gen", "cmd"},
	TPQ_UP_MULTI = {"entry", "gen", "cmd"},
	TPQ_DOWN_MULTI = {"entry", "gen", "cmd"},

	FACTOR_UP = {"entry", "gen", "cmd"},
	FACTOR_DOWN = {"entry", "gen", "cmd"},

	KSPECIES_UP = {"gen"},
	KSPECIES_DOWN = {"gen"},

	SCALENUM_UP = {"gen"},
	SCALENUM_DOWN = {"gen"},

	WHEELNUM_UP = {"gen"},
	WHEELNUM_DOWN = {"gen"},

	CONSONANCE_UP = {"gen"},
	CONSONANCE_DOWN = {"gen"},
	CONSONANCE_UP_10 = {"gen"},
	CONSONANCE_DOWN_10 = {"gen"},

	SCALE_SWITCH_UP = {"gen"},
	SCALE_SWITCH_DOWN = {"gen"},
	SCALE_SWITCH_UP_10 = {"gen"},
	SCALE_SWITCH_DOWN_10 = {"gen"},

	WHEEL_SWITCH_UP = {"gen"},
	WHEEL_SWITCH_DOWN = {"gen"},
	WHEEL_SWITCH_UP_10 = {"gen"},
	WHEEL_SWITCH_DOWN_10 = {"gen"},

	DENSITY_UP = {"gen"},
	DENSITY_DOWN = {"gen"},
	DENSITY_UP_10 = {"gen"},
	DENSITY_DOWN_10 = {"gen"},

	BEAT_STICK_UP = {"gen"},
	BEAT_STICK_DOWN = {"gen"},
	BEAT_STICK_UP_10 = {"gen"},
	BEAT_STICK_DOWN_10 = {"gen"},

	BEAT_LENGTH_UP = {"gen"},
	BEAT_LENGTH_DOWN = {"gen"},
	BEAT_LENGTH_UP_MULTI = {"gen"},
	BEAT_LENGTH_DOWN_MULTI = {"gen"},

	BEAT_BOUND_UP = {"gen"},
	BEAT_BOUND_DOWN = {"gen"},

	BEAT_GRAIN_UP = {"gen"},
	BEAT_GRAIN_DOWN = {"gen"},
	BEAT_GRAIN_UP_MULTI = {"gen"},
	BEAT_GRAIN_DOWN_MULTI = {"gen"},

	NOTE_GRAIN_UP = {"gen"},
	NOTE_GRAIN_DOWN = {"gen"},
	NOTE_GRAIN_UP_MULTI = {"gen"},
	NOTE_GRAIN_DOWN_MULTI = {"gen"},

	MOD_DUR_INCREASE = {"entry", "gen"},
	MOD_DUR_DECREASE = {"entry", "gen"},

	MOD_CHANNEL_UP = {"entry", "gen"},
	MOD_CHANNEL_DOWN = {"entry", "gen"},

	MOD_VELOCITY_UP = {"entry", "gen"},
	MOD_VELOCITY_DOWN = {"entry", "gen"},
	MOD_VELOCITY_UP_10 = {"entry", "gen"},
	MOD_VELOCITY_DOWN_10 = {"entry", "gen"},

	MOD_NOTE_UP = {"entry", "gen"},
	MOD_NOTE_DOWN = {"entry", "gen"},
	MOD_NOTE_LEFT = {"entry", "gen"},
	MOD_NOTE_RIGHT = {"entry", "gen"},

	MOD_SEQ_UP = {"entry", "gen"},
	MOD_SEQ_DOWN = {"entry", "gen"},

	POINTER_UP = {"entry", "gen"},
	POINTER_DOWN = {"entry", "gen"},
	POINTER_UP_OCTAVE = {"entry", "gen"},
	POINTER_DOWN_OCTAVE = {"entry", "gen"},
	POINTER_LEFT = {"entry", "gen", "cmd"},
	POINTER_RIGHT = {"entry", "gen", "cmd"},
	POINTER_LEFT_BEAT = {"entry", "gen", "cmd"},
	POINTER_RIGHT_BEAT = {"entry", "gen", "cmd"},
	POINTER_PREV_NOTE = {"entry", "gen"},
	POINTER_NEXT_NOTE = {"entry", "gen"},

	X_ZOOM_INC = {"entry", "gen", "cmd"},
	X_ZOOM_DEC = {"entry", "gen", "cmd"},
	Y_ZOOM_INC = {"entry", "gen", "cmd"},
	Y_ZOOM_DEC = {"entry", "gen", "cmd"},

	SEQ_TAB_UP = {"entry", "gen", "cmd"},
	SEQ_TAB_DOWN = {"entry", "gen", "cmd"},
	SEQ_TAB_UP_10 = {"entry", "gen", "cmd"},
	SEQ_TAB_DOWN_10 = {"entry", "gen", "cmd"},

	CMD_POINTER_UP = {"cmd"},
	CMD_POINTER_DOWN = {"cmd"},

	CMD_TYPE_UP = {"cmd"},
	CMD_TYPE_DOWN = {"cmd"},

	CMD_BYTE_1_UP = {"cmd"},
	CMD_BYTE_1_DOWN = {"cmd"},
	CMD_BYTE_1_UP_10 = {"cmd"},
	CMD_BYTE_1_DOWN_10 = {"cmd"},

	CMD_BYTE_2_UP = {"cmd"},
	CMD_BYTE_2_DOWN = {"cmd"},
	CMD_BYTE_2_UP_10 = {"cmd"},
	CMD_BYTE_2_DOWN_10 = {"cmd"},

}

-- Functions that incur undo-block formation when called by keystrokes
T.undocmds = {

	-- cmd-funcs.lua
	["setCmd"] = true,
	["setCmds"] = true,

	-- data-funcs.lua
	["growSeq"] = true,
	["shrinkSeq"] = true,
	["insertTicks"] = true,
	["removeTicks"] = true,
	["insertSpacingTicks"] = true,
	["removeSpacingTicks"] = true,
	["addSequence"] = true,
	["removeSequence"] = true,
	["addActiveSequence"] = true,
	["removeActiveSequence"] = true,
	["switchSequences"] = true,
	["moveActiveSequence"] = true,

	-- file-funcs.lua
	["loadFile"] = true,
	["loadSLStringFile"] = true,
	["saveSLStringFile"] = true,

	-- generator-funcs.lua
	["generateSeqNotes"] = true,

	-- modify-funcs.lua
	["modSelectedNotes"] = true,
	["modCmds"] = true,
	["modNotes"] = true,
	["modByte"] = true,
	["humanizeNotes"] = true,
	["quantizeNotes"] = true,
	["dynamicStretch"] = true,

	-- note-funcs.lua
	["setNotes"] = true,
	["insertNote"] = true,
	["deleteNote"] = true,
	["deleteTickNotes"] = true,
	["deletePitchNotes"] = true,
	["deleteBeatNotes"] = true,

	-- select-funcs.lua
	["cutSelection"] = true,
	["pasteSelection"] = true,
	["pasteRepeating"] = true,
	["pasteFromText"] = true,

}

-- Functions that are allowed when D.active is false
T.inactivecmds = {
	
	["addSequence"] = true,
	["addActiveSequence"] = true,
	["toggleSaveLoad"] = true,
	["setUserSavePath"] = true,
	["loadFile"] = true,
	["loadSLStringFile"] = true,
	["shiftInternalValue"] = true,
	["tabToHotseat"] = true,
	["traverseUndo"] = true,

}

return T
