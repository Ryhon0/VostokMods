extends Camera3D

var gameData = preload("res://Resources/GameData.tres")

@export var camera: Camera3D
@export var attribute: CameraAttributesPractical
@onready var weapons = $Weapons

var translateSpeed: = 4.0
var rotateSpeed: = 4.0
var nearFarSpeed: = 1.0
var FOVSpeed: = 1.0
var interpolate = false
var currentRID: RID

static var fsr_scale = 1.0
static var fpspp_initialized : bool = false

func _ready() -> void:
	if !fpspp_initialized:
		InputMap.add_action("fsr_up")
		var up = InputEventKey.new()
		up.pressed = true
		up.keycode = KEY_UP
		InputMap.action_add_event("fsr_up", up)

		InputMap.add_action("fsr_down")
		var down = InputEventKey.new()
		down.pressed = true
		down.keycode = KEY_DOWN
		InputMap.action_add_event("fsr_down", down)
		fpspp_initialized = true

	currentRID = get_tree().get_root().get_viewport_rid()

func _process(delta):
	get_tree().root.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	if Input.is_action_just_pressed("fsr_up"):
		fsr_scale += 0.05
		fsr_scale = clamp(fsr_scale, 0.1, 1.0)
		print("FSR:", fsr_scale)
	elif Input.is_action_just_pressed("fsr_down"):
		fsr_scale -= 0.05
		fsr_scale = clamp(fsr_scale, 0.1, 1.0)
		print("FSR:", fsr_scale)

	get_tree().root.scaling_3d_scale = fsr_scale

	if gameData.isCaching:
		return 
	else :
		if gameData.flycam:
			camera.fov = 75
			Interpolate(delta)
		else :
			if interpolate:
				Interpolate(delta)
				FOV(delta)
				DOF(delta)
			else :
				Follow()
				FOV(delta)
				DOF(delta)

	if camera.projection == projection:
		var near_far_factor = nearFarSpeed * delta * 10
		var fov_factor = FOVSpeed * delta * 10
		var new_near = lerp(near, camera.near, near_far_factor) as float
		var new_far = lerp(far, camera.far, near_far_factor) as float
		var new_fov = lerp(fov, camera.fov, fov_factor) as float
		set_perspective(new_fov, new_near, new_far)

func Interpolate(delta):
	var translate_factor = translateSpeed * delta * 10
	var rotate_factor = rotateSpeed * delta * 10
	var target_xform = camera.get_global_transform()
	var local_transform_only_origin: = Transform3D(Basis(), get_global_transform().origin)
	var local_transform_only_basis: = Transform3D(get_global_transform().basis, Vector3())

	local_transform_only_origin = local_transform_only_origin.interpolate_with(target_xform, translate_factor)
	local_transform_only_basis = local_transform_only_basis.interpolate_with(target_xform, rotate_factor)
	set_global_transform(Transform3D(local_transform_only_basis.basis, local_transform_only_origin.origin))

func Follow():
	var local_transform_only_origin: = Transform3D(Basis(), get_global_transform().origin)
	var local_transform_only_basis: = Transform3D(get_global_transform().basis, Vector3())
	var target_xform: = camera.get_global_transform()

	local_transform_only_origin = target_xform
	local_transform_only_basis = target_xform
	set_global_transform(Transform3D(local_transform_only_basis.basis, local_transform_only_origin.origin))

func FOV(delta):

	if gameData.isAiming && !gameData.isRunning && !gameData.isInspecting && !gameData.isPreparing && !gameData.isColliding && !gameData.isReloading && (gameData.weaponType == 0 || gameData.weaponType == 1):
		camera.fov = lerp(camera.fov, gameData.aimFOV, delta * 50.0)


	elif gameData.isAiming && !gameData.isRunning && !gameData.isInspecting && !gameData.isPreparing && !gameData.isColliding && (gameData.weaponType == 2 || gameData.weaponType == 3):
		camera.fov = lerp(camera.fov, gameData.aimFOV, delta * 50.0)


	else :
		camera.fov = lerp(camera.fov, gameData.baseFOV, delta * 25)

func DOF(delta):

	if (gameData.settings || gameData.interface):
		UIDOF(delta)

	elif gameData.isScoped && gameData.isAiming && !gameData.isReloading && (gameData.weaponType == 0 || gameData.weaponType == 1):
		ScopeDOF(delta)

	elif gameData.isScoped && gameData.isAiming && (gameData.weaponType == 2 || gameData.weaponType == 3):
		ScopeDOF(delta)

	else :
		ResetDOF(delta)

func UIDOF(delta):
	attribute.dof_blur_far_enabled = true
	attribute.dof_blur_near_enabled = true
	attribute.dof_blur_far_distance = 0.01
	attribute.dof_blur_far_transition = 5.0
	attribute.dof_blur_near_distance = 400
	attribute.dof_blur_near_transition = 1.0
	attribute.dof_blur_amount = move_toward(attribute.dof_blur_amount, 0.1, delta)

func ScopeDOF(delta):

	attribute.dof_blur_far_enabled = true
	attribute.dof_blur_near_enabled = false
	attribute.dof_blur_far_distance = 0.01
	attribute.dof_blur_far_transition = 5.0
	attribute.dof_blur_amount = move_toward(attribute.dof_blur_amount, 0.1, delta)

func ResetDOF(delta):

	attribute.dof_blur_amount = move_toward(attribute.dof_blur_amount, 0.0, delta)

	if attribute.dof_blur_amount == 0:
		attribute.dof_blur_far_enabled = false
		attribute.dof_blur_near_enabled = false
