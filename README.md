# Godot Strata Zero

Strata Zero is a __horizontal sidescrolling shooter with some roguelike elements__ to spice things up. This is my first public game, and some of its contents are inspired by tutorials and based on the official Godot documentation, and I'll address every source in each section. The game will also be a part of series of videos made to teach the basics of Godot and present some aspects of development.

This project purpose is to have a great variety of mechanisms and extensively documented info directed for people wanting to learn the foundations of Godot. This game will also be uploaded in __[itch.io](http://itch.io)__ after completion, and will always be *open source*, as there is no better way to learn than to teach.

Some of the features of the game are:

* Loadout menu and inventory
  * Selectable weapons and items to start the game with an specific loadout
  * Unlockable and rare items // WIP
  * Upgrade system // WIP
* Singletons (Autoload)
  * Options
    * Toggleable firing button (Comes on by default)
    * Toggleable screen shake
    * Photosensitivity mode for disabling light flickers
    * Keybinding menu for remapping controls
    * Sound sliders // (although the game doesn't have sounds yet)
  * Profile
    * Simple stage performance register (score, items collected at stage, history, etc.)
    * Saved progress
    * Saved preferences that automatically activate options previously selected in certain menus
  * UI
    * UIOverlay - HUD with HP, ammo, items display, and stage progress bar
    * ScreenTransition - Fade-in and fade-out transition using shader
    * PauseMenu
    * GameOverScreen
* Components
  * HitboxComponent - Recieves data from collision boxes and polygons. Mostly used together with HealthComponent.
  * HealthComponent - Controls the health of all entities of the game, with heal, damage and death functions.
  * DropComponent - Drops items based on the id of the entity that owns it, recieves items from a .JSON file.
  * CombatComponent - Adds targeting system on enemies, debuffs, etc.
* Player character
  * Smooth movement using lerp function
  * Functioning AnimationTree that nicely blends movement animations.
  * Primary fire action - Light weapons like lasers, miniguns, etc. Low damage but fast and limitless.
  * Secondary fire action - Heavy weapons like bombs, guided missiles, etc. They are limited by the use of ammo.
  * Dash action - Quickly accelerates player towards the direction it is moving
  * Roll action - Makes player immune to projectiles for a short period
  * InventoryModule - Has a lot of functionalities, including managing ammo, updating hud, presenting choices from a item drop, etc. Only present on player.
* StageManager
  * ThreatGenerator - Event controller and threat spawner. Highly adaptative functions with optional rules for position, quantity, and other properties of the spawning entity.
  * System works entirely on a script written on a JSON dictionary format, wtih event name, type, period, and other properties defining the aspect of the event.
  * Challenges that stops the stage progress bar and resumes after completion.
* Graphics
  * Pixel art UI and general graphics (Asset pack will be available to download)
  * Cutscenes states and animated sprites
  * [Using a gorgeous pallette called Ressurect64](https://lospec.com/palette-list/resurrect-64)

Planned features are:

* Final goal and game end

After gathering more experience in Godot and overall game design, it is __highly__ probable that I'll redo some aspects of the game in the future on another project or even a sequel. Looking forward to it!
