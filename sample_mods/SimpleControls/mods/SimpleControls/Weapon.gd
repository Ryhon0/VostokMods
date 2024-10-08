extends "res://Scripts/Weapon.gd"

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
