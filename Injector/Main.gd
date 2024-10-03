extends Control

@export var StatusLabel: Label
@export var Progress: ProgressBar

const githubAPIBaseURL = "https://api.github.com/"

@onready var isWindows = OS.get_name() == "Windows"
@onready var pckToolFilename = "godotpcktool.exe" if isWindows else "godotpcktool"
@onready var pckToolPath = getGameDir() + "/" + pckToolFilename;
var pckName = "Public_Demo_2_v2.pck"

func shutdown():
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

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED, 0)

	var useSubScriptInjector = true
	if useSubScriptInjector:
		startSubScriptInjector()
	else: startPCKInjector()

func startSubScriptInjector():
	var p = load("user://Preferences.tres")
	p.set_script(load("res://ModLoader/SubResourceEntryPoint.gd").duplicate())
	p.loaderScript = load("res://ModLoader/ModLoader.gd").duplicate()
	ResourceSaver.save(p, "user://Preferences.tres")

	var pckdir = getGameDir() + "/" + pckName
	if !FileAccess.file_exists(pckdir):
		StatusLabel.text = "PCK doesn't exist " + pckdir
		shutdown()
		return

	var modsDir = getGameDir() + "/mods"
	var args = ["--main-pack", pckdir, "--", "--mods-dir", modsDir]
	args.append(OS.get_cmdline_user_args())
	
	var pid = OS.create_process(OS.get_executable_path(), args, true)
	if pid == -1:
		StatusLabel.text = "Failed to start Road to Vostok"
		shutdown()
		return
	get_tree().quit()

func startPCKInjector():
	if (!FileAccess.file_exists(pckToolPath)):
		StatusLabel.text = "Downloading GodotPCKTool"

		var httpReq = HTTPRequest.new()
		add_child(httpReq)
		var err = httpReq.request(githubAPIBaseURL + "repos/hhyyrylainen/GodotPckTool/releases/latest", ["accept: application/vnd.github+json"])
		if err != OK:
			StatusLabel.text = "Failed to create GodotPCKTool releases request"
			shutdown()
			return

		showHttpProgress(httpReq)
		httpReq.request_completed.connect(pckToolReleasesRequestCompleted)
	else:
		injectLoaderToPCK()

func pckToolReleasesRequestCompleted(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		StatusLabel.text = "Failed to get GodotPCKTool releases"
		shutdown()
		return
	if response_code < 200 || response_code >= 300:
		StatusLabel.text = "Failed to get GodotPCKTool releases (HTTP code " + str(response_code) + ")"
		shutdown()
		return
	
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var tag = json.data.tag_name
	var assets = json.data.assets

	var matchingAssets = assets.filter(func(a): return a.name == pckToolFilename)
	if matchingAssets.size() == 0:
		StatusLabel.text = "Could not find GodotPCKTool release asset " + pckToolFilename
		shutdown()
		return
	
	var asset = matchingAssets[0]

	StatusLabel.text = "Downloading " + pckToolFilename + " " + tag
	var httpReq = HTTPRequest.new()
	add_child(httpReq)
	var err = httpReq.request(asset.browser_download_url)
	if err != OK:
		StatusLabel.text = "Failed to create " + pckToolFilename + " " + tag + " request"
		shutdown()
		return
	
	showHttpProgress(httpReq)
	httpReq.request_completed.connect(pckToolDownloadRequestCompleted)

func pckToolDownloadRequestCompleted(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		StatusLabel.text = "Failed to download GodotPCKTool"
		shutdown()
		return
	if response_code < 200 || response_code >= 300:
		StatusLabel.text = "Failed to download GodotPCKTool (HTTP code " + str(response_code) + ")"
		shutdown()
		return

	print(pckToolPath)
	var fa = FileAccess.open(pckToolPath, FileAccess.WRITE_READ)
	fa.store_buffer(body)

	if !isWindows:
		if OS.execute("chmod", ["+x", pckToolPath]) != 0:
			StatusLabel.text = "Failed to mark " + pckToolPath + " as executable"
			shutdown()
			return
	
	injectLoaderToPCK()
		
func injectLoaderToPCK():
	StatusLabel.text = "Injecting mod loader"
	Progress.value = 0
	Progress.max_value = 1
	Progress.min_value = 0

	StatusLabel.text = "Checking hash"
	var pckPath = getGameDir() + "/" + pckName
	var pckHash = await hashPCK(pckPath)
	if !pckHash:
		StatusLabel.text = "Failed to calculate PCK hash"
		shutdown()
		return
	StatusLabel.text = "Hash = " + pckHash
	# TODO: append scripts, run PCK

func hashPCK(path):
	var CHUNK_SIZE = 33554432
	if not FileAccess.file_exists(path):
		return null
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	var file = FileAccess.open(path, FileAccess.READ)
	# Update the context after reading each chunk.

	Progress.min_value = 0
	Progress.max_value = file.get_length()
	Progress.value = file.get_position()

	while file.get_position() < file.get_length():
		Progress.value = file.get_position()
		Progress.max_value = file.get_length()

		var remaining = file.get_length() - file.get_position()
		ctx.update(file.get_buffer(min(remaining, CHUNK_SIZE)))
		await RenderingServer.frame_pre_draw
	Progress.value = file.get_length()
	
	# Get the computed hash.
	var res = ctx.finish()
	# Print the result as hex string and array.
	return res.hex_encode()
