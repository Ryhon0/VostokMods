# Vostok Mods
This is an experimental mod loader for Road to Vostok.  
RTV doesn't natively support mods, so we need to inject a script that loads other PCKs and runs other scripts.  
The mod loader can be injected using one of the 2 options:  
* **(Currently used)** Modifying the `user://Preferences.tres` save file to reference a subresource script.  
* **(Not implemented)** Injecting a custom main loop using [GodotPckTool](https://github.com/hhyyrylainen/GodotPckTool)   and running it with `--script`  

Mod PCKs (or ZIPs) will overwrite existing game files at runtime. Partial patches are not supported.  

## Installation
* Go to the [releases page](https://github.com/Ryhon0/VostokMods/releases)  
* Download the `Injector.pck` file from the latest release  
* Right click Road to Vostok in your Steam library and select "Manage>Browse local files"
* Move the downloaded file into the folder
* Right click Road to Vostok again and select "Properties..."
* In the "General" tab, set the launch options to `--main-pack Injector.pck`  
* The mod loader is now installed  

To install mods, move the mod .ZIPs into the `mods` folder in the game directory.  

## Creating mods
Download [GodotPckTool](https://github.com/hhyyrylainen/GodotPckTool) to extract the game PCK.  
All the extracted resources will be in a binary form, you can use [Godot RE Tools](https://github.com/bruvzg/gdsdecomp) to convert them back to usable formats.  
Decompiling the GDScript scripts requires [v0.7.0](https://github.com/bruvzg/gdsdecomp/releases/tag/v0.7.0) or newer.  
To create a mod, create a new folder with a file called `mod.txt` and fill it out with information.  
`mod.txt` uses the [ConfigFile](https://docs.godotengine.org/en/stable/classes/class_configfile.html) format and requires the following fields:
```toml
[mod]
name="Human-readable mod name"
id="internal-mod-id"
version="0.0.1"
```
To modify a script or asset, extract it and decompile it.  
If a script has a `class_name`, it needs to be removed.  
Files must be in the same relative directory to your mod folder as in the PCK (e.g. `res://Scripts/Character.gd` -> `mod_src/MyMod/Character.gd`).  
To run the mod, ZIP the contents of your mod so that mod.txt is in the root of the ZIP and put it in the `mods` folder next to the game executable.

### Autoloads
Mod autoloads let you run scripts when the mod is loaded. They can be defined in the `[autoload]` section in `mod.txt`.  
The value of a field must be a path to a script inhereting `Node` or a path to a `PackedScene`. The autoload will be added as a child of `/root/` and it's name will be set to the field key.  
Example autoload section:
```toml
[autoload]
MyModMain="res://MyMod/Main.gd"
```

### Modifying assets
#### Dynamically
This method is prefered for modifying scripts, scenes and custom resources as it allows multiple mods to make changes on a single resource. For textures and audio, the static approach might be better but this approach works too.  
To modify a script, create a script in your mod and extend it using the path to the script you want to modify, instead of it's class name. Then in your mod autoload script, load and compile the script and call `take_over_path()` on your new script with the path of the original script, for example:  
```gd
extends "res://Scripts/Weapon.gd"

func PlayFireAudio():
	base()
	print("Pew!")
```
Autoload script:
```gd
func _ready():
	var script = load("res://MyMod/Weapon.gd")
	script.reload() # compile the script
	var parentScript = script.get_base_script()
	script.take_over_path(parentScript.resource_path)
	queue_free()
```
> [!IMPORTANT]  
> Due to an issue with Godot, scripts can be overriden ONLY ONCE.  
> See [godot#83542](https://github.com/godotengine/godot/issues/83542) and [godot-mod-loader#338](https://github.com/GodotModding/godot-mod-loader/issues/338)  
> We might switch to a hook-based system, which adds PRE and POST function hooks in the future if the issue isn't resolved. ([godot-mod-loader#408](https://github.com/GodotModding/godot-mod-loader/pull/408))

This process also works for any other asset.

#### Statically
You can replace assets by having a file with the same path in your mod as the file you want to replace. A lot of assets will have a `.remap` file, which acts like a symlink. `.remap` files have the following format:
```
[remap]
path="res://path/to/target.file"
```
If you want to replace a file with a `.remap` file, you must create your own `.remap` file, which points to a different path.

## Sample mods
These mods are included in the `sample_mods` directory
### LightlyWeathered
Time, weather and music changes when entering a new zone.  
## SimpleControls
Simplifies the controls.  
Weapon is always ready when not sprinting, arm stamina is only consumed while aiming.  Bolt- and pump- action weapons automatically chamber next round and reload automatically with a single reload button press.