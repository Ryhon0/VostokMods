extends SceneTree

func _initialize():
	var loader = load("ModLoader.gd").new()
	root.add_child(loader)
	loader.name = "ModLoader"
	
	change_scene_to_packed(load(ProjectSettings.get_setting_with_override("application/run/main_scene")))