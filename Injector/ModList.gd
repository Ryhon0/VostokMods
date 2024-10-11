extends ScrollContainer
class_name ModList

@export var Main: Control
@export var List: Tree
var mods : Array[ModInfo] = []

class ModInfo:
	var zipPath : String
	var config : ConfigFile

func _ready():
	List.set_column_title(0, "Name")
	List.set_column_title(1, "ID")
	List.set_column_title(2, "Version")
	List.set_column_title(3, "File name")
	List.set_column_title(4, "Enabled")

	for i in range(List.columns):
		List.set_column_expand(i, false)

	List.set_column_expand(0, true)
	List.set_column_custom_minimum_width(1, 175)
	List.set_column_custom_minimum_width(3, 175)

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
		mods.append(modi)

		var li = List.create_item()
		li.set_meta("filename", zipname)

		li.set_text(0, modname)
		li.set_text(1, modid)
		li.set_text(2, modver)
		li.set_text(3, zipname)
		li.set_cell_mode(List.columns - 1, TreeItem.CELL_MODE_CHECK)
		li.set_checked(List.columns - 1, !disabled)
		li.set_editable(List.columns - 1, true)

func itemEdited() -> void:
	if List.get_edited_column() != List.columns - 1:
		return

	var item: TreeItem = List.get_edited()
	var disabled = item.is_checked(List.columns - 1)
	var file = Main.getModsDir().path_join(item.get_meta("filename"))

	var from = file + ".zip"
	var to = file + ".zip"
	if disabled: from += ".disabled"
	else: to += ".disabled"

			
	if DirAccess.rename_absolute(from, to) != OK:
		OS.alert("Could not move file " + from)

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
