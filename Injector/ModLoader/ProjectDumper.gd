extends SceneTree

func _initialize() -> void:
	ProjectSettings.save_custom("project.godot")
	
	var classListIn = FileAccess.open("res://.godot/global_script_class_cache.cfg", FileAccess.READ)
	var classListOut = FileAccess.open("global_script_class_cache.cfg", FileAccess.WRITE)
	classListOut.store_buffer(classListIn.get_buffer(classListIn.get_length()))
	classListOut.close()
	classListIn.close()
	quit()