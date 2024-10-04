extends Node

class ModInfo:
	var path : String
	var cfg : ConfigFile

func getModsDir() -> String:
	# Get the --main-pack option
	var modsDir = null
	var args = OS.get_cmdline_user_args()
	for i in range(args.size()):
		var arg = args[i]
		# Engine specific options stop
		if arg == "--" || arg == "++":
			break

		if !arg.begins_with("--"):
			continue
		
		var idx = arg.find('=')
		if idx == -1:
			if i == args.size():
				continue
			else:
				if arg == "--mods-dir":
					var val = args[i+1]
					if val.begins_with("-") || val.begins_with("+"):
						continue
					modsDir = val
					break
		else:
			var key = arg.substr(2,idx)
			var val = arg.substr(idx+1)
			if key == "mods-dir":
				modsDir = val
				break

	if modsDir:
		return modsDir

	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://") + "/mods"
	return OS.get_executable_path().get_base_dir() + "/"

func _ready():
	var modsDir = getModsDir()
	if !DirAccess.dir_exists_absolute(modsDir):
		DirAccess.make_dir_recursive_absolute(modsDir)

	print("Loading mods from ", modsDir)
	var da = DirAccess.open(modsDir)
	for mod in da.get_files():
		var zipPath = modsDir + "/" + mod
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

		print("Loading mod \"", modname, "\" (", id, " ", version, ")")
		ProjectSettings.load_resource_pack(zipPath)

		if cfg.has_section("autoload"):
			var entries = cfg.get_section_keys("autoload")
			for k in entries:
				var path = cfg.get_value("autoload", k)
				if !ResourceLoader.exists(path):
					printerr("Autoload '", path, "' defined by mod '", modname, "' does not exist")

				var autoloadRes = load(path)
				var node = null
				if autoloadRes is GDScript:
					node = autoloadRes.new()
				elif autoloadRes is PackedScene:
					node = autoloadRes.instantiate()
					
				if node is Node:
					get_tree().root.add_child(node)
				else:
					printerr("Autoload '", path, "' defined by mod '", modname, "' does not extend class Node!")

		print("Done")
