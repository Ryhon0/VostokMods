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
[Moved to the wiki](https://github.com/Ryhon0/VostokMods/wiki)

## Sample mods
A few sample mods are contained in the `sample_mods` directory
