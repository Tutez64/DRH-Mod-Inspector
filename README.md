# Inspector

A mod for [Dungeon Rampage Haxe](https://github.com/Tutez64/Dungeon-Rampage-Haxe) modders: it shows what the game runs, to find what a mod can build on.

<!-- drh:show -->
For modders: shows, as they happen, the game's states, its objects, the actor under the cursor and the fields the server sends, to see what a mod can build on. F8 shows or hides it.
<!-- /drh:show -->

## How it works

It listens through `context.core` to the core's events (game objects ready and gone, fields the server sends, state changes) and to the game's own event bus for the actor under the cursor, and draws its panel on the overlay.
