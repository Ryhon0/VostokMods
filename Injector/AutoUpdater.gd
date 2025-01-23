extends Node
class_name AutoUpdater

@export var Main : InjectorMain

func _ready() -> void:
	pass

func checkInjectorUpdate():
	var deletemePath = ProjectSettings.globalize_path(".").path_join("Injector.pck.deleteme")
	if FileAccess.file_exists(deletemePath):
		DirAccess.remove_absolute(deletemePath)

	var httpReq = HTTPRequest.new()
	add_child(httpReq)
	var err = httpReq.request(Main.githubAPIBaseURL + "repos/Ryhon0/VostokMods/releases", ["accept: application/vnd.github+json"])
	if err != OK:
		push_error("Failed to create mod loader releases request ", err)
		if Main.config.allowModsAutoUpdate: 
			await checkModUpdates()
		else:
			Main.Mods.loadMods()
			Main.launchOrShowConfig()
		return

	Main.StatusLabel.text = "Checking for updates"
	Main.showHttpProgress(httpReq)

	httpReq.request_completed.connect(injectorReleasesRequestCompleted)

func injectorReleasesRequestCompleted(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Failed to get mod loader releases")
		if Main.config.allowModsAutoUpdate: 
			await checkModUpdates()
		else:
			Main.Mods.loadMods()
			Main.launchOrShowConfig()
		return
	if response_code < 200 || response_code >= 300:
		push_error("Failed to get mod loader releases (HTTP code " + str(response_code) + ")")
		if Main.config.allowModsAutoUpdate: 
			await checkModUpdates()
		else:
			Main.Mods.loadMods()
			Main.launchOrShowConfig()
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	for r in json:
		if r["draft"]: continue
		if r["prerelease"] && !Main.config.autoUpdatePreRelease:
			continue
		var tag = r["tag_name"]

		var injectorAsset
		for a in r["assets"]:
			if a["name"] == "Injector.pck":
				injectorAsset = a
				break
		if !injectorAsset:
			continue

		print("Latest version: " + tag)
		if Main.version != tag:
			downloadLoaderUpdate(tag, injectorAsset)
		else: 
			if Main.config.allowModsAutoUpdate: 
				await checkModUpdates()
			else:
				Main.Mods.loadMods()
				Main.launchOrShowConfig()
		return

func downloadLoaderUpdate(tag, asset):
	var httpReq = HTTPRequest.new()
	add_child(httpReq)
	var err = httpReq.request(asset["browser_download_url"])
	if err != OK:
		Main.StatusLabel.text = "Failed to download mod loader update.\nCode " + str(err)
		if Main.config.allowModsAutoUpdate: 
			get_tree().create_timer(2).timeout.connect(checkModUpdates)
		else:
			get_tree().create_timer(2).timeout.connect(func(): Main.Mods.loadMods(); Main.launchOrShowConfig())
		return

	Main.StatusLabel.text = "Downloading mod loader version " + tag
	Main.showHttpProgress(httpReq)

	httpReq.request_completed.connect(injectorFileDownloaded)

func injectorFileDownloaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Failed to download mod loader")
		Main.StatusLabel.text = "Failed to save mod loader, error " + str(FileAccess.get_open_error())
		if Main.config.allowModsAutoUpdate: 
			get_tree().create_timer(2).timeout.connect(checkModUpdates)
		else:
			get_tree().create_timer(2).timeout.connect(func(): Main.Mods.loadMods(); Main.launchOrShowConfig())
		return
	if response_code < 200 || response_code >= 300:
		push_error("Failed to get mod loader releases (HTTP code " + str(response_code) + ")")
		Main.StatusLabel.text = "Failed to save mod loader, error " + str(FileAccess.get_open_error())
		if Main.config.allowModsAutoUpdate: 
			get_tree().create_timer(2).timeout.connect(checkModUpdates)
		else:
			get_tree().create_timer(2).timeout.connect(func(): Main.Mods.loadMods(); Main.launchOrShowConfig())
		return

	var dir = ProjectSettings.globalize_path(".")
	var injectorPath = dir.path_join("Injector.pck")
	var deletemePath = dir.path_join("Injector.pck.deleteme")
	
	var err = DirAccess.rename_absolute(injectorPath, deletemePath)
	if err != OK:
		Main.StatusLabel.text = "Failed to move moad loader, error " + str(err)
		if Main.config.allowModsAutoUpdate: 
			get_tree().create_timer(2).timeout.connect(checkModUpdates)
		else:
			get_tree().create_timer(2).timeout.connect(func(): Main.Mods.loadMods(); Main.launchOrShowConfig())
		return
	
	var f = FileAccess.open(injectorPath, FileAccess.WRITE)
	if !f:
		DirAccess.rename_absolute(deletemePath, injectorPath)
		Main.StatusLabel.text = "Failed to save mod loader, error " + str(FileAccess.get_open_error())
		if Main.config.allowModsAutoUpdate: 
			get_tree().create_timer(2).timeout.connect(checkModUpdates)
		else:
			get_tree().create_timer(2).timeout.connect(func(): Main.Mods.loadMods(); Main.launchOrShowConfig())
		return
	f.store_buffer(body)
	f.close()

	var args = ["--main-pack", "Injector.pck", "--"]
	args.append(OS.get_cmdline_user_args())
	OS.create_process(OS.get_executable_path(), args, false)
	get_tree().quit()

func checkModUpdates():
	Main.StatusLabel.text = "Checking for mod updates"
	Main.Progress.value = 0
	Main.Progress.max_value = 1

	var updatableMods = []
	var mwsIds = []
	for mod in Main.Mods.mods:
		if mod.config.has_section_key("updates", "modworkshop"):
			updatableMods.append(mod)
			mwsIds.append(mod.config.get_value("updates", "modworkshop"))
	
	if !updatableMods.size():
		Main.launchOrShowConfig()
		return # No updatable mods found
	
	var idChunks = chunk(mwsIds, 100)
	var latestVersions = {}
	for ids in idChunks:
		var httpReq = HTTPRequest.new()
		add_child(httpReq)
		var err = httpReq.request("https://api.modworkshop.net/mods/versions",\
			["Content-Type: application/json", "Accept: application/json"],\
			HTTPClient.METHOD_GET, JSON.stringify({"mod_ids": ids}))
		if err != OK:
			push_error("Failed to create mod versions request ", str(err))
			continue
		Main.showHttpProgress(httpReq)
		var res = await httpReq.request_completed
		if res[0] != HTTPRequest.RESULT_SUCCESS:
			push_error("Mod versions request failed, code ", str(res[0]))
			continue
		var response_code = res[1]
		if response_code < 200 || response_code >= 300:
			push_error("Failed to get mod versions (HTTP code " + str(response_code) + ")")
			continue
		
		var versions = JSON.parse_string(res[3].get_string_from_utf8())
		if versions is Dictionary:
			latestVersions.merge(versions)
	
	for k in latestVersions.keys():
		var mod = updatableMods.filter(func(m): return m.config.get_value("updates", "modworkshop") == int(k))[0]
		
		var version = mod.config.get_value("mod", "version")
		var modName = mod.config.get_value("mod", "name")
		var latestVersion = latestVersions[k]

		if !latestVersion: # Version is empty
			push_warning("MWS mod ", k, " has an empty version!")
			continue

		var zip = mod.zipPath
		if FileAccess.file_exists(zip + ".zip"):
			zip += ".zip"
		elif FileAccess.file_exists(zip + ".zip.disabled"):
			zip += ".zip.disabled"

		if version == latestVersion: # Already up to date 
			print("MWS mod ", k , " is up to date")
			continue
		
		print("Updating MWS mod ", k , " to ", latestVersion)
		Main.StatusLabel.text = "Updating " + modName + "\n" + version + "→" + latestVersion
		
		var httpReq = HTTPRequest.new()
		add_child(httpReq)
		var err = httpReq.request("https://api.modworkshop.net/mods/"+str(k)+"/download")
		if err != OK:
			push_error("Failed to create mod download request ", str(err))
			continue
		Main.showHttpProgress(httpReq)
		var res = await httpReq.request_completed
		if res[0] != HTTPRequest.RESULT_SUCCESS:
			push_error("Mod download request failed, code ", str(res[0]))
			continue
		var response_code = res[1]
		if response_code < 200 || response_code >= 300:
			push_error("Failed to download mod (HTTP code " + str(response_code) + ")")
			continue

		err = OS.move_to_trash(zip)
		if err != OK:
			push_error("Failed to move mod to trash ", str(err))
			continue
		
		var f = FileAccess.open(zip, FileAccess.WRITE)
		if !f:
			push_error("Failed to open mod file ", FileAccess.get_open_error())
			continue
		
		f.store_buffer(res[3])
		f.close()
	
	Main.Mods.loadMods()
	Main.launchOrShowConfig()

func chunk(arr, size):
	var ret = []
	var i = 0
	var j = -1
	for el in arr:
		if i % size == 0:
			ret.push_back([])
			j += 1;
		ret[j].push_back(el)
		i += 1
	return ret
