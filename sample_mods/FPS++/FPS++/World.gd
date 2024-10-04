extends "res://Scripts/World.gd"

func ExecuteStandardRendering(value: bool) -> void:
	super(value)
	var currentRID = get_tree().get_root().get_viewport_rid()
	RenderingServer.viewport_set_scaling_3d_scale(currentRID, 1.0)
	RenderingServer.viewport_set_msaa_3d(currentRID, RenderingServer.VIEWPORT_MSAA_4X)

func ExecutePerformanceRendering(value: bool) -> void:
	super(value)
	var currentRID = get_tree().get_root().get_viewport_rid()
	RenderingServer.viewport_set_scaling_3d_scale(currentRID, 1.0)
	RenderingServer.viewport_set_msaa_3d(currentRID, RenderingServer.VIEWPORT_MSAA_DISABLED)
