extends Node3D


var gameData = preload("res://Resources/GameData.tres")
var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")


var heavyGear = false


@onready var interface = $"../../UI/UI_Interface"
@onready var weapons = $"../../Camera/Weapons"
@onready var audio = $"../../Audio"

func _physics_process(delta):
	if !gameData.isCaching && !gameData.flycam:
		Health(delta)
		Stamina(delta)
		Energy(delta)
		Hydration(delta)
		Oxygen(delta)
		BurnDamage(delta)


func Health(delta):
	if gameData.starvation && !gameData.isDead:
		gameData.health -= delta / 10

	if gameData.dehydration && !gameData.isDead:
		gameData.health -= delta / 10

	if gameData.bleeding && !gameData.isDead:
		gameData.health -= delta / 5

	if gameData.fracture && !gameData.isDead:
		gameData.health -= delta / 5

	if gameData.burn && !gameData.isDead:
		gameData.health -= delta / 5

	if gameData.rupture && !gameData.isDead:
		gameData.health -= delta

	if gameData.headshot && !gameData.isDead:
		gameData.health -= delta

	if gameData.health <= 0 && !gameData.isDead:
		Death()

func Energy(delta):
	if !gameData.starvation:
		gameData.energy -= delta / 30.0

	if gameData.energy <= 0 && !gameData.starvation:
		Starvation(true)
	elif gameData.energy > 0 && gameData.starvation:
		Starvation(false)

func Hydration(delta):
	if !gameData.dehydration:
		gameData.hydration -= delta / 20.0

	if gameData.hydration <= 0 && !gameData.dehydration:
		Dehydration(true)
	elif gameData.hydration > 0 && gameData.dehydration:
		Dehydration(false)

func Stamina(delta):
	gameData.weaponPosition = 1 if gameData.isRunning else 2
	if (gameData.isRunning || gameData.overweight || (gameData.isSwimming && gameData.isMoving)) && gameData.bodyStamina > 0:

		if gameData.overweight || gameData.starvation || gameData.dehydration:
			gameData.bodyStamina -= delta * 4.0
		else :
			gameData.bodyStamina -= delta * 2.0


	elif gameData.bodyStamina < 100:
		if gameData.starvation || gameData.dehydration:
			gameData.bodyStamina += delta * 5.0
		else :
			gameData.bodyStamina += delta * 10.0


	if ((gameData.primary || gameData.secondary) && (gameData.isAiming || gameData.isCanted || gameData.isInspecting || gameData.overweight) || (gameData.isSwimming && gameData.isMoving)) && gameData.armStamina > 0:

		if gameData.overweight || gameData.starvation || gameData.dehydration:
			gameData.armStamina -= delta * 4.0
		else :
			gameData.armStamina -= delta * 2.0


	elif gameData.armStamina < 100:

		if gameData.starvation || gameData.dehydration:
			gameData.armStamina += delta * 10.0
		else :
			gameData.armStamina += delta * 20.0

	gameData.bodyStamina = clampf(gameData.bodyStamina, 0, 100)
	gameData.armStamina = clampf(gameData.armStamina, 0, 100)

func Oxygen(delta):

	if gameData.isSubmerged:
		if gameData.isSwimming:
			gameData.oxygen -= delta * 4.0
		else :
			gameData.oxygen -= delta * 2.0


	elif gameData.oxygen < 100:
		gameData.oxygen += delta * 50.0


	if gameData.oxygen <= 0 && !gameData.isDead:
		Death()




func Death():

	if gameData.flycam:
		return 

	PlayDeathAudio()
	audio.breathing.stop()
	audio.heartbeat.stop()
	gameData.health = 0
	gameData.isDead = true
	gameData.freeze = true
	weapons.ClearWeapons()


	if !gameData.permadeath && !gameData.shelter && !gameData.tutorial:
		Loader.ResetGear()
		print("DEATH: Standard")


	if gameData.shelter:
		Loader.ResetGear()
		Loader.SaveShelter()
		print("DEATH: Shelter")


	if gameData.permadeath:
		Loader.ResetSave()
		print("DEATH: Vostok")

	Loader.LoadScene("Death")




func Consume(item: ItemData):
	gameData.health += item.health
	gameData.energy += item.energy
	gameData.hydration += item.hydration

	gameData.health = clampf(gameData.health, 0, 100)
	gameData.energy = clampf(gameData.energy, 0, 100)
	gameData.hydration = clampf(gameData.hydration, 0, 100)

	if item.bleeding:
		Bleeding(false)
	if item.burn:
		Burn(false)
	if item.fracture:
		Fracture(false)
	if item.rupture:
		Rupture(false)
	if item.headshot:
		Headshot(false)



func ExplosionDamage():

	if !gameData.bleeding:
		Bleeding(true)

	gameData.damage = true
	gameData.health -= 40.0

func BurnDamage(delta):
	if gameData.isBurning:
		gameData.damage = true
		gameData.health -= delta * 10

func FallDamage(distance: float):
	if distance > 10:
		gameData.health = 0.0
		gameData.damage = true
		Fracture(true)
	elif distance > 5:
		gameData.health -= randi_range(5, 20)
		gameData.damage = true
		Fracture(true)

func WeaponDamage(damage: int, penetration: int):

	var hitbox = randi_range(1, 3)



	if hitbox == 1:
		print("Hit: HEAD")


		if interface.HelmetCheck(penetration):
			gameData.impact = true
			PlayArmorAudio()
			return 



	elif hitbox == 2:
		print("Hit: TORSO")


		if interface.PlateCheck(penetration):
			gameData.impact = true
			PlayArmorAudio()
			return 

	elif hitbox == 3:
		print("Hit: LIMBS")



	var medicalRoll = randi_range(0, 100)


	if hitbox == 1 && medicalRoll < 5 && !gameData.headshot:
		Headshot(true)

	elif hitbox == 2 && medicalRoll < 5 && !gameData.rupture:
		Rupture(true)

	else :

		if medicalRoll > 0 && medicalRoll <= 5 && !gameData.bleeding:
			Bleeding(true)

		elif medicalRoll > 5 && medicalRoll <= 10 && !gameData.fracture:
			Fracture(true)
		else :
			PlayImpactAudio()



	if !gameData.isDead:
		gameData.damage = true
		gameData.health -= randf_range(damage / 4.0, damage / 2.0)
		gameData.health = clampf(gameData.health, 0, 100)




func Overweight(active: bool):
	if active:
		gameData.overweight = true
		PlayIndicator()
		PlayOverweight()
	else :
		gameData.overweight = false

func Starvation(active: bool):
	if active:
		gameData.starvation = true
		PlayIndicator()
		PlayStarvation()
	else :
		gameData.starvation = false

func Dehydration(active: bool):
	if active:
		gameData.dehydration = true
		PlayIndicator()
		PlayDehydration()
	else :
		gameData.dehydration = false

func Bleeding(active: bool):
	if active:
		gameData.bleeding = true
		PlayIndicator()
		PlayBleeding()
	else :
		gameData.bleeding = false

func Fracture(active: bool):
	if active:
		gameData.fracture = true
		PlayIndicator()
		PlayFracture()
	else :
		gameData.fracture = false

func Burn(active: bool):
	if active:
		gameData.burn = true
		PlayIndicator()
		PlayBurn()
	else :
		gameData.burn = false

func Rupture(active: bool):
	if active:
		gameData.rupture = true
		PlayIndicator()
		PlayRupture()
	else :
		gameData.rupture = false

func Headshot(active: bool):
	if active:
		gameData.headshot = true
		PlayIndicator()
		PlayRupture()
	else :
		gameData.headshot = false







func PlayDamageAudio():
	var damage = audioInstance2D.instantiate()
	add_child(damage)
	damage.PlayInstance(audioLibrary.damage)

func PlayImpactAudio():
	var impact = audioInstance2D.instantiate()
	add_child(impact)
	impact.PlayInstance(audioLibrary.impact)

func PlayArmorAudio():
	var armor = audioInstance2D.instantiate()
	add_child(armor)
	armor.PlayInstance(audioLibrary.armor)

func PlayDeathAudio():
	var death = audioInstance2D.instantiate()
	add_child(death)
	death.PlayInstance(audioLibrary.death)

func PlayIndicator():
	var indicator = audioInstance2D.instantiate()
	add_child(indicator)
	indicator.PlayInstance(audioLibrary.indicator)

func PlayOverweight():
	var overweight = audioInstance2D.instantiate()
	add_child(overweight)
	overweight.PlayInstance(audioLibrary.overweight)

func PlayStarvation():
	var starvation = audioInstance2D.instantiate()
	add_child(starvation)
	starvation.PlayInstance(audioLibrary.starvation)

func PlayDehydration():
	var dehydration = audioInstance2D.instantiate()
	add_child(dehydration)
	dehydration.PlayInstance(audioLibrary.dehydration)

func PlayBleeding():
	var bleeding = audioInstance2D.instantiate()
	add_child(bleeding)
	bleeding.PlayInstance(audioLibrary.bleeding)

func PlayFracture():
	var fracture = audioInstance2D.instantiate()
	add_child(fracture)
	fracture.PlayInstance(audioLibrary.fracture)

func PlayBurn():
	var burn = audioInstance2D.instantiate()
	add_child(burn)
	burn.PlayInstance(audioLibrary.burn)

func PlayRupture():
	var rupture = audioInstance2D.instantiate()
	add_child(rupture)
	rupture.PlayInstance(audioLibrary.rupture)
