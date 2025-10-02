extends Control
class_name InjectorMain

@export var VersionLabel: Label
@export var StatusLabel: Label
@export var Progress: ProgressBar

@export var LoadingScreen: Control
@export var ConfigScreen: Control
@export var WindowsDeveloperScreen: Control

@export var SettingsPage: Control
@export var Mods: ModList
@export var Updater: AutoUpdater

var version

var pckName = ""
const configPath = "user://ModConfig.json"
class ModLoaderConfig:
	var customModDir: String = ""
	var startOnConfigScreen: bool = false
	var autoUpdatePreRelease: bool = false
	var allowAutoUpdate: bool = true
	var allowModAutoUpdates: bool = true
	var autoUpdateDisalbedMods: bool = false
var config: ModLoaderConfig = ModLoaderConfig.new()

func loadConfig():
	if !FileAccess.file_exists(configPath):
		return

	var f = FileAccess.open(configPath, FileAccess.READ)
	var obj = JSON.parse_string(f.get_as_text())
	config = ModLoaderConfig.new()
	if "customModDir" in obj:
		config.customModDir = obj["customModDir"]
	if "startOnConfigScreen" in obj:
		config.startOnConfigScreen = obj["startOnConfigScreen"]
	if "autoUpdatePreRelease" in obj:
		config.autoUpdatePreRelease = obj["autoUpdatePreRelease"]
	if "allowAutoUpdate" in obj:
		config.allowAutoUpdate = obj["allowAutoUpdate"]
	if "allowModAutoUpdates" in obj:
		config.allowModAutoUpdates = obj["allowModAutoUpdates"]
	if "autoUpdateDisalbedMods" in obj:
		config.autoUpdateDisalbedMods = obj["autoUpdateDisalbedMods"]
	SettingsPage.onLoaded()

func saveConfig():
	var jarr = {
		"customModDir": config.customModDir,
		"startOnConfigScreen": config.startOnConfigScreen,
		"autoUpdatePreRelease": config.autoUpdatePreRelease,
		"allowAutoUpdate": config.allowAutoUpdate,
		"allowModAutoUpdates": config.allowModAutoUpdates,
		"autoUpdateDisalbedMods": config.autoUpdateDisalbedMods
	}
	var jstr = JSON.stringify(jarr)
	var f = FileAccess.open(configPath, FileAccess.WRITE)
	f.store_string(jstr)
	f.flush()
	f.close()

func shutdown(msg: String = "Shutting down"):
	StatusLabel.text = msg
	Progress.value = 1.0
	Progress.max_value = 1.0
	create_tween().tween_property(Progress, "value", 0.0, 3.0)
	await get_tree().create_timer(3.0).timeout
	get_tree().quit(1)

func showHttpProgress(httpReq: HTTPRequest):
	while httpReq.get_http_client_status() != HTTPClient.Status.STATUS_DISCONNECTED && \
		httpReq.get_http_client_status() != HTTPClient.Status.STATUS_CONNECTION_ERROR && \
		httpReq.get_http_client_status() != HTTPClient.Status.STATUS_TLS_HANDSHAKE_ERROR && \
		httpReq.get_http_client_status() != HTTPClient.Status.STATUS_CANT_CONNECT && \
		httpReq.get_http_client_status() != HTTPClient.Status.STATUS_CANT_RESOLVE:
			var bodySize = httpReq.get_body_size()
			if bodySize == -1:
				Progress.max_value = 1
				Progress.value = 0
			else:
				Progress.max_value = bodySize
				Progress.value = httpReq.get_downloaded_bytes()
			await RenderingServer.frame_pre_draw
	Progress.value = httpReq.get_body_size()

func getGameDir() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir() + "/"
	return OS.get_executable_path().get_base_dir() + "/"

func showLoadingScreen():
	WindowsDeveloperScreen.hide()
	ConfigScreen.hide()
	
	StatusLabel.text = "Launching Road to Vostok..."
	LoadingScreen.show()

func showWindowsDeveloperScreen():
	ConfigScreen.hide()
	LoadingScreen.hide()

	WindowsDeveloperScreen.show()

func showConfigScreen():
	WindowsDeveloperScreen.hide()
	LoadingScreen.hide()

	ConfigScreen.show()

func retrySymlinkCheck() -> void:
	if !canCreateSymlinks():
		showWindowsDeveloperScreen()
	else:
		launchOrShowConfig()

func _ready() -> void:
	loadConfig()
	if !OS.is_debug_build():
		pckName = OS.get_executable_path().get_file().trim_suffix(".exe").trim_suffix(".x86_64") + ".pck"
	else: pckName = "Road_to_Vostok_Demo.pck"

	if !OS.has_feature("editor"):
		pckName = OS.get_executable_path().get_file().trim_suffix(".exe").trim_suffix(".x86_64") + ".pck"

	var f = FileAccess.open("res://VM_VERSION", FileAccess.READ)
	version = f.get_as_text()
	VersionLabel.text = "Version " + version
	f.close()

	Mods.loadMods()
	showLoadingScreen()
	if !OS.has_feature("editor") and config.allowAutoUpdate:
		await Updater.checkInjectorUpdate()
	else:
		await Updater.checkModUpdates()

func launchOrShowConfig():
	if !canCreateSymlinks():
		if windowsIsDeveloper():
			OS.alert("Cannot create symlinks but developer mode is enabled! This should not happen!")
			get_tree().quit()
			return
		else:
			showWindowsDeveloperScreen()
			return

	if config.startOnConfigScreen:
		showConfigScreen()
	else:
		showLoadingScreen()
		launch()

func getModsDir() -> String:
	if config.customModDir:
		return config.customModDir
	return getGameDir() + "/mods"

func openMods() -> void:
	OS.shell_show_in_file_manager(getModsDir())

func openUser() -> void:
	OS.shell_show_in_file_manager(OS.get_user_data_dir())

var isLaunching = false
var launchTimer: Timer
var launchTween: Tween
func launch() -> void:
	isLaunching = true
	StatusLabel.text = "Launching Road to Vostok
Press any key to abort or configure"
	var launchTime = 3.0
	launchTimer = Timer.new()
	add_child(launchTimer)
	launchTimer.timeout.connect(injectAndLaunch)
	launchTimer.start(launchTime)

	Progress.value = 0.0
	Progress.max_value = 1.0
	launchTween = create_tween()
	launchTween.tween_property(Progress, "value", 1.0, launchTime)

func _input(event: InputEvent) -> void:
	if !isLaunching:
		return
	if event.is_pressed():
		cancelLaunch()

func cancelLaunch() -> void:
	launchTimer.stop()
	launchTimer.queue_free()
	launchTimer = null

	launchTween.stop()
	launchTween = null

	isLaunching = false
	showConfigScreen()

func injectAndLaunch(modded: bool = true) -> void:
	saveConfig()
	showLoadingScreen()
	startGame(modded)

const forbiddenOverrideSections = ["autoload", "vostokmods"]
const REPLACEME_NULL = "%VM_REPLACEME_NULL%"
const REPLACEME_EMPTY = "%VM_REPLACEME_EMPTY%"
func startGame(modded: bool = true) -> void:
	var pckPath = getGameDir().path_join(pckName)
	if !FileAccess.file_exists(pckPath):
		shutdown("PCK doesn't exist " + pckPath)
		return

	if !modded:
		var pureArgs = ["--main-pack", pckPath, "--"]
		pureArgs.append_array(OS.get_cmdline_user_args())
		OS.create_process(OS.get_executable_path(), pureArgs, false)
		get_tree().quit()
		return

	# Create temp run dir
	var runDir = getTempDir()
	print("Run dir: " + runDir)
	var da = DirAccess.open(runDir)

	# Link the executable to the run dir
	var runExec = runDir.path_join(OS.get_executable_path().get_file())
	var err = da.create_link(OS.get_executable_path(), runExec)
	if err != OK:
		shutdown("Failed to create executable symlink, error code " + str(err))
		return

	# Link the game PCK to the run dir
	var runPck = runDir.path_join(pckName)
	err = da.create_link(pckPath, runPck)
	if err != OK:
		shutdown("Failed to create PCK symlink, error code " + str(err))
		return

	# Copy main loop script and assets to run dir
	for f in ["ProjectDumper.gd", "MainLoop.gd", "ModLoader.gd"]:
		var srcFa = FileAccess.open("res://ModLoader/" + f, FileAccess.ModeFlags.READ)
		var destFa = FileAccess.open(runDir.path_join(f), FileAccess.ModeFlags.WRITE)
		destFa.store_buffer(srcFa.get_buffer(srcFa.get_length()))
		destFa.close()
		srcFa.close()

	# Dump the project.godot
	var dumperPid = OS.create_process(runExec, ["--headless", "--quit", "-s", "ProjectDumper.gd", "--path", runDir, "--main-pack", runPck], false)
	if dumperPid == -1:
		shutdown("Failed to dump project")
		return

	while OS.is_process_running(dumperPid):
		await RenderingServer.frame_post_draw

	var orderedMods = Mods.mods.duplicate()
	orderedMods.sort_custom(func (a, b) -> bool: return a.priority > b.priority)
	var reverseMods = orderedMods.duplicate()
	reverseMods.reverse()

	# Copy mod files
	for mod in reverseMods:
		if mod.disabled: continue
		if !mod.config.has_section_key("mod", "copyFiles"): continue
		var copyFilesDir = mod.config.get_value("mod", "copyFiles")
		if copyFilesDir is not String:
			printerr("copyFiles for mod ", mod.name, " is not a path to a directory!")
			continue
		if !copyFilesDir.ends_with("/"): copyFilesDir += "/"
		var zip = ZIPReader.new()
		zip.open(mod.getPath())
		for f in zip.get_files():
			# Ignore folders
			if f[f.length()-1] == '/': continue

			if !f.begins_with(copyFilesDir): continue
			var fname = f.trim_prefix(copyFilesDir)
			if !fname || !fname.length(): continue
			var outPath = runDir.path_join(fname).simplify_path()
			if !outPath.begins_with(runDir):
				printerr("File ", fname, " in mod ", mod.name, " tried to escape the run dir!")
				continue
			print("Copying file ", fname, " from mod ", mod.name)
			DirAccess.make_dir_recursive_absolute(outPath.get_base_dir())
			var buf = zip.read_file(f)
			var outf = FileAccess.open(outPath, FileAccess.ModeFlags.WRITE)
			if outf == null:
				OS.shell_open(runDir)
				shutdown("Failed to copy\n" + fname + "\nto\n" + outPath + "\nfrom mod " + mod.name + "\nError " + str(FileAccess.get_open_error()))
				return
			outf.store_buffer(buf)
			outf.close()

	var tempClassCachePath = runDir.path_join("global_script_class_cache.cfg")
	var projectPath = runDir.path_join("project.godot")
	if !FileAccess.file_exists(projectPath) && !FileAccess.file_exists(tempClassCachePath):
		shutdown("Project dumper failed to dump")
		return
	
	# Add the mod classes to the class list
	var classCachePath = runDir.path_join(".godot/global_script_class_cache.cfg")
	var classListCfg: ConfigFile = ConfigFile.new()
	classListCfg.load(tempClassCachePath)
	DirAccess.remove_absolute(tempClassCachePath)
	var classList = classListCfg.get_value("", "list", [])
	for mod in reverseMods:
		if mod.disabled: continue
		if !mod.config.has_section_key("mod", "class_list"): continue
		var modClassList = mod.config.get_value("mod", "class_list")
		print(modClassList)
		if modClassList is Array[Dictionary]:
			for c in modClassList:
				classList.append(c)
				# Copy the file into the run dir
				var classOutPath = runDir.path_join(c.path.trim_prefix("res://"))
				DirAccess.make_dir_recursive_absolute(classOutPath.get_base_dir())
				var classF = FileAccess.open(classOutPath, FileAccess.WRITE)

				var zip = ZIPReader.new()
				zip.open(mod.getPath())
				classF.store_buffer(zip.read_file(c.path.trim_prefix("res://")))
				zip.close()
				classF.close()

	# Save the class list
	classListCfg.set_value("", "list", classList)
	DirAccess.make_dir_recursive_absolute(classCachePath.get_base_dir())
	var cacheListFile = FileAccess.open(classCachePath, FileAccess.WRITE)
	cacheListFile.store_string(classListCfg.encode_to_text())
	cacheListFile.close()

	# Create override.cfg
	var project = ConfigFile.new()
	project.load(projectPath)
	var override = ConfigFile.new()
	# Add the mod .zip paths to be loaded by MainLoop
	var zips = []
	for mod in orderedMods:
		if mod.disabled: continue
		zips.append(mod.getPath())
	override.set_value("vostokmods", "zips", zips)
	# Merge mod override.cfg
	for mod in reverseMods:
		if mod.disabled: continue
		var zip = ZIPReader.new()
		zip.open(mod.getPath())
		if !zip.file_exists("override.cfg"):
			zip.close()
			continue
		var modCfg = ConfigFile.new()
		err = modCfg.parse(zip.read_file("override.cfg").get_string_from_utf8())
		if err != OK:
			printerr("Failed to read mod override config for mod ", mod.name)
			zip.close()
			continue
		for sect in modCfg.get_sections():
			if sect in forbiddenOverrideSections:
				printerr("Mod ", mod.name, " tried to override forbidden section ", sect, ", ignoring")
				continue
			for k in modCfg.get_section_keys(sect):
				override.set_value(sect, k, modCfg.get_value(sect, k))

	# Create autoloads
	# Remove built-in autoloads. Adding them later changes their order
	for al in project.get_section_keys("autoload"):
		override.set_value("autoload", REPLACEME_EMPTY + al, REPLACEME_NULL);
	# Load ModLoader
	override.set_value("autoload", "ModLoader", "*res://ModLoader.gd")
	# Load early mod autoloads
	for mod in orderedMods:
		if mod.disabled: continue
		for al in mod.config.get_section_keys("autoload"):
			var path = mod.config.get_value("autoload", al)
			if path.begins_with("!"):
				override.set_value("autoload", al, path.trim_prefix("!"));
	# Load built-in autoloads
	for al in project.get_section_keys("autoload"):
		override.set_value("autoload", al, project.get_value("autoload", al));
	# Load late mod autoloads
	for mod in orderedMods:
		if mod.disabled: continue
		for al in mod.config.get_section_keys("autoload"):
			var path = mod.config.get_value("autoload", al)
			if !path.begins_with("!"):
				override.set_value("autoload", al, path);

	# Serialize override.cfg
	var overrideStr = override.encode_to_text()
	# Replace REPLACEMEs
	overrideStr = overrideStr.replace("\n" + REPLACEME_EMPTY, "\n").replace("=\"" + REPLACEME_NULL + "\"\n", "=null\n")
	# Write override.cfg
	var fa = FileAccess.open(runDir.path_join("override.cfg"), FileAccess.ModeFlags.WRITE)
	fa.store_string(overrideStr)
	fa.close()

	# Run the game
	var args = ["-s", "MainLoop.gd", "--path", runDir, "--main-pack", runPck, "--"]
	args.append_array(OS.get_cmdline_user_args())
	print(args)
	var pid = OS.create_process(runExec, args, false)
	if pid == -1:
		shutdown("Failed to start Road to Vostok")
		return
	print("Game started with pid " + str(pid))
	get_tree().quit()

func getTempDir() -> String:
	var osname = OS.get_name()
	if osname == "Linux":
		var out = []
		var exitCode = OS.execute("mktemp", ["-d"], out)
		if exitCode != 0:
			OS.alert("mktemp failed with eixt code " + str(exitCode))
			get_tree().quit()
		var dir = out[0].trim_suffix("\n")
		DirAccess.make_dir_recursive_absolute(dir)
		return dir
	elif osname == "Windows":
		var dir = OS.get_environment("TEMP").path_join("temp." + str(randi()))
		DirAccess.make_dir_recursive_absolute(dir)
		return dir
	else:
		OS.alert("Platform not supported: " + osname)
		get_tree().quit()
		return ""

func openDonatePage():
	OS.shell_open("https://github.com/sponsors/Ryhon0")

func windowsGetRegistry(reg: String, key: String) -> String:
	var out = []
	var exitcode = OS.execute("reg.exe", ["query", reg, "/v", key, "/t", "REG_DWORD"], out)
	if exitcode != 0:
		OS.alert("reg.exe exited with " + str(exitcode))
		return ""
	if out.size() == 0: return ""
	var lines = out[0].split("\r\n")
	if lines[1] != reg: return ""
	var split = lines[2].split(" ")
	return split[split.size() - 1]

func windowsIsDeveloper() -> bool:
	if OS.get_name() != "Windows": return true
	return windowsGetRegistry("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppModelUnlock", "AllowDevelopmentWithoutDevLicense") == "0x1"

func windowsOpenDeveloperSettings() -> void:
	OS.shell_open("ms-settings:developers")

func canCreateSymlinks() -> bool:
	var tmpDir = getTempDir()
	var tmpFile1 = tmpDir.path_join(str(randi()) + ".tmp0")
	var tmpFile2 = tmpFile1 + ".symlink"
	FileAccess.open(tmpFile1, FileAccess.ModeFlags.WRITE).close()
	if !DirAccess.dir_exists_absolute(tmpDir):
		DirAccess.make_dir_recursive_absolute(tmpDir)
	var dir = DirAccess.open(tmpDir)
	if dir == null:
		OS.alert("Failed to create temp dir while testing symlinks\nError " + str(DirAccess.get_open_error()))
		return false
	var err = dir.create_link(tmpFile1, tmpFile2)
	return err == OK
