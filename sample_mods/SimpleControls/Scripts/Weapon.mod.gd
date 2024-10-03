extends Node3D

var gameData = preload("res://Resources/GameData.tres")
var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")

@export_group("Data")
@export var weaponData: Resource

@export_group("References")
@export var animator: AnimationTree
@export var skeleton: Skeleton3D
@export var recoil: Node3D
@export var ejector: Node3D
@export var muzzle: Node3D
@export var raycast: RayCast3D
@export var collision: RayCast3D
@export var arms: MeshInstance3D
@export var attachments: Node3D

@export_group("Dynamic Rig")
@export var dynamicSlide: bool
@export var dynamicSelector: bool
@export var slideIndex = 0
@export var selectorIndex = 0
@export var backSightIndex = 0
@export var frontSightIndex = 0

@export_group("Upgrade")
@export var defaultParts: Array[MeshInstance3D]
@export var upgradeParts: Array[MeshInstance3D]

var fireRate = 0.0
var fireTimer = 0.0
var fireImpulse = 0.0
var fireImpulseTimer = 0.0
var slideValue = 0.0
var slideWeight = 0.0
var selectorValue = 0.0
var initialSelectorRotation = Vector3.ZERO
var targetSelectorRotation = Vector3.ZERO
var casingDelay = 0.5
var slideLocked = false
var UIManager
var interface
var weaponManager
var weaponSlot

var isUpgraded = false
var activeOptic
var activeMuzzle
var activeBarrel
var aimOffset = 0.0
var aimPosition: Vector3
var muzzlePosition: Vector3

func _ready():
	weaponManager = get_parent()

	if gameData.primary:
		weaponSlot = weaponManager.primarySlot
	elif gameData.secondary:
		weaponSlot = weaponManager.secondarySlot

	animator.active = false
	gameData.weaponPosition = 1
	gameData.inspectPosition = 1
	gameData.isPreparing = false
	gameData.isReloading = false
	gameData.weaponType = weaponData.action
	muzzlePosition = muzzle.position

	interface = get_tree().current_scene.get_node("/root/Map/Core/UI/UI_Interface")
	UIManager = get_tree().current_scene.get_node("/root/Map/Core/UI")

	initialSelectorRotation = skeleton.get_bone_pose_rotation(selectorIndex).get_euler()

func _input(event):
	if gameData.isInspecting:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if gameData.inspectPosition == 1:
					animator["parameters/conditions/Inspect_Front"] = false
					animator["parameters/conditions/Inspect_Back"] = true
					gameData.inspectPosition = 2

			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if gameData.inspectPosition == 2:
					animator["parameters/conditions/Inspect_Front"] = true
					animator["parameters/conditions/Inspect_Back"] = false
					gameData.inspectPosition = 1

func _physics_process(delta):
	if gameData.freeze || gameData.isCaching || gameData.isPlacing:
		return 

	if weaponSlot:
		gameData.firemode = weaponSlot.slotData.firemode

	FireInput()
	ReloadInput()
	FireTimer(delta)
	FireImpulse(delta)

	if dynamicSlide && !gameData.isCaching:
		Slide(delta)

	if dynamicSelector && !gameData.isCaching:
		Selector(delta)

func FireInput():

	if Input.is_action_just_pressed(("firemode")) && weaponData.action == 0 && !gameData.isReloading:
		ChangeFiremode()

	if gameData.isInspecting || gameData.isReloading || gameData.isPreparing || gameData.isInserting:
		return 

	if !gameData.weaponPosition == 2 && !gameData.isAiming && !gameData.isCanted:
		return 

	if weaponSlot.slotData.ammo == 0:
		return 

	if weaponData.action == 0:

		if weaponSlot.slotData.firemode == 1:
			if Input.is_action_just_pressed(("fire")):
				FireEvent()
				fireImpulse = 0.1
				fireRate = 0.1

		elif weaponSlot.slotData.firemode == 2:
			if Input.is_action_pressed(("fire")):
				FireEvent()
				fireImpulse = weaponData.fireRate
				fireRate = weaponData.fireRate

	elif weaponData.action == 1:

		if Input.is_action_just_pressed(("fire")):
			FireEvent()
			fireImpulse = 0.1
			fireRate = 0.1

	elif (weaponData.action == 2 || weaponData.action == 3) && weaponSlot.slotData.chamber == 1:
		if Input.is_action_just_pressed(("fire")):
			FireEvent()
			fireImpulse = 0.1
			fireRate = 0.1

func InspectWeapon():
	animator.active = true
	weaponManager.flashTimer = 0.0
	weaponManager.muzzleFlash = false

	animator["parameters/conditions/Inspect_Front"] = true
	animator["parameters/conditions/Inspect_Idle"] = false

func ResetInspect():
	if gameData.inspectPosition == 1:
		animator["parameters/conditions/Inspect_Front"] = false
		animator["parameters/conditions/Inspect_Idle"] = true
	elif gameData.inspectPosition == 2:
		animator["parameters/conditions/Inspect_Back"] = false
		animator["parameters/conditions/Inspect_Idle"] = true
		gameData.inspectPosition = 1

func ReloadInput():
	if gameData.isInspecting || gameData.isReloading || gameData.isInserting:
		return 

	# Pistol/Rifle reload
	if Input.is_action_just_pressed(("reload")) && (weaponData.action == 0 || weaponData.action == 1):

		if weaponSlot.slotData.ammo == weaponData.magazineSize:
			return 

		if !interface.AmmoCheck(weaponData):
			return 

		animator.active = true
		gameData.isReloading = true
		gameData.isAiming = false
		gameData.isFiring = false

		if weaponSlot.slotData.ammo != 0:
			animator["parameters/conditions/Reload_Tactical"] = true
		else :
			animator["parameters/conditions/Reload_Empty"] = true

		var ammoNeeded = weaponData.magazineSize - weaponSlot.slotData.ammo
		var ammoProvided = interface.Reload(ammoNeeded, weaponData)
		weaponSlot.slotData.ammo = weaponSlot.slotData.ammo + ammoProvided

	# Chamber next round
	if (weaponData.action == 2 || weaponData.action == 3) && ( !gameData.isPreparing && !gameData.isInserting):
		if !(weaponSlot.slotData.ammo == 0 || weaponSlot.slotData.ammo == weaponData.magazineSize || weaponSlot.slotData.chamber == 1):
			animator.active = true
			gameData.isReloading = true
			gameData.isFiring = false
			animator["parameters/conditions/Reload"] = true
			animator["parameters/conditions/Insert_Start"] = false
			animator["parameters/conditions/Insert"] = false
			animator["parameters/conditions/Insert_End"] = false
			weaponSlot.slotData.chamber = 1

	# Start shotgun/sniper reload
	if Input.is_action_just_pressed(("reload")) && (weaponData.action == 2 || weaponData.action == 3):

		if gameData.isInserting:
			return 

		animator.active = true

		if !gameData.isPreparing:
			animator["parameters/conditions/Insert_Start"] = true
			animator["parameters/conditions/Insert_End"] = false
			gameData.isFiring = false
			gameData.isPreparing = true

	# Insert round
	if (weaponData.action == 2 || weaponData.action == 3):

		if !gameData.isPreparing:
			return 

		# Full or no more ammo, exit out of reload
		if weaponSlot.slotData.ammo == weaponData.magazineSize || !interface.AmmoCheck(weaponData):
			animator["parameters/conditions/Insert_Start"] = false
			animator["parameters/conditions/Insert_End"] = true
			gameData.isFiring = false
			gameData.isPreparing = false
			return 

		animator.active = true
		animator["parameters/conditions/Insert"] = true
		gameData.isInserting = true
		gameData.isFiring = false
		weaponSlot.slotData.chamber = 1

		var ammoProvided = interface.Reload(1, weaponData)
		weaponSlot.slotData.ammo += ammoProvided

func FireTimer(delta):
	if (fireTimer < fireRate):
		fireTimer += delta

func FireEvent():
	if fireTimer < fireRate || weaponSlot.slotData.ammo == 0:
		return 

	if weaponData.action == 3:
		for ray in 6:
			Raycast(0.5)
			raycast.force_raycast_update()
	else :
		Raycast(0.0)

	MuzzleEffect()
	PlayFireAudio()
	PlayTailAudio()
	recoil.ApplyRecoil()
	weaponSlot.slotData.ammo -= 1
	fireTimer = 0.0

	if weaponData.action == 0 || weaponData.action == 1:
		CartridgeEject()
		PlayCasingDrop()

	if weaponData.action == 2 || weaponData.action == 3:
		weaponSlot.slotData.chamber = 0

	if weaponSlot.slotData.ammo == 0 && weaponData.action == 1:
		PlaySlideLockedAudio()

	if activeMuzzle == null && !weaponData.nativeSuppressor:
		weaponManager.muzzleFlash = true

func Raycast(spread: float):
	raycast.rotation_degrees.x = randf_range( - spread, spread)
	raycast.rotation_degrees.y = randf_range( - spread, spread)

	if raycast.is_colliding():
		var hitCollider = raycast.get_collider()
		var hitPoint = raycast.get_collision_point()
		var hitNormal = raycast.get_collision_normal()
		var hitSurface = raycast.get_collider().get("surfaceType")
		BulletDecal(hitCollider, hitPoint, hitNormal, hitSurface)

		if hitCollider is Hitbox:
			if activeBarrel != null:
				hitCollider.ApplyDamage(weaponData.upgrade.damage)
			else :
				hitCollider.ApplyDamage(weaponData.damage)

		if hitCollider.owner is Mine:
			hitCollider.owner.InstantDetonate()

func BulletDecal(hitCollider, hitPoint, hitNormal, hitSurface):
	var bulletDecal

	if hitCollider is Hitbox:
		bulletDecal = weaponManager.hitBlood.instantiate()
	else :
		bulletDecal = weaponManager.hit.instantiate()

	hitCollider.add_child(bulletDecal)
	bulletDecal.global_transform.origin = hitPoint

	if hitNormal == Vector3(0, 1, 0):
		bulletDecal.look_at(hitPoint + hitNormal, Vector3.RIGHT)
	elif hitNormal == Vector3(0, -1, 0):
		bulletDecal.look_at(hitPoint + hitNormal, Vector3.RIGHT)
	else :
		bulletDecal.look_at(hitPoint + hitNormal, Vector3.DOWN)

	bulletDecal.global_rotation.z = randf_range(-360, 360)

	if hitCollider is Hitbox:
		bulletDecal.Emit()
	else :
		bulletDecal.PlayHit(hitSurface)

func CartridgeEject():

	if weaponData.action == 0 || weaponData.action == 1:
		if weaponData.cartridge == 0:
			var cartridge = weaponManager.cartridgePistol.instantiate()
			ejector.add_child(cartridge)
			cartridge.Emit()
		elif weaponData.cartridge == 1:
			var cartridge = weaponManager.cartridgeRifle.instantiate()
			ejector.add_child(cartridge)
			cartridge.Emit()

	if weaponData.action == 2:
		var cartridge = weaponManager.cartridgeRifle.instantiate()
		ejector.add_child(cartridge)
		cartridge.Emit()

	if weaponData.action == 3:
		var cartridge = weaponManager.cartridgeShell.instantiate()
		ejector.add_child(cartridge)
		cartridge.Emit()

func MuzzleEffect():
	var newSmoke = weaponManager.smoke.instantiate()
	muzzle.add_child(newSmoke)
	newSmoke.Emit()

	if activeMuzzle == null && !weaponData.nativeSuppressor:
		if weaponData.action == 1:
			var newFlashSmall = weaponManager.flashSmall.instantiate()
			muzzle.add_child(newFlashSmall)
			newFlashSmall.Emit()
		else :
			var newFlashMedium = weaponManager.flashMedium.instantiate()
			muzzle.add_child(newFlashMedium)
			newFlashMedium.Emit()

func ChangeFiremode():
	if weaponSlot.slotData.firemode == 1:
		weaponSlot.slotData.firemode = 2
	elif weaponSlot.slotData.firemode == 2:
		weaponSlot.slotData.firemode = 1

	PlayFiremode()

func PlayFireAudio():
	var fire = audioInstance2D.instantiate()
	get_tree().get_root().add_child(fire)

	if isUpgraded:
		if activeMuzzle != null:
			fire.PlayInstance(weaponData.upgrade.fireSuppressed)
		else :
			if weaponSlot.slotData.firemode == 2 && weaponData.action == 0:
				fire.PlayInstance(weaponData.upgrade.fireAuto)
			else :
				fire.PlayInstance(weaponData.upgrade.fireSemi)

	else :
		if activeMuzzle != null:
			fire.PlayInstance(weaponData.fireSuppressed)
		else :
			if weaponSlot.slotData.firemode == 2 && weaponData.action == 0:
				fire.PlayInstance(weaponData.fireAuto)
			else :
				fire.PlayInstance(weaponData.fireSemi)

func PlayTailAudio():
	var tail = audioInstance2D.instantiate()
	get_tree().get_root().add_child(tail)

	if isUpgraded:
		if activeMuzzle != null:
			if gameData.indoor:
				tail.PlayInstance(weaponData.upgrade.tailIndoorSuppressed)
			else :
				tail.PlayInstance(weaponData.upgrade.tailOutdoorSuppressed)
		else :
			if gameData.indoor:
				tail.PlayInstance(weaponData.upgrade.tailIndoor)
			else :
				tail.PlayInstance(weaponData.upgrade.tailOutdoor)

	else :
		if activeMuzzle != null:
			if gameData.indoor:
				tail.PlayInstance(weaponData.tailIndoorSuppressed)
			else :
				tail.PlayInstance(weaponData.tailOutdoorSuppressed)
		else :
			if gameData.indoor:
				tail.PlayInstance(weaponData.tailIndoor)
			else :
				tail.PlayInstance(weaponData.tailOutdoor)

func PlayFiremode():
	var firemode = audioInstance2D.instantiate()
	add_child(firemode)
	firemode.PlayInstance(audioLibrary.firemode)

func PlayMagazineOutAudio():
	var magazineOut = audioInstance2D.instantiate()
	add_child(magazineOut)
	magazineOut.PlayInstance(weaponData.magazineOut)

func PlayMagazineInAudio():
	var magazineIn = audioInstance2D.instantiate()
	add_child(magazineIn)
	magazineIn.PlayInstance(weaponData.magazineIn)

func PlayAdditionalAudio():
	var additional = audioInstance2D.instantiate()
	add_child(additional)
	additional.PlayInstance(weaponData.additional)

func PlaySlideReleaseAudio():
	var slideRelease = audioInstance2D.instantiate()
	add_child(slideRelease)
	slideRelease.PlayInstance(weaponData.slideRelease)

func PlaySlideLockedAudio():
	var slideLockedAudio = audioInstance2D.instantiate()
	add_child(slideLockedAudio)
	slideLockedAudio.PlayInstance(weaponData.slideLocked)

func PlayBoltOpenAudio():
	var boltOpen = audioInstance2D.instantiate()
	add_child(boltOpen)
	boltOpen.PlayInstance(weaponData.boltOpen)

func PlayBoltCloseAudio():
	var boltClosed = audioInstance2D.instantiate()
	add_child(boltClosed)
	boltClosed.PlayInstance(weaponData.boltClosed)

func PlayInsertAudio():
	var insert = audioInstance2D.instantiate()
	add_child(insert)
	insert.PlayInstance(weaponData.insert)

func PlayCasingDrop():
	await get_tree().create_timer(casingDelay).timeout;

	var casingDrop = audioInstance2D.instantiate()
	add_child(casingDrop)

	if gameData.surface == 0 || gameData.surface == 1 || gameData.surface == 2:
		if weaponData.action == 3:
			casingDrop.PlayInstance(audioLibrary.shellDropSoft)
		else :
			casingDrop.PlayInstance(audioLibrary.casingDropSoft)

	elif gameData.surface == 5:
		if weaponData.action == 3:
			casingDrop.PlayInstance(audioLibrary.shellDropHard)
		else :
			casingDrop.PlayInstance(audioLibrary.casingDropWood)

	elif gameData.surface == 9:
		return 

	else :
		if weaponData.action == 3:
			casingDrop.PlayInstance(audioLibrary.shellDropHard)
		else :
			casingDrop.PlayInstance(audioLibrary.casingDropHard)

func FireImpulse(delta):
	if fireImpulseTimer < fireImpulse:
		gameData.isFiring = true
		fireImpulseTimer += delta
	else :
		gameData.isFiring = false
		fireImpulseTimer = 0.0
		fireImpulse = 0.0

func InsertFinished():
	gameData.isInserting = false
	animator["parameters/conditions/Insert"] = false

func ReloadFinished():
	gameData.isReloading = false
	gameData.isPreparing = false
	gameData.isInserting = false

	if weaponData.action == 0 || weaponData.action == 1:
		animator["parameters/conditions/Reload_Tactical"] = false
		animator["parameters/conditions/Reload_Empty"] = false
	elif weaponData.action == 2 || weaponData.action == 3:
		animator["parameters/conditions/Reload"] = false
		animator["parameters/conditions/Insert_Start"] = false
		animator["parameters/conditions/Insert_End"] = false

func Selector(delta):
	if weaponSlot.slotData.firemode == 1:
		selectorValue = move_toward(selectorValue, weaponData.semiRotation, delta * weaponData.selectorSpeed)
	else :
		selectorValue = move_toward(selectorValue, weaponData.autoRotation, delta * weaponData.selectorSpeed)

	if weaponData.selectorDirection == 0:
		targetSelectorRotation = Vector3(initialSelectorRotation.x + selectorValue, initialSelectorRotation.y, initialSelectorRotation.z)
	elif weaponData.selectorDirection == 1:
		targetSelectorRotation = Vector3(initialSelectorRotation.x, initialSelectorRotation.y + selectorValue, initialSelectorRotation.z)
	else :
		targetSelectorRotation = Vector3(initialSelectorRotation.x, initialSelectorRotation.y, initialSelectorRotation.z + selectorValue)

	skeleton.set_bone_pose_rotation(selectorIndex, Quaternion.from_euler(targetSelectorRotation))

func Slide(delta):
	var currentPose = skeleton.get_bone_global_pose_no_override(slideIndex)

	if gameData.isFiring || (weaponData.slideLock && weaponSlot.slotData.ammo == 0):
		slideValue = lerp(slideValue, weaponData.slideMovement, delta * weaponData.slideSpeed)
	else :
		slideValue = lerp(slideValue, 0.0, delta * weaponData.slideSpeed)

	if gameData.isReloading:
		slideWeight = 0.0
	else :
		slideWeight = 1.0

	if weaponData.slideDirection == weaponData.SlideDirection.X:
		var slidePose = currentPose.translated_local(Vector3(slideValue, 0, 0))
		skeleton.set_bone_global_pose_override(slideIndex, slidePose, slideWeight, true)
	elif weaponData.slideDirection == weaponData.SlideDirection.Y:
		var slidePose = currentPose.translated_local(Vector3(0, slideValue, 0))
		skeleton.set_bone_global_pose_override(slideIndex, slidePose, slideWeight, true)
	elif weaponData.slideDirection == weaponData.SlideDirection.Z:
		var slidePose = currentPose.translated_local(Vector3(0, 0, slideValue))
		skeleton.set_bone_global_pose_override(slideIndex, slidePose, slideWeight, true)

func UpdateMuzzlePosition():
	if activeMuzzle != null:
		muzzle.position = muzzle.position + Vector3(0, 0, 0.2)
	else :
		muzzle.position = muzzlePosition

func UpdateAimOffset():
	if activeOptic != null:
		aimOffset = abs(raycast.position.y - activeOptic.position.y)

		if weaponData.foldSights:
			skeleton.set_bone_pose_rotation(backSightIndex, Quaternion.from_euler(Vector3(weaponData.foldSightsRotation, 0, 0)))
			skeleton.set_bone_pose_rotation(frontSightIndex, Quaternion.from_euler(Vector3(weaponData.foldSightsRotation, 0, 0)))
	else :
		aimOffset = 0.0

		if weaponData.foldSights:
			skeleton.set_bone_pose_rotation(backSightIndex, Quaternion.from_euler(Vector3(0, 0, 0)))
			skeleton.set_bone_pose_rotation(frontSightIndex, Quaternion.from_euler(Vector3(0, 0, 0)))

func UpdateBarrel():
	if activeBarrel != null:
		isUpgraded = true

		for part in defaultParts:
			part.hide()
		for part in upgradeParts:
			part.show()
	else :
		isUpgraded = false

		for part in defaultParts:
			part.show()
		for part in upgradeParts:
			part.hide()

func IdleState():
	animator.active = false
	gameData.isReloading = false
