extends "res://Scripts/Camera.gd"

func ScopeDOF(delta):
	super(delta)
	RenderingServer.viewport_set_scaling_3d_scale(currentRID, 1.0)

func ResetDOF(delta):
	super(delta)
	RenderingServer.viewport_set_scaling_3d_scale(currentRID, 1.0)