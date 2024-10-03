extends Preferences

@export var loaderScript : GDScript

func _init():
	# Constructor is called BEFORE export variables are set
	load_loader.call_deferred()
	
func load_loader():
	if ProjectSettings.get_setting("vostokmods/is_injector", false):
		return
	if Engine.get_main_loop().root.has_node("ModLoader"):
		return

	var loader = loaderScript.new()
	Engine.get_main_loop().root.add_child.call_deferred(loader)
	loader.name = "ModLoader"