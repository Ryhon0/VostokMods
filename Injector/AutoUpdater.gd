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
		Main.launchOrShowConfig()
		return

	Main.StatusLabel.text = "Checking for updates"
	Main.showHttpProgress(httpReq)

	httpReq.request_completed.connect(injectorReleasesRequestCompleted)

func injectorReleasesRequestCompleted(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Failed to get mod loader releases")
		Main.launchOrShowConfig()
		return
	if response_code < 200 || response_code >= 300:
		push_error("Failed to get mod loader releases (HTTP code " + str(response_code) + ")")
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
		else: Main.launchOrShowConfig()
		return

func downloadLoaderUpdate(tag, asset):
	var httpReq = HTTPRequest.new()
	add_child(httpReq)
	var err = httpReq.request(asset["browser_download_url"])
	if err != OK:
		Main.StatusLabel.text = "Failed to download mod loader update.\nCode " + str(err)
		get_tree().create_timer(2).timeout.connect(Main.launchOrShowConfig)
		return

	Main.StatusLabel.text = "Downloading mod loader version " + tag
	Main.showHttpProgress(httpReq)

	httpReq.request_completed.connect(injectorFileDownloaded)

func injectorFileDownloaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Failed to download mod loader")
		Main.StatusLabel.text = "Failed to save mod loader, error " + str(FileAccess.get_open_error())
		get_tree().create_timer(2).timeout.connect(Main.launchOrShowConfig)
		return
	if response_code < 200 || response_code >= 300:
		push_error("Failed to get mod loader releases (HTTP code " + str(response_code) + ")")
		Main.StatusLabel.text = "Failed to save mod loader, error " + str(FileAccess.get_open_error())
		get_tree().create_timer(2).timeout.connect(Main.launchOrShowConfig)
		return

	var dir = ProjectSettings.globalize_path(".")
	var injectorPath = dir.path_join("Injector.pck")
	var deletemePath = dir.path_join("Injector.pck.deleteme")
	
	var err = DirAccess.rename_absolute(injectorPath, deletemePath)
	if err != OK:
		Main.StatusLabel.text = "Failed to move moad loader, error " + str(err)
		get_tree().create_timer(2).timeout.connect(Main.launchOrShowConfig)
		return
	
	var f = FileAccess.open(injectorPath, FileAccess.WRITE)
	if !f:
		DirAccess.rename_absolute(deletemePath, injectorPath)
		Main.StatusLabel.text = "Failed to save mod loader, error " + str(FileAccess.get_open_error())
		get_tree().create_timer(2).timeout.connect(Main.launchOrShowConfig)
		return
	f.store_buffer(body)
	f.close()

	var args = ["--main-pack", "Injector.pck", "--"]
	args.append(OS.get_cmdline_user_args())
	OS.create_process(OS.get_executable_path(), args, false)
	get_tree().quit()
