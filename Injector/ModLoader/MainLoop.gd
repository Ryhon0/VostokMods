extends SceneTree

func _init() -> void:
	print("Main loop init")

	if !ProjectSettings.has_setting("vostokmods/zips"):
		print("vostokmods/zips not defined! Cannot load ZIPs!")
		return
	
	for zipPath in ProjectSettings.get_setting("vostokmods/zips"):
		print("Loading ZIP ", zipPath)
		ProjectSettings.load_resource_pack(zipPath)

func _initialize() -> void:
	print("Main loop initialized")
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))