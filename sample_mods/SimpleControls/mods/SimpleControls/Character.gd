extends "res://Scripts/Character.gd"

func _process(delta):
	# super()
	gameData.weaponPosition = 1 if gameData.isRunning else 2

func Stamina(delta):
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
