# Vostok Mods
This is an experimental mod loader for Road to Vostok.  
RTV doesn't natively support mods, so we need to inject a script that loads other PCKs and runs other scripts.  
The mod loader can be injected using one of the 2 options:  
* **(Currently used)** Modifying the `user://Preferences.tres` save file to reference a subresource script.  
* **(Not implemented)** Injecting a custom main loop using [GodotPckTool](https://github.com/hhyyrylainen/GodotPckTool)   and running it with `--script`  

Mod PCKs (or ZIPs) will overwrite existing game files at runtime. Partial patches are not supported.  

## Installation
This mod loader isn't designed to be installed by end-users yet.  
For developers, clone the repo, export a PCK for the Injector Godot project, move it to the root of the game installation and run the game executable with `--main-pack (path to Injector.pck)`. You need to run the game at least once for the mod loader to work.  

## Creating mods
Download [GodotPckTool](https://github.com/hhyyrylainen/GodotPckTool) to extract the game PCK.  
All the extracted resources will be in a binary form, you can use [Godot RE Tools](https://github.com/bruvzg/gdsdecomp) to convert them back to usable formats.  
Decompiling the GDScript scripts requires [v0.7.0-prerelease.1](https://github.com/bruvzg/gdsdecomp/releases/tag/v0.7.0-prerelease.1) or newer.  
To create a mod, create a new folder with a file called `mod.txt` and fill it out with information.  
`mod.txt` uses the [ConfigFile](https://docs.godotengine.org/en/stable/classes/class_configfile.html) format and requires the following fields:
```
[mod]
name="Human-readable mod name"
id="internal-mod-id"
version="0.0.1"
```
To modify a script or asset, extract it and decompile it.  
If a script has a `class_name`, it needs to be removed.  
Files must be in the same relative directory to your mod folder as in the PCK (e.g. `res://Scripts/Character.gd` -> `mod_src/MyMod/Character.gd`).  
To run the mod, ZIP the contents of your mod so that mod.txt is in the root of the ZIP and put it in the `mods` folder next to the game executable.

### .remap files
This process may be automated in the future by the build script.  

A lot of assets will have a `.remap` file, which acts like a symlink. `.remap` files have the following format:
```
[remap]
path="res://path/to/target.file"
```
Mod PCKs can overwrite the `.remap` files. For example, if you want to overwrite the `res://Scripts/Character.gd` file (which is remapped to `res://Scripts/Character.gdc`), you need to create a `Scripts/Character.gd.remap` file, which remaps to another file, e.g. `Scripts/Character.mod.gd`.  

## Sample mods
These mods are included in the `sample_mods` directory
### FPS++
Disables 4xMSAA in performance mode, FSR 2.2 is enabled and resolution scale can be adjusted with up/down arrow keys.  
## SimpleControls
Simplifies the controls.  
Weapon is always ready when not sprinting, arm stamina is only consumed while aiming.  Bolt- and pump- action weapons automatically chamber next round and reload automatically with a single reload button press.