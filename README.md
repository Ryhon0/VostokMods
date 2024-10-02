# Vostok Mods
This is an experimental mod loader for Road to Vostok.  
RTV doesn't natively support mods, so we need to inject a script that loads other PCKs and runs other scripts.  
The mod loader is injected by appending a script to the game PCK using [GodotPckTool](https://github.com/hhyyrylainen/GodotPckTool) and using the `--script` option.  
Mod PCKs (or ZIPs) will overwrite existing game files at runtime. Partial patches are not supported.  

## Installation
Press the green "Code" button at the top of the page and press "Download ZIP".  
Extract the contents of the installation of your game so that the `mods` directory is in the same folder as the game executable.  
Download [GodotPckTool](https://github.com/hhyyrylainen/GodotPckTool/releases) and put it in your game's directory.  
To run the game with mods, run the `run.sh` script in the game directory. Windows is not supported yet.

## Creating mods
Download [GodotPckTool](https://github.com/hhyyrylainen/GodotPckTool) to extract the game PCK.  
All the extracted resources will be in a binary form, you can use [Godot RE Tools](https://github.com/bruvzg/gdsdecomp) to convert them back to usable formats.  
Decompiling the GDScript scripts requires [v0.7.0-prerelease.1](https://github.com/bruvzg/gdsdecomp/releases/tag/v0.7.0-prerelease.1) or newer.  
To create a mod, create a new folder in the `mod_src` directory.  
To modify a script or asset, extract it and decompile it.  
If a script has a `class_name`, it needs to be removed.  
Files must be in the same relative directory to your mod folder as in the PCK (e.g. `res://Scripts/Character.gd` -> `mod_src/MyMod/Character.gd`).  

### .remap files
This process may be automated in the future by the build script.  

A lot of assets will have a `.remap` file, which acts like a symlink. `.remap` files have the following format:
```
[remap]
path="res://path/to/target.file"
```
Mod PCKs can overwrite the `.remap` files. For example, if you want to overwrite the `res://Scripts/Character.gd` file (which is remapped to `res://Scripts/Character.gdc`), you need to create a `Scripts/Character.gd.remap` file, which remaps to another file, e.g. `Scripts/Character.mod.gd`.  

## Sample mods
These mods are included in the `mod_src` directory
### FPS++
Disables 4xMSAA in performance mode, FSR 2.2 is enabled and resolution scale can be adjusted with up/down arrow keys.  
## SimpleControls
Simplifies the controls.  
Weapon is always ready when not sprinting, arm stamina is only consumed while aiming.  Bolt- and pump- action weapons automatically chamber next round and reload automatically with a single reload button press.