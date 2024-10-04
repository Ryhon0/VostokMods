extends Node
func _init():
	overrideScript("res://SimpleControls/Weapon.gd")
	overrideScript("res://SimpleControls/Character.gd")
	queue_free()

func overrideScript(overrideScriptPath : String):
	var script : Script = load(overrideScriptPath)
	script.reload()
	var parentScript = script.get_base_script();
	script.take_over_path(parentScript.resource_path)