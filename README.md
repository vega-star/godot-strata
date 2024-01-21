# Godot Strata

Strata is a __*experimental* simple horizontal sidescrolling shooter with further roguelike elements__ to spice things up. This is my first public game, and some of its contents are inspired by tutorials and based on the official Godot documentation, and I'll address every source in each section.

Strata's purpose is to have a great variety of mechanisms and extensively documented info directed for people wanting to learn the foundations of Godot. This game will also be uploaded in __[itch.io](http://itch.io)__ after completion, but this version will be always here *and open source*, as there is no better way to learn than to teach.

The working game currently has:

* Option menu
  * Keybinding menu for remapping
  * Sound sliders // (although the game doesn't have sounds yet)
* Modular components
  * Hitbox component
  * Health component
* Player character
  * Smooth movement using lerp function
  * Primary fire action - Light weapons like lasers, miniguns, etc.
  * Secondary fire action - Heavy weapons like bombs, rockets, etc.
  * Dash action
  * Reactive health bar
* Threat manager
  * Spawner controller
  * Simple enemies with collision
* Graphics
  * Fade-in and fade-out transition with shader and scene controller
  * Scalable menus snapped to screen center

Planned features are:

* Toggleable photosensitivy mode
* Roll action

* Roguelike elements and items
* Stages and route map
* Simple inventory management and equipment
* Cutscenes and advanced animation
* Enemies variety and boss fights
* Variety of weapons and maybe starter characters
* Final goal and game end

After completion, this repository will also bear a *__.pdf__* file where each detail, issue, and solution should be registered. After gathering more experience both in Godot and overall game design, it is __highly__ probable that I'll redo some aspects of the game in another project, but I'll also surely document the differences and explain the reason behind them.

The first horizontal slice will already contain a playable game with raw assets and functioning code. It's expected that the code becomes more complex through time and refinement, so the first release will remain as the main branch of this repository. A secondary branch will be created to contain the complete game.
