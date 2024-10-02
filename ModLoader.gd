extends SceneTree

func _initialize():
	var modsDir = OS.get_executable_path().get_base_dir() + "/mods"
	print("Loading mods from ", modsDir)
	var da = DirAccess.open(modsDir)
	da.list_dir_begin()
	var pck = da.get_next()
	while pck:
		print("Loading ", pck)
		ProjectSettings.load_resource_pack(modsDir + "/" + pck)
		pck = da.get_next()
	print("Done")

	# Change scene to main scene
	change_scene_to_packed(load(ProjectSettings.get_setting_with_override("application/run/main_scene")))