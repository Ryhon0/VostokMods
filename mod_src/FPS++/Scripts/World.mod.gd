@tool
extends Node3D


var audioLibrary = preload("res://Resources/AudioLibrary.tres")
var audioInstance2D = preload("res://Resources/AudioInstance2D.tscn")
var gameData = preload("res://Resources/GameData.tres")


const waterMaterial = preload("res://Nature/Water/Files/MT_Water.tres")
const iceMaterial = preload("res://Nature/Water/Files/MT_Ice.tres")
const debrisMaterial = preload("res://Nature/Debris/Files/MT_Debris.tres")
const debrisMaterialAA = preload("res://Nature/Debris/Files/MT_Debris_AA.tres")
const foliageMaterial = preload("res://Nature/Foliage/Files/MT_Foliage.tres")
const foliageMaterialAA = preload("res://Nature/Foliage/Files/MT_Foliage_AA.tres")
const branchesMaterial = preload("res://Nature/Trees/Files/MT_Tree_Branches.tres")
const branchesMaterialAA = preload("res://Nature/Trees/Files/MT_Tree_Branches_AA.tres")
const billboardMaterial = preload("res://Nature/Trees/Files/MT_Tree_Billboard.tres")
const billboardMaterialAA = preload("res://Nature/Trees/Files/MT_Tree_Billboard_AA.tres")

@export_group("References")
@export var terrain: Node3D
@export var summerMaterial: Material
@export var winterMaterial: Material

@export_group("Audio")
@export var waterAudio: Array[AudioStreamPlayer3D]

@export_group("Skyboxes")
@export var dawnDarkSky: Material
@export var dawnNeutralSky: Material
@export var dayDarkSky: Material
@export var dayNeutralSky: Material
@export var duskDarkSky: Material
@export var duskNeutralSky: Material
@export var nightDarkSky: Material
@export var nightNeutralSky: Material

@export_group("Seasons")
@export var summer: bool = false:
	set = ExecuteSummer
@export var winter: bool = false:
	set = ExecuteWinter

@export_group("Water")
@export var showWater: bool = false:
	set = ExecuteShowWater
@export var hideWater: bool = false:
	set = ExecuteHideWater

@export_group("Lighting")
@export_subgroup("Tutorial")
@export var tutorial: bool = false:
	set = ExecuteTutorial
@export_subgroup("Shelter")
@export var shelter: bool = false:
	set = ExecuteShelter
@export_subgroup("Neutral")
@export var dawnNeutral: bool = false:
	set = ExecuteDawnNeutral
@export var dayNeutral: bool = false:
	set = ExecuteDayNeutral
@export var duskNeutral: bool = false:
	set = ExecuteDuskNeutral
@export var nightNeutral: bool = false:
	set = ExecuteNightNeutral
@export_subgroup("Dark")
@export var dawnDark: bool = false:
	set = ExecuteDawnDark
@export var dayDark: bool = false:
	set = ExecuteDayDark
@export var duskDark: bool = false:
	set = ExecuteDuskDark
@export var nightDark: bool = false:
	set = ExecuteNightDark

@export_group("Spawners")
@export_subgroup("Master")
@export var spawnAll: bool = false:
	set = ExecuteSpawnAll
@export var clearAll: bool = false:
	set = ExecuteClearAll
@export_subgroup("Rocks")
@export var spawnRocks: bool = false:
	set = ExecuteSpawnRocks
@export var clearRocks: bool = false:
	set = ExecuteClearRocks
@export_subgroup("Stones")
@export var spawnStones: bool = false:
	set = ExecuteSpawnStones
@export var clearStones: bool = false:
	set = ExecuteClearStones
@export_subgroup("Pebbles")
@export var spawnPebbles: bool = false:
	set = ExecuteSpawnPebbles
@export var clearPebbles: bool = false:
	set = ExecuteClearPebbles
@export_subgroup("Logs")
@export var spawnLogs: bool = false:
	set = ExecuteSpawnLogs
@export var clearLogs: bool = false:
	set = ExecuteClearLogs
@export_subgroup("Stumps")
@export var spawnStumps: bool = false:
	set = ExecuteSpawnStumps
@export var clearStumps: bool = false:
	set = ExecuteClearStumps
@export_subgroup("Debris")
@export var spawnDebris: bool = false:
	set = ExecuteSpawnDebris
@export var clearDebris: bool = false:
	set = ExecuteClearDebris
@export_subgroup("Foliage")
@export var spawnFoliage: bool = false:
	set = ExecuteSpawnFoliage
@export var clearFoliage: bool = false:
	set = ExecuteClearFoliage
@export_subgroup("Grass")
@export var spawnGrass: bool = false:
	set = ExecuteSpawnGrass
@export var clearGrass: bool = false:
	set = ExecuteClearGrass
@export_subgroup("Trees")
@export var spawnTrees: bool = false:
	set = ExecuteSpawnTrees
@export var clearTrees: bool = false:
	set = ExecuteClearTrees

@export_group("Settings")
@export_subgroup("Rendering")
@export var RStandard: bool = false:
	set = ExecuteStandardRendering
@export var RPerformance: bool = false:
	set = ExecutePerformanceRendering
@export_subgroup("Lighting")
@export var LStandard: bool = false:
	set = ExecuteStandardLighting
@export var LPerformance: bool = false:
	set = ExecutePerformanceLighting


@onready var rocks = $"../Content/Spawners/Rocks"
@onready var stones = $"../Content/Spawners/Stones"
@onready var pebbles = $"../Content/Spawners/Pebbles"
@onready var logs = $"../Content/Spawners/Logs"
@onready var stumps = $"../Content/Spawners/Stumps"
@onready var debris = $"../Content/Spawners/Debris"
@onready var foliage = $"../Content/Spawners/Foliage"
@onready var grass = $"../Content/Spawners/Grass"
@onready var trees = $"../Content/Spawners/Trees"


@onready var environment = $Environment
@onready var sun = $Sun
@onready var water = $Water


@onready var ambient = $Audio / Ambient
@onready var wind = $Audio / Wind
@onready var thunder = $Audio / Thunder


@onready var aurora = $VFX / Aurora
@onready var rain = $VFX / Rain
@onready var storm = $VFX / Storm
@onready var snow = $VFX / Snow
@onready var blizzard = $VFX / Blizzard

func ExecuteSummer(value: bool)->void :
	RenderingServer.global_shader_parameter_set("Winter", false)

	if terrain:
		terrain.get_child(0).set_surface_override_material(0, summerMaterial)

	if water.visible:
		water.material = waterMaterial


	if !Engine.is_editor_hint() && water.visible && gameData.flycam:
		water.use_collision = true
	else :
		water.use_collision = false

	for audio in waterAudio:
		audio.play()

	grass.show()
	foliage.show()
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	summer = false

func ExecuteWinter(value: bool)->void :
	RenderingServer.global_shader_parameter_set("Winter", true)

	if terrain:
		terrain.get_child(0).set_surface_override_material(0, winterMaterial)

	if water.visible:
		water.material = iceMaterial
		water.use_collision = true

	for audio in waterAudio:
		audio.stop()

	grass.hide()
	foliage.hide()
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	winter = false



func ExecuteShowWater(value: bool)->void :
	water.show()
	UpdateProbes()
	showWater = false

func ExecuteHideWater(value: bool)->void :
	water.hide()
	UpdateProbes()
	hideWater = false



func ExecuteTutorial(value: bool)->void :
	environment.environment.sky.sky_material = dayDarkSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(0, 0, 0)
	environment.environment.ambient_light_sky_contribution = 1.0
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_density = 0.01
	environment.environment.volumetric_fog_albedo = Color8(0, 0, 0)
	environment.environment.volumetric_fog_emission = Color8(200, 200, 200)
	environment.environment.volumetric_fog_emission_energy = 0.2
	environment.environment.volumetric_fog_anisotropy = 0.0
	environment.environment.volumetric_fog_enabled = true

	sun.hide()
	UpdateProbes()
	tutorial = false

func ExecuteShelter(value: bool)->void :
	environment.environment.sky.sky_material = dayDarkSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(0, 0, 0)
	environment.environment.ambient_light_sky_contribution = 0.1
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_enabled = false

	sun.hide()
	UpdateProbes()
	shelter = false

func ExecuteDawnDark(value: bool)->void :
	environment.environment.sky.sky_material = dawnDarkSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(0, 0, 0)
	environment.environment.ambient_light_sky_contribution = 0.5
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_density = 0.02
	environment.environment.volumetric_fog_albedo = Color8(0, 0, 0)
	environment.environment.volumetric_fog_emission = Color8(180, 210, 240)
	environment.environment.volumetric_fog_emission_energy = 0.1
	environment.environment.volumetric_fog_anisotropy = 0.9
	environment.environment.volumetric_fog_enabled = true

	sun.show()
	sun.light_energy = 0.25
	sun.shadow_opacity = 1.0
	sun.light_color = Color8(255, 255, 255)
	sun.rotation_degrees = Vector3(-25, 45, 0)

	UpdateProbes()
	dawnDark = false

func ExecuteDawnNeutral(value: bool)->void :
	environment.environment.sky.sky_material = dawnNeutralSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(0, 0, 0)
	environment.environment.ambient_light_sky_contribution = 0.5
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_density = 0.01
	environment.environment.volumetric_fog_albedo = Color8(120, 80, 40)
	environment.environment.volumetric_fog_emission = Color8(180, 195, 220)
	environment.environment.volumetric_fog_emission_energy = 0.2
	environment.environment.volumetric_fog_anisotropy = 0.9
	environment.environment.volumetric_fog_enabled = true

	sun.show()
	sun.light_energy = 1.0
	sun.shadow_opacity = 1.0
	sun.light_color = Color8(200, 180, 180)
	sun.rotation_degrees = Vector3(-25, 45, 0)

	UpdateProbes()
	dawnNeutral = false

func ExecuteDayNeutral(value: bool)->void :
	environment.environment.sky.sky_material = dayNeutralSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(0, 0, 0)
	environment.environment.ambient_light_sky_contribution = 0.5
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_density = 0.01
	environment.environment.volumetric_fog_albedo = Color8(150, 120, 80)
	environment.environment.volumetric_fog_emission = Color8(200, 220, 240)
	environment.environment.volumetric_fog_emission_energy = 0.2
	environment.environment.volumetric_fog_anisotropy = 0.9
	environment.environment.volumetric_fog_enabled = true

	sun.show()
	sun.light_energy = 1.0
	sun.shadow_opacity = 1.0
	sun.light_color = Color8(255, 255, 255)
	sun.rotation_degrees = Vector3(-45, -45, 0)

	UpdateProbes()
	dayNeutral = false

func ExecuteDayDark(value: bool)->void :
	environment.environment.sky.sky_material = dayDarkSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(0, 0, 0)
	environment.environment.ambient_light_sky_contribution = 0.5
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_density = 0.02
	environment.environment.volumetric_fog_albedo = Color8(0, 0, 0)
	environment.environment.volumetric_fog_emission = Color8(200, 210, 220)
	environment.environment.volumetric_fog_emission_energy = 0.1
	environment.environment.volumetric_fog_anisotropy = 0.9
	environment.environment.volumetric_fog_enabled = true

	sun.show()
	sun.light_energy = 0.25
	sun.shadow_opacity = 1.0
	sun.light_color = Color8(255, 255, 255)
	sun.rotation_degrees = Vector3(-45, -45, 0)

	UpdateProbes()
	dayDark = false

func ExecuteDuskNeutral(value: bool)->void :
	environment.environment.sky.sky_material = duskNeutralSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(0, 0, 0)
	environment.environment.ambient_light_sky_contribution = 0.5
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_density = 0.01
	environment.environment.volumetric_fog_albedo = Color8(120, 80, 40)
	environment.environment.volumetric_fog_emission = Color8(200, 180, 160)
	environment.environment.volumetric_fog_emission_energy = 0.2
	environment.environment.volumetric_fog_anisotropy = 0.9
	environment.environment.volumetric_fog_enabled = true

	sun.show()
	sun.light_energy = 1.0
	sun.shadow_opacity = 1.0
	sun.light_color = Color8(220, 200, 190)
	sun.rotation_degrees = Vector3(-25, -45, 0)

	UpdateProbes()
	duskNeutral = false

func ExecuteDuskDark(value: bool)->void :
	environment.environment.sky.sky_material = duskDarkSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(0, 0, 0)
	environment.environment.ambient_light_sky_contribution = 0.5
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_density = 0.02
	environment.environment.volumetric_fog_albedo = Color8(0, 0, 0)
	environment.environment.volumetric_fog_emission = Color8(200, 180, 160)
	environment.environment.volumetric_fog_emission_energy = 0.1
	environment.environment.volumetric_fog_anisotropy = 0.9
	environment.environment.volumetric_fog_enabled = true

	sun.show()
	sun.light_energy = 0.25
	sun.shadow_opacity = 1.0
	sun.light_color = Color8(220, 200, 180)
	sun.rotation_degrees = Vector3(-25, -45, 0)

	UpdateProbes()
	duskDark = false

func ExecuteNightNeutral(value: bool)->void :
	environment.environment.sky.sky_material = nightNeutralSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(60, 70, 90)
	environment.environment.ambient_light_sky_contribution = 0.5
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_density = 0.01
	environment.environment.volumetric_fog_albedo = Color8(0, 0, 0)
	environment.environment.volumetric_fog_emission = Color8(50, 50, 50)
	environment.environment.volumetric_fog_emission_energy = 0.2
	environment.environment.volumetric_fog_anisotropy = 0.0
	environment.environment.volumetric_fog_enabled = true

	sun.show()
	sun.light_energy = 1.0
	sun.shadow_opacity = 1.0
	sun.light_color = Color8(70, 80, 90)
	sun.rotation_degrees = Vector3(-45, 120, 0)

	UpdateProbes()
	nightNeutral = false

func ExecuteNightDark(value: bool)->void :
	environment.environment.sky.sky_material = nightDarkSky
	environment.environment.sky_rotation = Vector3(0, 0, 0)
	environment.environment.ambient_light_color = Color8(60, 70, 90)
	environment.environment.ambient_light_sky_contribution = 0.5
	environment.environment.ambient_light_energy = 1.0
	environment.environment.volumetric_fog_density = 0.02
	environment.environment.volumetric_fog_albedo = Color8(0, 0, 0)
	environment.environment.volumetric_fog_emission = Color8(50, 50, 50)
	environment.environment.volumetric_fog_emission_energy = 0.1
	environment.environment.volumetric_fog_anisotropy = 0.0
	environment.environment.volumetric_fog_enabled = true

	sun.show()
	sun.light_energy = 0.5
	sun.shadow_opacity = 1.0
	sun.light_color = Color8(70, 80, 90)
	sun.rotation_degrees = Vector3(-45, 120, 0)

	UpdateProbes()
	nightDark = false



func ExecuteSpawnAll(value: bool)->void :
	clearAll = true
	await get_tree().create_timer(0.1).timeout;
	rocks.generate = true
	await get_tree().create_timer(0.1).timeout;
	stones.generate = true
	await get_tree().create_timer(0.1).timeout;
	pebbles.generate = true
	await get_tree().create_timer(0.1).timeout;
	logs.generate = true
	await get_tree().create_timer(0.1).timeout;
	stumps.generate = true
	await get_tree().create_timer(0.1).timeout;
	debris.generate = true
	await get_tree().create_timer(0.1).timeout;
	foliage.generate = true
	await get_tree().create_timer(0.1).timeout;
	grass.generate = true
	await get_tree().create_timer(0.1).timeout;
	trees.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnAll = false

func ExecuteClearAll(value: bool)->void :
	rocks.clear = true
	stones.clear = true
	pebbles.clear = true
	logs.clear = true
	stumps.clear = true
	debris.clear = true
	foliage.clear = true
	grass.clear = true
	trees.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearAll = false

func ExecuteSpawnRocks(value: bool)->void :
	rocks.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnRocks = false

func ExecuteClearRocks(value: bool)->void :
	rocks.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearRocks = false

func ExecuteSpawnStones(value: bool)->void :
	stones.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnStones = false

func ExecuteClearStones(value: bool)->void :
	stones.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearStones = false

func ExecuteSpawnPebbles(value: bool)->void :
	pebbles.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnPebbles = false

func ExecuteClearPebbles(value: bool)->void :
	pebbles.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearPebbles = false

func ExecuteSpawnLogs(value: bool)->void :
	logs.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnLogs = false

func ExecuteClearLogs(value: bool)->void :
	logs.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearLogs = false

func ExecuteSpawnStumps(value: bool)->void :
	stumps.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnStumps = false

func ExecuteClearStumps(value: bool)->void :
	stumps.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearStumps = false

func ExecuteSpawnDebris(value: bool)->void :
	debris.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnDebris = false

func ExecuteClearDebris(value: bool)->void :
	debris.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearDebris = false

func ExecuteSpawnFoliage(value: bool)->void :
	foliage.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnFoliage = false

func ExecuteClearFoliage(value: bool)->void :
	foliage.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearFoliage = false

func ExecuteSpawnGrass(value: bool)->void :
	grass.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnGrass = false

func ExecuteClearGrass(value: bool)->void :
	grass.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearGrass = false

func ExecuteSpawnTrees(value: bool)->void :
	trees.generate = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	spawnTrees = false

func ExecuteClearTrees(value: bool)->void :
	trees.clear = true
	await get_tree().create_timer(0.1).timeout;
	UpdateProbes()
	clearTrees = false

func UpdateProbes()->void :
	var probes = get_tree().get_nodes_in_group("Probe")

	for probe in probes:
		probe.interior = true
		probe.interior = false



func ExecuteStandardRendering(value: bool)->void :
	get_tree().get_root().msaa_3d = Viewport.MSAA_4X

	RenderingServer.directional_shadow_atlas_set_size(4096, true)
	sun.directional_shadow_max_distance = 200

	for element in debris.get_children():
		element.set_surface_override_material(0, debrisMaterialAA)

	for element in grass.get_children():
		element.set_surface_override_material(0, foliageMaterialAA)

	for element in trees.get_children():
		element.get_child(0).set_surface_override_material(0, branchesMaterialAA)
		element.get_child(1).set_surface_override_material(0, billboardMaterialAA)



	RStandard = false

func ExecutePerformanceRendering(value: bool)->void :
	get_tree().get_root().msaa_3d = Viewport.MSAA_DISABLED

	RenderingServer.directional_shadow_atlas_set_size(2048, true)
	sun.directional_shadow_max_distance = 100

	for element in debris.get_children():
		element.set_surface_override_material(0, debrisMaterial)

	for element in grass.get_children():
		element.set_surface_override_material(0, foliageMaterial)

	for element in trees.get_children():
		element.get_child(0).set_surface_override_material(0, branchesMaterial)
		element.get_child(1).set_surface_override_material(0, billboardMaterial)

	RPerformance = false

func ExecuteStandardLighting(value: bool)->void :
	environment.environment.ssao_enabled = true
	environment.environment.ssil_enabled = true

	LStandard = false

func ExecutePerformanceLighting(value: bool)->void :
	environment.environment.ssao_enabled = false
	environment.environment.ssil_enabled = false

	LPerformance = false



func UpdateAmbientSFX():
	ambient.stop()
	wind.stop()
	thunder.stop()

	if gameData.season == 1:


		if gameData.weather == 1:
			if gameData.TOD == 1:
				PlayAmbientDawn()
			elif gameData.TOD == 2:
				PlayAmbientDay()
			elif gameData.TOD == 3:
				PlayAmbientDusk()
			elif gameData.TOD == 4:
				PlayAmbientNight()


		elif gameData.weather == 2:
			if gameData.TOD == 1:
				PlayWindMedium()
			elif gameData.TOD == 2:
				PlayWindMedium()
			elif gameData.TOD == 3:
				PlayWindMedium()
			elif gameData.TOD == 4:
				PlayWindMedium()


		elif gameData.weather == 3:
			if gameData.TOD == 1:
				PlayRainLight()
				PlayWindMedium()
			elif gameData.TOD == 2:
				PlayRainLight()
				PlayWindMedium()
			elif gameData.TOD == 3:
				PlayRainLight()
				PlayWindMedium()
			elif gameData.TOD == 4:
				PlayRainLight()
				PlayWindMedium()


		elif gameData.weather == 4:
			if gameData.TOD == 1:
				PlayRainLight()
				PlayWindHeavy()
				PlayThunderHum()
			elif gameData.TOD == 2:
				PlayRainLight()
				PlayWindHeavy()
				PlayThunderHum()
			elif gameData.TOD == 3:
				PlayRainLight()
				PlayWindHeavy()
				PlayThunderHum()
			elif gameData.TOD == 4:
				PlayRainLight()
				PlayWindHeavy()
				PlayThunderHum()

	elif gameData.season == 2:


		if gameData.weather == 1:
			if gameData.TOD == 1:
				PlayWindMedium()
			elif gameData.TOD == 2:
				PlayWindMedium()
			elif gameData.TOD == 3:
				PlayWindMedium()
			elif gameData.TOD == 4:
				PlayWindMedium()


		elif gameData.weather == 2:
			if gameData.TOD == 1:
				PlayWindMedium()
			elif gameData.TOD == 2:
				PlayWindMedium()
			elif gameData.TOD == 3:
				PlayWindMedium()
			elif gameData.TOD == 4:
				PlayWindMedium()


		elif gameData.weather == 3:
			if gameData.TOD == 1:
				PlayWindMedium()
			elif gameData.TOD == 2:
				PlayWindMedium()
			elif gameData.TOD == 3:
				PlayWindMedium()
			elif gameData.TOD == 4:
				PlayWindMedium()


		elif gameData.weather == 4:
			if gameData.TOD == 1:
				PlayWindHowl()
			elif gameData.TOD == 2:
				PlayWindHowl()
			elif gameData.TOD == 3:
				PlayWindHowl()
			elif gameData.TOD == 4:
				PlayWindHowl()

func PlayAmbientDawn():
	var randomIndex: int = randi_range(0, audioLibrary.ambientDawn.audioClips.size() - 1)
	ambient.stream = audioLibrary.ambientDawn.audioClips[randomIndex]
	ambient.volume_db = randf_range(audioLibrary.ambientDawn.minVolume, audioLibrary.ambientDawn.maxVolume)
	ambient.pitch_scale = randf_range(audioLibrary.ambientDawn.minPitch, audioLibrary.ambientDawn.maxPitch)
	ambient.play()

func PlayAmbientDay():
	var randomIndex: int = randi_range(0, audioLibrary.ambientDay.audioClips.size() - 1)
	ambient.stream = audioLibrary.ambientDay.audioClips[randomIndex]
	ambient.volume_db = randf_range(audioLibrary.ambientDay.minVolume, audioLibrary.ambientDay.maxVolume)
	ambient.pitch_scale = randf_range(audioLibrary.ambientDay.minPitch, audioLibrary.ambientDay.maxPitch)
	ambient.play()

func PlayAmbientDusk():
	var randomIndex: int = randi_range(0, audioLibrary.ambientDusk.audioClips.size() - 1)
	ambient.stream = audioLibrary.ambientDusk.audioClips[randomIndex]
	ambient.volume_db = randf_range(audioLibrary.ambientDusk.minVolume, audioLibrary.ambientDusk.maxVolume)
	ambient.pitch_scale = randf_range(audioLibrary.ambientDusk.minPitch, audioLibrary.ambientDusk.maxPitch)
	ambient.play()

func PlayAmbientNight():
	var randomIndex: int = randi_range(0, audioLibrary.ambientNight.audioClips.size() - 1)
	ambient.stream = audioLibrary.ambientNight.audioClips[randomIndex]
	ambient.volume_db = randf_range(audioLibrary.ambientNight.minVolume, audioLibrary.ambientNight.maxVolume)
	ambient.pitch_scale = randf_range(audioLibrary.ambientNight.minPitch, audioLibrary.ambientNight.maxPitch)
	ambient.play()

func PlayWindLight():
	var randomIndex: int = randi_range(0, audioLibrary.windLight.audioClips.size() - 1)
	wind.stream = audioLibrary.windLight.audioClips[randomIndex]
	wind.volume_db = randf_range(audioLibrary.windLight.minVolume, audioLibrary.windLight.maxVolume)
	wind.pitch_scale = randf_range(audioLibrary.windLight.minPitch, audioLibrary.windLight.maxPitch)
	wind.play()

func PlayWindMedium():
	var randomIndex: int = randi_range(0, audioLibrary.windMedium.audioClips.size() - 1)
	wind.stream = audioLibrary.windMedium.audioClips[randomIndex]
	wind.volume_db = randf_range(audioLibrary.windMedium.minVolume, audioLibrary.windMedium.maxVolume)
	wind.pitch_scale = randf_range(audioLibrary.windMedium.minPitch, audioLibrary.windMedium.maxPitch)
	wind.play()

func PlayWindHeavy():
	var randomIndex: int = randi_range(0, audioLibrary.windHeavy.audioClips.size() - 1)
	wind.stream = audioLibrary.windHeavy.audioClips[randomIndex]
	wind.volume_db = randf_range(audioLibrary.windHeavy.minVolume, audioLibrary.windHeavy.maxVolume)
	wind.pitch_scale = randf_range(audioLibrary.windHeavy.minPitch, audioLibrary.windHeavy.maxPitch)
	wind.play()

func PlayWindHowl():
	var randomIndex: int = randi_range(0, audioLibrary.windHowl.audioClips.size() - 1)
	wind.stream = audioLibrary.windHowl.audioClips[randomIndex]
	wind.volume_db = randf_range(audioLibrary.windHowl.minVolume, audioLibrary.windHowl.maxVolume)
	wind.pitch_scale = randf_range(audioLibrary.windHowl.minPitch, audioLibrary.windHowl.maxPitch)
	wind.play()

func PlayRainLight():
	var randomIndex: int = randi_range(0, audioLibrary.rainLight.audioClips.size() - 1)
	ambient.stream = audioLibrary.rainLight.audioClips[randomIndex]
	ambient.volume_db = randf_range(audioLibrary.rainLight.minVolume, audioLibrary.rainLight.maxVolume)
	ambient.pitch_scale = randf_range(audioLibrary.rainLight.minPitch, audioLibrary.rainLight.maxPitch)
	ambient.play()

func PlayRainHeavy():
	var randomIndex: int = randi_range(0, audioLibrary.rainHeavy.audioClips.size() - 1)
	ambient.stream = audioLibrary.rainHeavy.audioClips[randomIndex]
	ambient.volume_db = randf_range(audioLibrary.rainHeavy.minVolume, audioLibrary.rainHeavy.maxVolume)
	ambient.pitch_scale = randf_range(audioLibrary.rainHeavy.minPitch, audioLibrary.rainHeavy.maxPitch)
	ambient.play()

func PlayThunderHum():
	var randomIndex: int = randi_range(0, audioLibrary.thunderHum.audioClips.size() - 1)
	thunder.stream = audioLibrary.thunderHum.audioClips[randomIndex]
	thunder.volume_db = randf_range(audioLibrary.thunderHum.minVolume, audioLibrary.thunderHum.maxVolume)
	thunder.pitch_scale = randf_range(audioLibrary.thunderHum.minPitch, audioLibrary.thunderHum.maxPitch)
	thunder.play()

func PlayThunderStrike():
	var thunderStrike = audioInstance2D.instantiate()
	add_child(thunderStrike)
	thunderStrike.PlayInstance(audioLibrary.thunderStrike)



func ResetVFX():
	rain.hide()
	storm.hide()
	snow.hide()
	blizzard.hide()
	aurora.hide()
	RenderingServer.global_shader_parameter_set("Storm", false)

func Rain():
	rain.show()

func Storm():
	storm.show()
	RenderingServer.global_shader_parameter_set("Storm", true)

func Snow():
	snow.show()

func Blizzard():
	blizzard.show()

func Aurora():
	aurora.show()
