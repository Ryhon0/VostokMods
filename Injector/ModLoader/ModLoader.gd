extends Node

var loadedMods: Array[ModInfo] = []

signal modLoaded(mod: ModInfo)
signal allModsLoaded()

class ModInfo:
	var path: String
	var cfg: ConfigFile

func _ready():
	if !ProjectSettings.has_setting("vostokmods/zips"):
		print("vostokmods/zips not defined! Cannot load mods!")
		return

	print("Loading mods")
	for zipPath in ProjectSettings.get_setting("vostokmods/zips"):
		print("Loading ", zipPath)

		var zipReader = ZIPReader.new()
		var err = zipReader.open(zipPath)
		if err != OK:
			printerr("Failed to open mod ZIP: ", zipPath, "(", err, ")")
			continue
		
		if !zipReader.file_exists("mod.txt"):
			printerr("Cannot find mod.txt in ", zipPath)
			continue
		
		var cfgStr = zipReader.read_file("mod.txt").get_string_from_utf8()
		zipReader.close()

		var cfg = ConfigFile.new()
		var cfgErr = cfg.parse(cfgStr)
		if cfgErr != OK:
			printerr("Failed to parse mod.txt in ", zipPath, " (", cfgErr, ")")
			continue
		
		if !cfg.has_section_key("mod", "name"):
			printerr("No key 'name' in section [mod] in mod.txt in ", zipPath)
			continue
		var modname = cfg.get_value("mod", "name")
		
		if !cfg.has_section_key("mod", "id"):
			printerr("No key 'id' in section [mod] in mod.txt in ", zipPath)
			continue
		var id = cfg.get_value("mod", "id")
		
		if !cfg.has_section_key("mod", "version"):
			printerr("No key 'version' in section [mod] in mod.txt in ", zipPath)
			continue
		var version = cfg.get_value("mod", "version")
			
		var info = ModInfo.new()
		info.cfg = cfg
		info.path = zipPath
		print("Mod loaded \"", modname, "\" (", id, " ", version, ")")

		loadedMods.append(info)
		modLoaded.emit(info)

	print("Done loading mods")
	allModsLoaded.emit()