extends "res://Scripts/Transition.gd"

var preferences: Preferences

func Interact():
    if not deactivated and not tutorialExit:
        ProgressWeather()

    super()

    if not deactivated and not tutorialExit:
        SetMusic()

func ProgressWeather():
    if shelterExit:
        if randf() < 0.15:
            gameData.season = (gameData.season % 2) + 1

        if randf() < 0.5:
            if randf() < 0.75:
                gameData.TOD = (randi() % 2) + 1
            else:
                gameData.TOD = (randi() % 4) + 1

    else:
        if (gameData.TOD == 2 && randf() < 0.33) or (gameData.TOD != 2 && randf() < 0.5):
            gameData.TOD = (gameData.TOD % 4) + 1

        if randf() < 0.15:
            gameData.aurora = true
        else:
            gameData.aurora = false

    if randf() < 0.5:
        if randf() < 0.75:
            gameData.weather = 1
        else:
            gameData.weather = (randi() % 4) + 1

    preferences = Preferences.Load()
    preferences.season = gameData.season
    preferences.TOD = gameData.TOD
    preferences.weather = gameData.weather
    preferences.aurora = gameData.aurora
    preferences.Save()

func SetMusic():
    if gameData.shelter:
        gameData.musicPreset = 1
    elif gameData.permadeath:
        gameData.musicPreset = 4
    elif gameData.currentMap == "Minefield":
        gameData.musicPreset = 3
    else:
        gameData.musicPreset = 2

    preferences = Preferences.Load()
    if preferences.musicPreset != gameData.musicPreset:
        preferences.musicPreset = gameData.musicPreset
        preferences.Save()
