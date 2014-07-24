
local D = {}

-- LOVE ENGINE VARS --
D.updatespeed = 0.01 -- Speed at which to attempt to update program-state

-- DATA VARS --
D.seq = {} -- Sequence-data table
D.keys = {} -- Keystroke-tracking table
D.overlay = {} -- Overlay-render tracking table
D.active = false -- Currently active sequence (false if nothing loaded)
D.tp = 0 -- Current tick-pointer position
D.np = 0 -- Current note-pointer position
D.tick = 1 -- Current tick occupied by the play-line position
D.playing = false -- Toggles whether the tickline is playing or not

-- LOADING SCREEN VARS --
D.loadcmds = {} -- Holds all loading-screen messages
D.loadtext = "" -- Holds text from finished and active loading-screen cmds
D.loadnum = 1 -- Iterates through loading-screen cmds

-- SAVEFILE VARS --
D.saveok = false -- Controls whether it's OK to save to data.savepath

-- HOTSEAT VARS --
D.activeseat = 1 -- Currently active hotseat-name

-- MIDI VARS --
D.bpm = 120 -- Beats per minute
D.tpq = 24 -- Ticks per quarter-note
D.chan = 0 -- Channel
D.velo = 127 -- Velocity
D.dur = 24 -- Duration
D.spacing = 24 -- Spacing

-- SOCKET VARS --
D.udpout = false -- Holds UDP-OUT socket

-- ZOOM VARS --
D.cellwidth = 2 -- Horizontal pixels per cell
D.cellheight = 14 -- Vertical pixels per cell
D.pianowidth = 0 -- Holds updated width of piano-bar

-- UNDO VARS --
D.dostack = {} -- Holds all undo and redo command-blocks
D.undotarget = 0 -- Currently targeted undo-block

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

-- MOUSE VARS --
D.dragging = false -- True if mouse is dragging across screen
D.dragx = false -- Holds table of both x-bounds while dragging
D.dragy = false -- Holds table of both y-bounds while dragging

-- SCALE VARS --
D.scales = {} -- All possible scales (built in wheel-funcs)
D.wheels = {} -- All possible wheels (built in wheel-funcs)
D.scalenotes = {} -- Holds currently-used notes for scale comparison
D.threshbig = 0 -- Biggest note-consonance threshold

-- GENERATOR VARS --
D.kspecies = 7 -- Scale-size per 12 chromatic notes for melody generation
D.scalenum = 5 -- Number of scales to grab from the desired consonance-point
D.wheelnum = 2 -- Number of wheels to grab from the present wheel-species
D.consonance = 90 -- Melody scale consonance
D.scaleswitch = 20 -- Chance to switch scales, per note
D.wheelswitch = 20 -- Chance to switch wheels, per note
D.density = 60 -- Melody note-density
D.beatstick = 66 -- Likelihood for notes to favor major beats
D.beatlength = 24 -- Secondary beat length, decoupled from TPQ
D.beatbound = 1 -- Number of TPQ-based beats to fill with generated notes
D.beatgrain = 12 -- Smallest beatlength factor to which notes will stick
D.notegrain = 4 -- Minimum note size, in ticks

-- SEQ-PLAY VARS --
D.playoffset = 0 -- Holds the sub-delta time offset for tick-playing

-- MODE VARS --
D.cmdmodes = { -- Mode flags for accepting certain command types
	base = true, -- Accept base-commands
	entry = true, -- Accept Entry Mode commands
	gen = false, -- Accept Generator Mode commands
}
D.loading = true -- True while loading; false after loading is done
D.recording = true -- Toggles whether note-recording is enabled
D.playing = false -- Toggles whether to play through the seq's contents
D.drawnotes = true -- Toggles whether to draw notes
D.chanview = true -- Toggles rendering chan-nums on notes

-- Baseline contents for new sequences
D.baseseq = {
	overlay = false, -- Toggles whether the seq shadows other seqs
	tick = {}, -- Table that holds all ticks (each holds its own notes)
}

-- Boundaries for user-shiftable control vars
D.bounds = {

	-- Misc bounds --
	bpm = {1, math.huge, false}, -- Beats per minute
	tpq = {1, 1000, false}, -- Ticks per quarter-note
	spacing = {0, math.huge, false}, -- Movement spacing

	-- MIDI-Note bounds --
	np = {0, 127, true}, -- Note-pointer (active pitch)
	chan = {0, 15, true}, -- Channel
	velo = {0, 127, true}, -- Velocity
	dur = {1, math.huge, false}, -- Duration

	-- Zoom bounds --
	cellwidth = {0.25, 16, false}, -- X-axis zoom (tick axis)
	cellheight = {2, 32, false}, -- Y-axis zoom (note axis)

	-- Generator bounds --
	kspecies = {1, 8, true}, -- Filled scale notes
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

	TOGGLE_SEQ_OVERLAY = {"toggleSeqOverlay"},
	TOGGLE_NOTE_DRAW = {"toggleNoteDraw"},
	TOGGLE_RECORDING = {"toggleRecording"},
	TOGGLE_GENERATOR_MODE = {"toggleGeneratorMode"},
	TOGGLE_PLAY_MODE = {"togglePlayMode"},
	TOGGLE_CHAN_NUM_VIEW = {"toggleChanNumView"},

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
	CLEAR_SELECT_RANGE = {"toggleSelect", "clear"},
	CLEAR_SELECT_MEMORY = {"clearSelectMemory"},

	COPY = {"copySelection", false},
	COPY_ADD = {"copySelection", true},
	CUT = {"cutSelection", false, false},
	CUT_ADD = {"cutSelection", true, false},
	PASTE = {"pasteSelection", false},

	HUMANIZE = {"humanizeNotes", false},

	KSPECIES_UP = {"shiftInternalValue", "kspecies", false, 1},
	KSPECIES_DOWN = {"shiftInternalValue", "kspecies", false, -1},
	NOTECOMP_UP = {"shiftInternalValue", "notecompare", false, 1},
	NOTECOMP_DOWN = {"shiftInternalValue", "notecompare", false, -1},

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

	KSPECIES_UP = {"shiftInternalValue", "kspecies", false, 1},
	KSPECIES_DOWN = {"shiftInternalValue", "kspecies", false, -1},

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

	MOD_DUR_INCREASE = {"modNotes", "dur", 1, false},
	MOD_DUR_DECREASE = {"modNotes", "dur", -1, false},

	MOD_CHANNEL_UP = {"modNotes", "chan", 1, false},
	MOD_CHANNEL_DOWN = {"modNotes", "chan", -1, false},

	MOD_VELOCITY_UP = {"modNotes", "velo", 1, false},
	MOD_VELOCITY_DOWN = {"modNotes", "velo", -1, false},
	MOD_VELOCITY_UP_10 = {"modNotes", "velo", 10, false},
	MOD_VELOCITY_DOWN_10 = {"modNotes", "velo", -10, false},

	MOD_NOTE_UP = {"modNotes", "np", 1, false},
	MOD_NOTE_DOWN = {"modNotes", "np", -1, false},
	MOD_NOTE_LEFT = {"modNotes", "tp", -1, false},
	MOD_NOTE_RIGHT = {"modNotes", "tp", 1, false},

	MOD_SEQ_UP = {"moveActiveSequence", -1, false},
	MOD_SEQ_DOWN = {"moveActiveSequence", 1, false},

	POINTER_UP = {"shiftInternalValue", "np", false, 1, false},
	POINTER_DOWN = {"shiftInternalValue", "np", false, -1, false},
	POINTER_UP_OCTAVE = {"shiftInternalValue", "np", false, 12, false},
	POINTER_DOWN_OCTAVE = {"shiftInternalValue", "np", false, -12, false},
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

	SEQ_TAB_UP = {"tabActiveSeq", -1},
	SEQ_TAB_DOWN = {"tabActiveSeq", 1},
	SEQ_TAB_UP_10 = {"tabActiveSeq", -10},
	SEQ_TAB_DOWN_10 = {"tabActiveSeq", 10},

	EXTROVERT_LOAD_FILE = {"sendExtrovertCommand", "loadmidi"},

}

-- Functions that incur undo-block formation when called by keystrokes
D.undocmds = {

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

	-- generator-funcs.lua
	["generateSeqNotes"] = true,

	-- note-funcs.lua
	["setNotes"] = true,
	["moveNotes"] = true,
	["insertNote"] = true,
	["deleteNote"] = true,
	["deleteTickNotes"] = true,
	["deletePitchNotes"] = true,
	["deleteBeatNotes"] = true,
	["humanizeNotes"] = true,

	-- select-funcs.lua
	["cutSelection"] = true,
	["pasteSelection"] = true,
	["modNotes"] = true,

}

return D
