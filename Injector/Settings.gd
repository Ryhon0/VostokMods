extends Control

@export var Main : Control
@export var CustomModDirLine : LineEdit
@export var StartOnConfigCheckBox : CheckBox

func _ready() -> void:
	CustomModDirLine.text_changed.connect(func(val): Main.config.customModDir = val)
	StartOnConfigCheckBox.toggled.connect(func(val): Main.config.startOnConfigScreen = val)

func openModDirDialog():
	var fd = FileDialog.new()
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	fd.show_hidden_files = true
	fd.dir_selected.connect(func(dir): CustomModDirLine.text = dir; Main.config.customModDir = dir)
	add_child(fd)
	fd.popup_centered_ratio()

func onLoaded():
	CustomModDirLine.text = Main.config.customModDir
	StartOnConfigCheckBox.button_pressed = Main.config.startOnConfigScreen