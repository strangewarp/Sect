
return {
	
	-- Path where savefiles are stored
	savepath = "C:/FALSE_SAVEPATH_REPLACE_ME_WITH_SOMETHING/",

	-- Max undo depth
	maxundo = 250,

	-- MIDI-over-UDP ports
	udpsend = 8562, -- OUT to SectMidiClient
	udpreceive = 8563, -- IN from SectMidiClient

	-- Toggles whether the mouse is reset to the center on right-click.
	mousetocenter = false,

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
			warning = {255, 60, 60, 255},
			cmd = {3, 2, 10, 255},
			cmd_shadow = {245, 245, 255, 255},
			note_shadow = {4, 5, 9, 100},
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
			active_dark = {20, 20, 30, 255},
			active_light = {240, 240, 250, 255},
			inactive_dark = {100, 100, 150, 255},
			inactive_light = {150, 150, 200, 255},
			highlight = {230, 45, 40, 255},
			border = {130, 129, 132, 255},
			text_active_light = {40, 40, 35, 255},
			text_active_dark = {200, 200, 205, 255},
			text_inactive_light = {170, 170, 200, 255},
			text_inactive_dark = {130, 130, 150, 255},
			text_highlight = {225, 225, 255, 255},
		},

		seq = { -- Sequence-grid colors
			active = {255, 0, 0, 235},
			dark = {10, 5, 108, 50},
			light = {200, 200, 209, 255},
			beat_dark = {0, 0, 220, 230},
			beat_light = {50, 50, 200, 50},
			font = {252, 240, 240, 255},
			highlight = {0, 100, 255, 200},
		},

		note = { -- Note colors
			border = {4, 253, 255, 255},
			text = {255, 255, 255, 255},
			normal = {255, 10, 20, 255},
			normal_quiet = {6, 20, 235, 255},
			highlight = {255, 100, 100, 255},
			highlight_quiet = {60, 70, 245, 255},
			sel = {225, 20, 225, 255},
			sel_quiet = {160, 160, 160, 255},
			shadow = {160, 16, 16, 110},
			shadow_quiet = {6, 10, 160, 110},
			other_chan = {225, 10, 20, 150},
			other_chan_quiet = {6, 20, 235, 150},
		},

		selection = { -- Selection colors
			fill = {10, 255, 5, 80},
			line = {235, 235, 255, 200},
		},

		triangle = { -- Beat-triangle colors
			fill = {0, 0, 245, 255},
			line = {0, 0, 25, 255},
			text = {240, 240, 240, 255},
		},

		reticule = { -- Reticule colors
			line = {235, 5, 5, 100},
			light = {255, 255, 255, 125},
			dark = {5, 5, 255, 90},
			recording = {5, 205, 215, 215},
			generator = {215, 210, 9, 215},
			generator_dark = {125, 125, 9, 215},
			cmd = {245, 6, 2, 55},
			cmd_dark = {9, 6, 2, 55},
		},

		save = { -- Save-confirmation-popup colors
			border = {230, 233, 234, 255},
			background = {0, 0, 245, 255},
			background_fade = {100, 100, 150, 255},
			text = {240, 240, 240, 255},
			text_shadow = {4, 5, 10, 175},
		},

		saveload = { -- Saveload panel colors
			background = {180, 180, 190, 255},
			panel = {110, 110, 120, 255},
			exist = {10, 195, 5, 255},
			not_exist = {0, 0, 245, 255},
			reticule = {0, 0, 245, 255},
			text = {230, 225, 225, 255},
			text_exist = {255, 255, 255, 255},
			text_not_exist = {235, 235, 235, 255},
		},

		loading = { -- Loading-screen colors
			background = {70, 70, 80, 255},
			text = {210, 210, 200, 255},
			text_shadow = {50, 55, 55, 255},
		},

	},

	img = { -- Image properties

		-- For no image, set "file" to "false" (without quotes).

		-- Place the images you want to use in your savedata folder.
		-- On Windows, this will be something like:
		-- "C:/Users/YourName/AppData/Roaming/LOVE/sect".
		-- Then simply set "file" to their filename.
		-- Like so: --> file = "file.png",
		-- Make sure to remember the quotes and comma!

		-- xglue types: "left", "right", "center"
		-- yglue types: "top", "bottom", "center"

		sidebar = { -- Sidebar
			file = "img/biglogo.png",
			xglue = "center",
			yglue = "bottom",
		},

		track = { -- Bottom-bar
			file = false,
			xglue = "center",
			yglue = "center",
		},

		grid = { -- Sequence-grid
			file = false,
			xglue = "center",
			yglue = "center",
		},

		loading = { -- Loading screen
			file = "img/loadingbg.png",
			xglue = "center",
			yglue = "center",
		},

	},

	cursor = { -- Mouse-cursor images

		default = { -- Default cursor
			file = "img/cursor1.png", -- File location
			x = 0, -- Cursor's x hotspot
			y = 0, -- Cursor's y hotspot
		},

		leftclick = { -- Left-click cursor
			file = "img/cursor2.png",
			x = 0,
			y = 0,
		},

		rightclick = { -- Right-click cursor
			file = "img/cursor3.png",
			x = 0,
			y = 0,
		},

	},

	font = { -- Font types

		sidebar = { -- Sidebar font
			file = "font/Milavregarian.ttf",
			height = 8,
		},

		track = { -- Bottom track-bar font
			file = "font/Milavregarian.ttf",
			height = 10,
		},

		piano = { -- Piano-key font
			file = "font/Milavregarian.ttf",
			height = 8,
		},

		note = { -- Sequence-note font
			file = "font/Milavregarian.ttf",
			height = 8,
		},

		beat = { -- Sequence-beat-triangle font
			file = "font/Milavregarian.ttf",
			height = 8,
		},

		save = { -- Save-popup font
			file = "font/candal/Candal.ttf",
			height = 12,
		},

		loading = { -- Loading-screen font
			file = "font/candal/Candal.ttf",
			height = 12,
		},

	},

	size = { -- Element sizes

		anchor = { -- Center pointer anchors
			x = 0.33, -- Distance between left and right
			y = 0.7, -- Distance between top and bottom
		},

		piano = { -- Piano-bar
			basewidth = 55,
		},

		reticule = { -- Tick-pointer reticule
			breadth = 26,
		},

		save = { -- Save-confirmation popup
			margin_top = 25,
			margin_left = 125,
			width = 300,
		},

		sidebar = { -- Left sidebar
			width = 100,
		},

		track = { -- Bottom track-bar
			height = 60,
		},

		triangle = { -- Beat-line triangle
			breadth = 40,
		},

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

		LOAD_HOTSEAT_FILE = {"ctrl", "o"},
		SAVE_FILE_TO_HOTSEAT = {"ctrl", "shift", "tab", "s"},

		TOGGLE_SAVELOAD_MODE = {"ctrl", "s"},
		ESCAPE_SAVELOAD_MODE = {"escape"},
		SL_POINTER_LEFT = {"left"},
		SL_POINTER_RIGHT = {"right"},
		SL_CHAR_BACKSPACE = {"backspace"},
		SL_CHAR_DELETE = {"delete"},
		LOAD_SL_FILE = {"ctrl", "o"},
		SAVE_SL_FILE = {"ctrl", "s"},
		SET_SAVE_PATH = {"ctrl", "shift", "p"},

		TOGGLE_SEQ_OVERLAY = {"backspace"},
		TOGGLE_NOTE_DRAW = {"shift", "backspace"},
		TOGGLE_CHAN_NUM_VIEW = {"`"},

		TOGGLE_RECORDING = {"escape"},

		TOGGLE_ENTRY_QUANTIZE = {"ctrl", " "},

		TOGGLE_PLAY_MODE = {" "},
		TOGGLE_GENERATOR_MODE = {"shift", " "},
		TOGGLE_CMD_MODE = {"tab", " "},

		UNDO = {"ctrl", "z"},
		REDO = {"ctrl", "y"},

		TOGGLE_TOP = {"ctrl", ","},
		TOGGLE_BOT = {"ctrl", "."},
		SELECT_ALL = {"ctrl", "a"},
		SELECT_CHAN = {"ctrl", "n"},
		CLEAR_SELECT_RANGE = {"ctrl", "/"},
		CLEAR_SELECT_MEMORY = {"ctrl", "shift", "a"},

		COPY = {"ctrl", "c"},
		CUT = {"ctrl", "x"},
		PASTE = {"ctrl", "v"},
		PASTE_REPEATING = {"ctrl", "shift", "v"},
		PASTE_FROM_TEXT_MONO = {"ctrl", "m"},
		PASTE_FROM_TEXT_POLY = {"ctrl", "p"},

		HUMANIZE = {"ctrl", "h"},
		QUANTIZE = {"ctrl", "u"},

		INSERT_NOTE = {"return"},
		DELETE_NOTE = {"delete"},
		DELETE_TICK_NOTES = {"shift", "delete"},
		DELETE_PITCH_NOTES = {"ctrl", "delete"},
		DELETE_BEAT_NOTES = {"shift", "ctrl", "delete"},

		INSERT_TICKS = {"tab", "return"},
		REMOVE_TICKS = {"tab", "delete"},
		MULTIPLY_TICKS = {"shift", "tab", "return"},

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

		TPQ_UP = {"tab", "/"},
		TPQ_DOWN = {"tab", "."},
		TPQ_UP_MULTI = {"shift", "tab", "/"},
		TPQ_DOWN_MULTI = {"shift", "tab", "."},

		FACTOR_UP = {"tab", "'"},
		FACTOR_DOWN = {"tab", ";"},

		MOD_DUR_INCREASE = {"shift", "tab", "right"},
		MOD_DUR_DECREASE = {"shift", "tab", "left"},

		MOD_CHANNEL_UP = {"ctrl", "tab", "up"},
		MOD_CHANNEL_DOWN = {"ctrl", "tab", "down"},

		MOD_NOTE_UP_1 = {"tab", "up"},
		MOD_NOTE_DOWN_1 = {"tab", "down"},
		MOD_NOTE_UP_12 = {"shift", "tab", "up"},
		MOD_NOTE_DOWN_12 = {"shift", "tab", "down"},
		MOD_NOTE_LEFT = {"tab", "left"},
		MOD_NOTE_RIGHT = {"tab", "right"},

		MOD_VELOCITY_UP = {"tab", "="},
		MOD_VELOCITY_DOWN = {"tab", "-"},
		MOD_VELOCITY_UP_10 = {"shift", "tab", "="},
		MOD_VELOCITY_DOWN_10 = {"shift", "tab", "-"},

		MOD_SEQ_UP = {"ctrl", "pageup"},
		MOD_SEQ_DOWN = {"ctrl", "pagedown"},

		POINTER_UP = {"up"},
		POINTER_DOWN = {"down"},
		POINTER_UP_OCTAVE = {"shift", "up"},
		POINTER_DOWN_OCTAVE = {"shift", "down"},
		POINTER_LEFT = {"left"},
		POINTER_RIGHT = {"right"},
		POINTER_HOME = {"home"},
		POINTER_OPPOSITE = {"end"},
		POINTER_LEFT_BEAT = {"shift", "left"},
		POINTER_RIGHT_BEAT = {"shift", "right"},
		POINTER_PREV_NOTE = {"ctrl", "left"},
		POINTER_NEXT_NOTE = {"ctrl", "right"},

		X_ZOOM_INC = {"shift", "ctrl", "right"},
		X_ZOOM_DEC = {"shift", "ctrl", "left"},
		Y_ZOOM_INC = {"shift", "ctrl", "up"},
		Y_ZOOM_DEC = {"shift", "ctrl", "down"},

		SEQ_TAB_UP = {"pageup"},
		SEQ_TAB_DOWN = {"pagedown"},
		SEQ_TAB_UP_10 = {"shift", "pageup"},
		SEQ_TAB_DOWN_10 = {"shift", "pagedown"},

		KSPECIES_UP = {"shift", "w"},
		KSPECIES_DOWN = {"shift", "q"},

		SCALENUM_UP = {"shift", "s"},
		SCALENUM_DOWN = {"shift", "a"},
		
		WHEELNUM_UP = {"tab", "s"},
		WHEELNUM_DOWN = {"tab", "a"},

		CONSONANCE_UP = {"shift", "x"},
		CONSONANCE_DOWN = {"shift", "z"},
		CONSONANCE_UP_10 = {"tab", "x"},
		CONSONANCE_DOWN_10 = {"tab", "z"},

		SCALE_SWITCH_UP = {"shift", "r"},
		SCALE_SWITCH_DOWN = {"shift", "e"},
		SCALE_SWITCH_UP_10 = {"tab", "r"},
		SCALE_SWITCH_DOWN_10 = {"tab", "e"},

		WHEEL_SWITCH_UP = {"shift", "f"},
		WHEEL_SWITCH_DOWN = {"shift", "d"},
		WHEEL_SWITCH_UP_10 = {"tab", "f"},
		WHEEL_SWITCH_DOWN_10 = {"tab", "d"},

		DENSITY_UP = {"shift", "v"},
		DENSITY_DOWN = {"shift", "c"},
		DENSITY_UP_10 = {"tab", "v"},
		DENSITY_DOWN_10 = {"tab", "c"},

		BEAT_STICK_UP = {"shift", "y"},
		BEAT_STICK_DOWN = {"shift", "t"},
		BEAT_STICK_UP_10 = {"tab", "y"},
		BEAT_STICK_DOWN_10 = {"tab", "t"},

		BEAT_LENGTH_UP = {"shift", "h"},
		BEAT_LENGTH_DOWN = {"shift", "g"},
		BEAT_LENGTH_UP_MULTI = {"tab", "h"},
		BEAT_LENGTH_DOWN_MULTI = {"tab", "g"},

		BEAT_BOUND_UP = {"shift", "n"},
		BEAT_BOUND_DOWN = {"shift", "b"},

		BEAT_GRAIN_UP = {"shift", "i"},
		BEAT_GRAIN_DOWN = {"shift", "u"},
		BEAT_GRAIN_UP_MULTI = {"tab", "i"},
		BEAT_GRAIN_DOWN_MULTI = {"tab", "u"},

		NOTE_GRAIN_UP = {"shift", "k"},
		NOTE_GRAIN_DOWN = {"shift", "j"},
		NOTE_GRAIN_UP_MULTI = {"tab", "k"},
		NOTE_GRAIN_DOWN_MULTI = {"tab", "j"},

		CMD_POINTER_UP = {"up"},
		CMD_POINTER_DOWN = {"down"},

		CMD_TYPE_UP = {"shift", "w"},
		CMD_TYPE_DOWN = {"shift", "q"},

		CMD_BYTE_1_UP = {"shift", "s"},
		CMD_BYTE_1_DOWN = {"shift", "a"},
		CMD_BYTE_1_UP_10 = {"tab", "s"},
		CMD_BYTE_1_DOWN_10 = {"tab", "a"},

		CMD_BYTE_2_UP = {"shift", "x"},
		CMD_BYTE_2_DOWN = {"shift", "z"},
		CMD_BYTE_2_UP_10 = {"tab", "x"},
		CMD_BYTE_2_DOWN_10 = {"tab", "z"},

	},

}
