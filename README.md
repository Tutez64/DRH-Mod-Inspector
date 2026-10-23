# Inspector

A mod for [Dungeon Rampage Haxe](https://github.com/Tutez64/Dungeon-Rampage-Haxe) modders: it shows what the game runs, to find what a mod can build on.

<!-- drh:show -->
For modders: shows, as they happen, the game's states, its objects, the fields the server sends and what the last actor under the cursor holds, to see what a mod can build on. F7 pins that actor, F8 shows or hides the panel, F9 freezes it, F10 saves it to a file in the mod's data folder.
<!-- /drh:show -->

## How it works

It listens through `context.core` to the core's events (game objects ready and gone, fields the server sends, by the name the game's generated code gives them, state changes) and to the game's own event bus for the actor under the cursor, whose fields and properties it reads by reflection. It draws its panel on the overlay, and writes it with `context.data`.
