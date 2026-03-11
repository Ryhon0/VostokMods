# Vostok Mods
This is an unofficial mod loader for [Road to Vostok](https://roadtovostok.com/).  
This project only loads assets and code into the game, it does not provide any APIs to interface with the game.  
Mod developers are expected to use Godot's built-in systems to create mods. To interface with the game's code, decompile the game and interact with the scripts like in a regular script.  

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
