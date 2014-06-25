
return {
	
	-- Port for sending commands to Extrovert
	oscsend = 8500,

	-- Path where savefiles are stored
	savepath = "C:/Users/Christian/Documents/MUSIC_STAGING/",

	-- Max undo depth
	maxundo = 100,

	hotseats = { -- Names of savefiles that are tabled for quick loading

		"default1",
		"default2",
		"default3",
		"default4",
		"default5",

		"default6",
		"default7",
		"default8",
		"default9",
		"default10",

		"default11",
		"default12",
		"default13",
		"default14",
		"default15",

		"default16",
		"default17",
		"default18",
		"default19",
		"default20",

	},

	color = { -- GUI colors, in format {R, G, B, Alpha}

		window = { -- Window pane colors
			dark = {70, 70, 80, 255},
			mid = {100, 100, 110, 255},
			light = {150, 150, 160, 255},
		},

		font = { -- Font colors
			shadow = {31, 34, 33, 255},
			mid = {210, 210, 200, 255},
			light = {250, 250, 250, 255},
			highlight = {60, 255, 50, 255},
		},

		summary = { -- Summary-grid colors
			empty = {100, 100, 220, 255},
			full = {255, 100, 100, 255},
			pointer = {0, 225, 225, 95},
			pointer_border = {0, 225, 225, 255},
			text = {235, 235, 235, 255},
			text_shadow = {5, 5, 255, 255},
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
			light = {200, 200, 209, 255},
			beat = {0, 0, 220, 250},
			active = {255, 0, 0, 200},
			font = {252, 240, 240, 255},
			highlight = {0, 100, 255, 200},
		},

		note = { -- Note colors
			quiet = {6, 220, 235, 255},
			loud = {255, 10, 20, 255},
			highlight = {230, 240, 240, 255},
			select_quiet = {200, 200, 200, 255},
			select_loud = {225, 20, 225, 255},
			overlay_quiet = {6, 180, 200, 180},
			overlay_loud = {210, 5, 100, 180},
			bar_quiet = {255, 255, 255, 180},
			bar_loud = {130, 255, 130, 180},
			border = {5, 4, 8, 255},
			adjborder = {210, 210, 220, 255},
			lightborder = {255, 255, 255, 255},
		},

		selection = { -- Selection colors
			fill = {10, 10, 255, 80},
			line = {255, 255, 255, 200},
		},

		scale = { -- Scale-mode colors
			consonant = {0, 0, 225, 255},
			dissonant = {225, 4, 8, 255},
		},

		triangle = { -- Beat-triangle colors
			fill = {0, 0, 245, 255},
			line = {0, 0, 255, 255},
			text = {240, 240, 240, 255},
		},

		reticule = { -- Reticule colors
			line = {235, 235, 235, 100},
			light = {255, 255, 255, 125},
			dark = {5, 5, 255, 90},
			recording = {5, 205, 215, 215},
			generator = {215, 210, 9, 215},
			generator_dark = {125, 125, 9, 215},
		},

		loading = { -- Loading-screen colors
			background = {70, 70, 80, 255},
			text = {210, 210, 200, 255},
			text_shadow = {50, 55, 55, 255},
		},

	},

	reticule = { -- Reticule properties

		width = 38, -- Tick-pointer reticule width
		
	},

	pianokeys = { -- Keyboard-keys that correspond to piano-keys
		"z", -- C
		"s", -- Db
		"x", -- D
		"d", -- Eb
		"c", -- E
		"v", -- F
		"g", -- Gb
		"b", -- G
		"h", -- Ab
		"n", -- A
		"j", -- Bb
		"m", -- B
		{",", "q"}, -- C
		{"l", "2"}, -- Db
		"w", -- D
		"3", -- Eb
		"e", -- E
		"r", -- F
		"5", -- Gb
		"t", -- G
		"6", -- Ab
		"y", -- A
		"7", -- Bb
		"u", -- B
		"i", -- C
		"9", -- Db
		"o", -- D
		"0", -- Eb
		"p", -- E
	},

	cmds = { -- Links between command-names and keychords

		base = { -- Base commands (available in all modes)

			LOAD_FILE = {"ctrl", "o"},
			SAVE_FILE = {"ctrl", "s"},

			TOGGLE_SEQ_OVERLAY = {"backspace"},
			TOGGLE_NOTE_DRAW = {"shift", "backspace"},

			TOGGLE_RECORDING = {" "},

			TOGGLE_GENERATOR_MODE = {"shift", " "},

			TOGGLE_CHAN_NUM_VIEW = {"`"},

			UNDO = {"ctrl", "z"},
			REDO = {"ctrl", "y"},

			TOGGLE_TOP = {"ctrl", ","},
			TOGGLE_BOT = {"ctrl", "."},
			CLEAR_SELECT_RANGE = {"ctrl", "/"},
			CLEAR_SELECT_MEMORY = {"ctrl", "shift", "/"},
			SELECT_ALL = {"ctrl", "a"},

			COPY = {"ctrl", "c"},
			COPY_ADD = {"ctrl", "shift", "c"},
			CUT = {"ctrl", "x"},
			CUT_ADD = {"ctrl", "shift", "x"},
			PASTE = {"ctrl", "v"},

			HUMANIZE = {"ctrl", "h"},

			INSERT_NOTE = {"return"},
			DELETE_NOTE = {"delete"},
			DELETE_TICK_NOTES = {"shift", "delete"},
			DELETE_PITCH_NOTES = {"ctrl", "delete"},
			DELETE_BEAT_NOTES = {"shift", "ctrl", "delete"},

			INSERT_TICKS = {"tab", "return"},
			REMOVE_TICKS = {"tab", "delete"},

			INSERT_SEQ = {"shift", "return"},
			REMOVE_SEQ = {"shift", "ctrl", "return"},

			CHANNEL_UP = {"ctrl", "]"},
			CHANNEL_DOWN = {"ctrl", "["},

			SPACING_UP = {"'"},
			SPACING_DOWN = {";"},
			SPACING_UP_MULTI = {"shift", "'"},
			SPACING_DOWN_MULTI = {"shift", ";"},

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

			EXTROVERT_LOAD_FILE = {"ctrl", "e"},

		},

		entry = { -- Entry Mode only

			VELOCITY_UP = {"="},
			VELOCITY_DOWN = {"-"},
			VELOCITY_UP_10 = {"shift", "="},
			VELOCITY_DOWN_10 = {"shift", "-"},

			DURATION_UP = {"]"},
			DURATION_DOWN = {"["},
			DURATION_UP_MULTI = {"shift", "]"},
			DURATION_DOWN_MULTI = {"shift", "["},

			BPM_UP = {"/"},
			BPM_DOWN = {"."},
			BPM_UP_10 = {"shift", "/"},
			BPM_DOWN_10 = {"shift", "."},

			TPQ_UP = {"tab", "/"},
			TPQ_DOWN = {"tab", "."},
			TPQ_UP_MULTI = {"shift", "tab", "/"},
			TPQ_DOWN_MULTI = {"shift", "tab", "."},

		},

		gen = { -- Generator Mode only

			KSPECIES_UP = {"shift", "w"},
			KSPECIES_DOWN = {"shift", "q"},

			SCALENUM_UP = {"shift", "s"},
			SCALENUM_DOWN = {"shift", "a"},

			CONSONANCE_UP = {"shift", "x"},
			CONSONANCE_DOWN = {"shift", "z"},
			CONSONANCE_UP_10 = {"shift", "tab", "x"},
			CONSONANCE_DOWN_10 = {"shift", "tab", "z"},

			SCALE_SWITCH_UP = {"shift", "r"},
			SCALE_SWITCH_DOWN = {"shift", "e"},
			SCALE_SWITCH_UP_10 = {"shift", "tab", "r"},
			SCALE_SWITCH_DOWN_10 = {"shift", "tab", "e"},

			WHEEL_SWITCH_UP = {"shift", "f"},
			WHEEL_SWITCH_DOWN = {"shift", "d"},
			WHEEL_SWITCH_UP_10 = {"shift", "tab", "f"},
			WHEEL_SWITCH_DOWN_10 = {"shift", "tab", "d"},

			DENSITY_UP = {"shift", "v"},
			DENSITY_DOWN = {"shift", "c"},
			DENSITY_UP_10 = {"shift", "tab", "v"},
			DENSITY_DOWN_10 = {"shift", "tab", "c"},

			BEAT_STICK_UP = {"shift", "y"},
			BEAT_STICK_DOWN = {"shift", "t"},
			BEAT_STICK_UP_10 = {"shift", "tab", "y"},
			BEAT_STICK_DOWN_10 = {"shift", "tab", "t"},

			BEAT_LENGTH_UP = {"shift", "h"},
			BEAT_LENGTH_DOWN = {"shift", "g"},
			BEAT_LENGTH_UP_MULTI = {"shift", "tab", "h"},
			BEAT_LENGTH_DOWN_MULTI = {"shift", "tab", "g"},

			BEAT_BOUND_UP = {"shift", "n"},
			BEAT_BOUND_DOWN = {"shift", "b"},

			BEAT_GRAIN_UP = {"shift", "i"},
			BEAT_GRAIN_DOWN = {"shift", "u"},
			BEAT_GRAIN_UP_MULTI = {"shift", "tab", "i"},
			BEAT_GRAIN_DOWN_MULTI = {"shift", "tab", "u"},

			NOTE_GRAIN_UP = {"shift", "k"},
			NOTE_GRAIN_DOWN = {"shift", "j"},
			NOTE_GRAIN_UP_MULTI = {"shift", "tab", "k"},
			NOTE_GRAIN_DOWN_MULTI = {"shift", "tab", "j"},

			LOWNOTE_UP = {"shift", ","},
			LOWNOTE_DOWN = {"shift", "m"},
			LOWNOTE_UP_12 = {"shift", "tab", ","},
			LOWNOTE_DOWN_12 = {"shift", "tab", "m"},

			HIGHNOTE_UP = {"shift", "/"},
			HIGHNOTE_DOWN = {"shift", "."},
			HIGHNOTE_UP_12 = {"shift", "tab", "/"},
			HIGHNOTE_DOWN_12 = {"shift", "tab", "."},

		},

	},

}
