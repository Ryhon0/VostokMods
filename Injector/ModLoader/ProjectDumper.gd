extends SceneTree

func _initialize() -> void:
	ProjectSettings.save_custom("project.godot")
	quit()