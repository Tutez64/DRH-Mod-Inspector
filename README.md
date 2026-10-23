# Inspector

A mod for [Dungeon Rampage Haxe](https://github.com/Tutez64/Dungeon-Rampage-Haxe): shows the game's raw values as it runs, from the monsters and props under the cursor to what the server sends.

<!-- drh:show -->
Shows the game's raw values as it runs: those of the last monster or prop under the cursor, the game's states, its objects and what the server sends. Technical and unpolished, for the curious and for modders.

F7 shows or hides the panel, F8 freezes it, F9 pins the monster or prop it shows, F10 saves it to a file in the mod's data folder.
<!-- /drh:show -->

## How it works

It listens through `context.core` to the core's events (game objects ready and gone, fields the server sends, by the name the game's generated code gives them, state changes) and to the game's own event bus for the actor under the cursor, whose fields and properties it reads by reflection. It draws its panel on the overlay, and writes it with `context.data`.
