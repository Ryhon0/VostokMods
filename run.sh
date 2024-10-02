#!/bin/bash
set -e

LOADER_VERSION=1
INSTALLED_LOADER=0
if [ -f .LOADERVER ]; then
	INSTALLED_LOADER=$(cat .LOADERVER) 
fi

PCK="Public_Demo_2_v2.pck"

if [ $LOADER_VERSION -ne $INSTALLED_LOADER ]; then
	echo Expected loader version $LOADER_VERSION, got $INSTALLED_LOADER, installing...

	echo Creating PCK backup...
	if [ -f "$PCK.bak" ]; then
		cp "$PCK.bak" "$PCK"
	else
		cp "$PCK" "$PCK.bak"
	fi
	echo Done

	echo Adding mod loader...
	./godotpcktool "$PCK" --action add ModLoader.gd
	echo $LOADER_VERSION > .LOADERVER
	echo Done
fi

echo Building mods...
GAME_DIR=$(pwd)
for mod in mod_src/*
do
	cd "$GAME_DIR/$mod"
	mod="$(basename "$mod")"
	echo Building $mod...
	rm -f "../../mods/$mod.zip"
	zip -r "../../mods/$mod.zip" *
done
cd "$GAME_DIR"
echo Done

echo Running game
./Public_Demo_2_v2.exe --main-pack "$PCK" -s res://ModLoader.gd | tee latest.log