extends ScrollContainer
class_name ModList

@export var Main: Control
@export var List: Tree

@export var PinIcon: Texture2D
@export var PinIconDisabled: Texture2D

@export var ModWorkshopLogo: Texture2D

var mods : Array[ModInfo] = []

class ModInfo:
	var zipPath : String
	var config : ConfigFile
	var disabled : bool
	var versionPinned : bool

	func makeDisabled(disable: bool):
		var from = zipPath + ".zip"
		var to = zipPath + ".zip"

		if disable: to += ".disabled"
		else: from += ".disabled"

		var err = DirAccess.rename_absolute(from, to)
		if err != OK:
			OS.alert("Could not move file " + from + " to " + to + ". Error " + err)
			return
		
		disabled = disable
	
	func pinVersion(pin: bool):
		if !pin:
			var err = DirAccess.remove_absolute(zipPath + ".dontupdate")
			if err != OK:
				OS.alert("Could remove file " + zipPath + ".dontupdate. Error " + err)
				return
			versionPinned = pin
		else:
			var f = FileAccess.open(zipPath + ".dontupdate", FileAccess.ModeFlags.WRITE)
			var err = FileAccess.get_open_error()

			if err != OK:
				OS.alert("Failed to create file " + zipPath + ".dontupdate. Error " + err)
				return

			f.store_string("")
			f.close()

			err = f.get_error()
			if err != OK:
				OS.alert("Failed to save file " + zipPath + ".dontupdate. Error " + err)
				return

			versionPinned = pin

const VERSION_COLUMN = 2
const VERSION_COLUMN_BUTTON_PIN = 0

const LINKS_CLOLUMN = 4

const ENABLED_COLUMN = 5

func _ready():
	List.set_column_title(0, "Name")
	List.set_column_title(1, "ID")
	List.set_column_title(VERSION_COLUMN, "Version")
	List.set_column_title(3, "File name")
	List.set_column_title(LINKS_CLOLUMN, "Links")
	List.set_column_title(ENABLED_COLUMN, "Enabled")

	for i in range(List.columns):
		List.set_column_expand(i, false)

	List.set_column_expand(0, true)
	List.set_column_custom_minimum_width(1, 175)
	List.set_column_custom_minimum_width(VERSION_COLUMN, 75)
	List.set_column_custom_minimum_width(3, 175)
	List.set_column_custom_minimum_width(LINKS_CLOLUMN, 90)

func loadMods():
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
		modi.config = cfg
		modi.zipPath = modsdir.path_join(zipname)
		modi.disabled = disabled
		modi.versionPinned = pinned
		mods.append(modi)

		var li = List.create_item()
		li.set_meta("mod", modi)

		li.set_text(0, modname)
		li.set_text(1, modid)
		li.set_text(VERSION_COLUMN, modver)
		li.set_text(3, zipname)
		
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
	if List.get_edited_column() == 4:
		var item: TreeItem = List.get_edited()
		var modi: ModInfo = item.get_meta("mod")
		modi.makeDisabled(!modi.disabled)
		item.set_checked(ENABLED_COLUMN, modi.disabled)

func titleClicked(col: int, mouse: int) -> void:
	if mouse != MOUSE_BUTTON_LEFT:
		return
	
	var root = List.get_root()
	var items = root.get_children()
	for i in items:
		root.remove_child(i)
	
	items.sort_custom(func(a: TreeItem, b: TreeItem) -> bool:
		if a.get_cell_mode(col) == TreeItem.CELL_MODE_STRING:
			return a.get_text(col).naturalnocasecmp_to(b.get_text(col)) < 0
		
		if a.get_cell_mode(col) == TreeItem.CELL_MODE_CHECK:
			return a.is_checked(col)
		return false)

	for i in items:
		root.add_child(i)
