return {
	
	-- Port for communication with Extrovert
	oscport = 8500,

	-- Path where savefiles are stored
	savepath = "C:/Users/Christian/Documents/MUSIC_STAGING/",

	-- Undo depth
	maxundo = 100,

	hotseats = { -- Names of savefiles that are tabled for quick loading

		"default",
		"default",
		"default",
		"default",
		"default",

		"default",
		"default",
		"default",
		"default",
		"default",

		"default",
		"default",
		"default",
		"default",
		"default",

		"default",
		"default",
		"default",
		"default",
		"default",

	},

	color = { -- GUI colors, in format {R, G, B, Alpha}

		window = { -- Window pane colors
			dark = {70, 70, 80, 255},
			mid = {100, 100, 110, 255},
			light = {150, 150, 160, 255},
		},

		font = { -- Font colors
			dark = {170, 170, 160, 255},
			mid = {210, 210, 200, 255},
			light = {250, 250, 250, 255},
			highlight = {60, 255, 50, 255},
		},

		piano = { -- Vertical-piano colors
			dark = {20, 20, 30, 255},
			light = {240, 240, 250, 255},
			highlight = {230, 45, 40, 255},
			border = {130, 129, 132, 255},
			labellight = {200, 200, 205, 255},
			labeldark = {40, 40, 35, 255},
		},

		seq = { -- Sequence-roll colors
			dark = {180, 180, 190, 255},
			light = {200, 200, 210, 255},
			beat = {35, 30, 220, 255},
			active = {220, 30, 35, 255},
			font = {252, 240, 240, 255},
			highlight = {9, 10, 253, 255},
		},

		note = { -- Note colors
			quiet = {6, 220, 235, 255},
			loud = {255, 10, 20, 255},
			highlight = {230, 240, 240, 255},
			border = {5, 4, 8, 255},
			adjborder = {210, 210, 220, 255},
			lightborder = {255, 255, 255, 255},
		},

	},

	cmds = { -- Links between command-names and keychords

		LOAD_FILE = {"ctrl", "o"},
		SAVE_FILE = {"ctrl", "s"},
		LOAD_DIALOG = {"shift", "ctrl", "o"},
		SAVE_DIALOG = {"shift", "ctrl", "s"},
		HOTSEAT_UP = {"ctrl", "pageup"},
		HOTSEAT_DOWN = {"ctrl", "pagedown"},

		UNDO = {"ctrl", "z"},
		REDO = {"ctrl", "y"},

		TOGGLE_SELECTION = {"ctrl", "/"},
		COPY_RELATIVE_ADD = {"shift", "ctrl", "tab", "c"},
		COPY_RELATIVE = {"shift", "ctrl", "c"},
		COPY_ABSOLUTE_ADD = {"ctrl", "tab", "c"},
		COPY_ABSOLUTE = {"ctrl", "c"},
		CUT_RELATIVE_ADD = {"shift", "ctrl", "tab", "x"},
		CUT_RELATIVE = {"shift", "ctrl", "x"},
		CUT_ABSOLUTE_ADD = {"ctrl", "tab", "x"},
		CUT_ABSOLUTE = {"ctrl", "x"},
		PASTE_RELATIVE = {"shift", "ctrl", "v"},
		PASTE = {"ctrl", "v"},

		INSERT_NOTE = {"return"},
		DELETE_NOTE = {"delete"},
		DELETE_TICK_NOTES = {"shift", "delete"},
		DELETE_BEAT_NOTES = {"shift", "ctrl", "delete"},

		INSERT_SEQ = {"shift", "return"},
		REMOVE_SEQ = {"shift", "ctrl", "return"},

		CHANNEL_UP = {"ctrl", "]"},
		CHANNEL_DOWN = {"ctrl", "["},

		VELOCITY_UP = {"="},
		VELOCITY_DOWN = {"-"},
		VELOCITY_UP_10 = {"shift", "="},
		VELOCITY_DOWN_10 = {"shift", "-"},

		DURATION_UP = {"]"},
		DURATION_DOWN = {"["},
		DURATION_UP_MULTI = {"shift", "]"},
		DURATION_DOWN_MULTI = {"shift", "["},

		SPACING_UP = {"'"},
		SPACING_DOWN = {";"},
		SPACING_UP_MULTI = {"shift", "'"},
		SPACING_DOWN_MULTI = {"shift", ";"},

		BPM_UP = {"/"},
		BPM_DOWN = {"."},
		BPM_UP_10 = {"shift", "/"},
		BPM_DOWN_10 = {"shift", "."},

		TPQ_UP = {","},
		TPQ_DOWN = {"m"},
		TPQ_UP_MULTI = {"shift", ","},
		TPQ_DOWN_MULTI = {"shift", "m"},

		MOD_CHANNEL_UP = {"shift", "tab", "up"},
		MOD_CHANNEL_DOWN = {"shift", "tab", "down"},

		MOD_NOTE_UP = {"tab", "up"},
		MOD_NOTE_DOWN = {"tab", "down"},
		MOD_NOTE_LEFT = {"tab", "left"},
		MOD_NOTE_RIGHT = {"tab", "right"},

		MOD_VELOCITY_UP = {"tab", "pageup"},
		MOD_VELOCITY_DOWN = {"tab", "pagedown"},
		MOD_VELOCITY_UP_10 = {"shift", "tab", "pageup"},
		MOD_VELOCITY_DOWN_10 = {"shift", "tab", "pagedown"},

		MOD_SEQ_UP = {"shift", "pageup"},
		MOD_SEQ_DOWN = {"shift", "pagedown"},

		POINTER_UP = {"up"},
		POINTER_DOWN = {"down"},
		POINTER_UP_OCTAVE = {"shift", "up"},
		POINTER_DOWN_OCTAVE = {"shift", "down"},
		POINTER_LEFT = {"left"},
		POINTER_RIGHT = {"right"},
		POINTER_LEFT_BEAT = {"shift", "left"},
		POINTER_RIGHT_BEAT = {"shift", "right"},

		X_ZOOM_INC = {"shift", "ctrl", "right"},
		X_ZOOM_DEC = {"shift", "ctrl", "left"},
		Y_ZOOM_INC = {"shift", "ctrl", "up"},
		Y_ZOOM_DEC = {"shift", "ctrl", "down"},

		SEQ_TAB_UP = {"pageup"},
		SEQ_TAB_DOWN = {"pagedown"},

		TOGGLE_PLAYING = {"space"},

		MIDI_PANIC = {"ctrl", "space"},

		EXTROVERT_PLAY_NOTE = {"shift", " "},
		EXTROVERT_LOAD_FILE = {"shift", "ctrl", "e"},

	},

}