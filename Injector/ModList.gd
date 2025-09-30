extends ScrollContainer
class_name ModList

@export var Main: Control
@export var List: Tree

@export var PinIcon: Texture2D
@export var PinIconDisabled: Texture2D

@export var ModWorkshopLogo: Texture2D

var mods : Array[ModInfo] = []

class ModInfo:
	# Name of the mod file without the X- priority prefix and .zip/.zip.disabled extension
	var name : String

	var priority : int
	var disabled : bool
	var versionPinned : bool

	var config : ConfigFile

	func makeDisabled(disable: bool):
		if disabled == disable: return
		var from = getPath()
		var oldState = disabled
		disabled = disable
		var to = getPath()

		var err = DirAccess.rename_absolute(from, to)
		if err != OK:
			OS.alert("Could not move file " + from + " to " + to + ". Error " + err)
			disabled = oldState
			return
	
	func pinVersion(pin: bool):
		var main = Engine.get_main_loop().root.get_node("Main")
		var dontUpdateFile = main.getModsDir().path_join(name + ".dontupdate")
		if !pin:
			var err = DirAccess.remove_absolute(dontUpdateFile)
			if err != OK:
				OS.alert("Could remove file " + dontUpdateFile + "\nError " + err)
				return
			versionPinned = pin
		else:
			var f = FileAccess.open(dontUpdateFile, FileAccess.ModeFlags.WRITE)
			var err = FileAccess.get_open_error()

			if err != OK:
				OS.alert("Failed to create file " + dontUpdateFile + "\nError " + err)
				return

			f.store_string("")
			f.close()

			err = f.get_error()
			if err != OK:
				OS.alert("Failed to save file " + dontUpdateFile + "\nError " + err)
				return

			versionPinned = pin

	func setPriority(newPriority: int):
		if priority == newPriority: return
		var from = getPath()
		var oldState = disabled
		priority = newPriority
		var to = getPath()

		var err = DirAccess.rename_absolute(from, to)
		if err != OK:
			OS.alert("Could not move file " + from + " to " + to + ". Error " + err)
			priority = oldState
			return

	func getPath() -> String:
		var main = Engine.get_main_loop().root.get_node("Main")
		var modsDir = main.getModsDir()

		var path = ""
		if priority != 0:
			path += str(priority) + "-"
		
		path += name + ".zip"
		if disabled:
			path += ".disabled"
		return modsDir.path_join(path)

const NAME_COLUMN = 0
const ID_COLUMN = 1
const VERSION_COLUMN = 2
const FILE_COLUMN = 3
const VERSION_COLUMN_BUTTON_PIN = 0

const LINKS_CLOLUMN = 4

const PRIORITY_COLUMN = 5
const ENABLED_COLUMN = 6

func _ready():
	List.set_column_title(NAME_COLUMN, "Name")
	List.set_column_title(ID_COLUMN, "ID")
	List.set_column_title(VERSION_COLUMN, "Version")
	List.set_column_title(3, "File name")
	List.set_column_title(LINKS_CLOLUMN, "Links")
	List.set_column_title(PRIORITY_COLUMN, "Priority")
	List.set_column_title(ENABLED_COLUMN, "Enabled")

	for i in range(List.columns):
		List.set_column_expand(i, false)

	List.set_column_expand(NAME_COLUMN, true)
	List.set_column_custom_minimum_width(ID_COLUMN, 175)
	List.set_column_custom_minimum_width(VERSION_COLUMN, 75)
	List.set_column_custom_minimum_width(FILE_COLUMN, 175)
	List.set_column_custom_minimum_width(LINKS_CLOLUMN, 90)

func loadMods():
	var priorityNameRegex = RegEx.new()
	priorityNameRegex.compile("^\\-?\\d+-")
	mods = []
	var modsdir = Main.getModsDir()

	List.clear()
	List.create_item()

	if !DirAccess.dir_exists_absolute(modsdir):
		DirAccess.make_dir_recursive_absolute(modsdir)
	var da = DirAccess.open(modsdir)
	for f in da.get_files():
		var zipname = f
		var disabled = false
		if f.ends_with(".zip.disabled"):
			zipname = f.substr(0, f.length() - ".zip.disabled".length())
			disabled = true
		elif f.ends_with(".zip"):
			zipname = f.substr(0, f.length() - ".zip".length())
			disabled = false
		else:
			continue
		
		var priorityResult = priorityNameRegex.search(zipname)
		var priority = 0
		if priorityResult != null:
			priority = int(zipname.substr(0,priorityResult.get_end()))
			zipname = zipname.substr(priorityResult.get_end())
			
		var pinned = FileAccess.file_exists(modsdir.path_join(zipname) + ".dontupdate")
		
		var zr = ZIPReader.new()
		if zr.open(modsdir.path_join(f)) != OK:
			continue
		
		if !zr.file_exists("mod.txt"):
			continue
		
		var cfg = ConfigFile.new()
		cfg.parse(zr.read_file("mod.txt").get_string_from_utf8())
		zr.close()

		if !cfg.has_section_key("mod", "name") || !cfg.has_section_key("mod", "id") || !cfg.has_section_key("mod", "version"):
			continue

		var modname = cfg.get_value("mod", "name")
		var modid = cfg.get_value("mod", "id")
		var modver = cfg.get_value("mod", "version")

		var modi = ModInfo.new()
		modi.name = zipname
		modi.priority = priority
		modi.disabled = disabled
		modi.versionPinned = pinned
		modi.config = cfg

		# Fix the priority prefix if needed
		# 01 -> 1
		if modi.getPath() != modsdir.path_join(f):
			print("Fixing priority prefix " + modsdir.path_join(f) + " -> " + modi.getPath())
			var err = DirAccess.rename_absolute(modsdir.path_join(f), modi.getPath())
			if err != OK:
				OS.alert("Failed to fix the priority prefix of " + f + "\nError " + str(err))

		mods.append(modi)

		var li = List.create_item()
		li.set_meta("mod", modi)

		li.set_text(NAME_COLUMN, modname)
		li.set_text(ID_COLUMN, modid)
		li.set_text(VERSION_COLUMN, modver)
		li.set_text(FILE_COLUMN, zipname)

		# Priority
		li.set_text_alignment(PRIORITY_COLUMN, HORIZONTAL_ALIGNMENT_RIGHT)
		li.set_text(PRIORITY_COLUMN, str(priority))
		li.set_editable(PRIORITY_COLUMN, true)

		# Mod disalbed
		li.set_cell_mode(ENABLED_COLUMN, TreeItem.CELL_MODE_CHECK)
		li.set_checked(ENABLED_COLUMN, !disabled)
		li.set_editable(ENABLED_COLUMN, true)

		# Pin version
		li.add_button(VERSION_COLUMN, PinIcon if pinned else PinIconDisabled, VERSION_COLUMN_BUTTON_PIN, false, "Pin version")

		# Links
		var links : Array[String] = []
		if modi.config.has_section_key("updates", "modworkshop"):
			li.add_button(LINKS_CLOLUMN, ModWorkshopLogo, -1, false, "ModWorkshop")
			links.append("https://modworkshop.net/mod/" + str(modi.config.get_value("updates", "modworkshop")))
		li.set_meta("links", links)

func buttonPressed(item: TreeItem, column: int, button: int, mousebtn: int) -> void:
	if column == VERSION_COLUMN && button == VERSION_COLUMN_BUTTON_PIN && mousebtn == MOUSE_BUTTON_LEFT:
		var mod : ModInfo = item.get_meta("mod")
		mod.pinVersion(!mod.versionPinned)
		item.set_button(VERSION_COLUMN, VERSION_COLUMN_BUTTON_PIN, PinIcon if mod.versionPinned else PinIconDisabled)
		return
	if column == LINKS_CLOLUMN && mousebtn == MOUSE_BUTTON_LEFT:
		var links : Array[String] = item.get_meta("links")
		OS.shell_open(links[button])
		return

func itemEdited() -> void:
	var item: TreeItem = List.get_edited()
	var modi: ModInfo = item.get_meta("mod")
	if List.get_edited_column() == ENABLED_COLUMN:
		modi.makeDisabled(!modi.disabled)
		item.set_checked(ENABLED_COLUMN, !modi.disabled)
	elif List.get_edited_column() == PRIORITY_COLUMN:
		var text = item.get_text(PRIORITY_COLUMN)
		if !text.is_valid_int():
			item.set_text(PRIORITY_COLUMN, str(modi.priority))
			return
		modi.setPriority(int(text))
		item.set_text(PRIORITY_COLUMN, str(modi.priority))

func titleClicked(col: int, mouse: int) -> void:
	if mouse != MOUSE_BUTTON_LEFT:
		return
	
	var root = List.get_root()
	var items = root.get_children()
	for i in items:
		root.remove_child(i)
	
	items.sort_custom(func(a: TreeItem, b: TreeItem) -> bool:
		if col == PRIORITY_COLUMN:
			return int(a.get_text(PRIORITY_COLUMN)) > int(b.get_text(PRIORITY_COLUMN))

		if a.get_cell_mode(col) == TreeItem.CELL_MODE_STRING:
			return a.get_text(col).naturalnocasecmp_to(b.get_text(col)) < 0
		
		if a.get_cell_mode(col) == TreeItem.CELL_MODE_CHECK:
			return a.is_checked(col)
		return false)

	for i in items:
		root.add_child(i)
