extends Control

@export var Main: Control
@export var CustomModDirLine: LineEdit
@export var StartOnConfigCheckBox: CheckBox
@export var AllowAutoUpdateCheckBox: CheckBox
@export var AllowModsAutoUpdateCheckBox: CheckBox

func _ready() -> void:
	CustomModDirLine.text_changed.connect(func(val): Main.config.customModDir = val; Main.Mods.loadMods())
	StartOnConfigCheckBox.toggled.connect(func(val): Main.config.startOnConfigScreen = val)
	AllowAutoUpdateCheckBox.toggled.connect(func(val): Main.config.allowAutoUpdate = val)
	AllowModsAutoUpdateCheckBox.toggled.connect(func(val): Main.config.allowModsAutoUpdate = val)

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
	AllowModsAutoUpdateCheckBox.button_pressed = Main.config.allowModsAutoUpdate
