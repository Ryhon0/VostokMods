extends Control

@export var Main: Control
@export var CustomModDirLine: LineEdit
@export var StartOnConfigCheckBox: CheckBox
@export var AllowAutoUpdateCheckBox: CheckBox
@export var AllowModAutoUpdatesCheckBox: CheckBox
@export var AutoUpdateDisabledModsCheckBox: CheckBox

func _ready() -> void:
	CustomModDirLine.text_changed.connect(func(val): Main.config.customModDir = val; Main.saveConfig(); Main.Mods.loadMods())
	StartOnConfigCheckBox.toggled.connect(func(val): Main.config.startOnConfigScreen = val; Main.saveConfig())
	AllowAutoUpdateCheckBox.toggled.connect(func(val): Main.config.allowAutoUpdate = val; Main.saveConfig())
	AllowModAutoUpdatesCheckBox.toggled.connect(func(val): Main.config.allowModAutoUpdates = val; Main.saveConfig())
	AutoUpdateDisabledModsCheckBox.toggled.connect(func(val): Main.config.autoUpdateDisalbedMods = val; Main.saveConfig())

func openModDirDialog():
	var fd = FileDialog.new()
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	fd.show_hidden_files = true
	fd.dir_selected.connect(func(dir): CustomModDirLine.text = dir; Main.config.customModDir = dir; Main.Mods.loadMods())
	add_child(fd)
	fd.popup_centered_ratio()

func onLoaded():
	CustomModDirLine.text = Main.config.customModDir
	StartOnConfigCheckBox.button_pressed = Main.config.startOnConfigScreen
	AllowAutoUpdateCheckBox.button_pressed = Main.config.allowAutoUpdate
	AllowModAutoUpdatesCheckBox.button_pressed = Main.config.allowModAutoUpdates
	AutoUpdateDisabledModsCheckBox.button_pressed = Main.config.autoUpdateDisalbedMods
