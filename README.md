# Godot Strata

Prototype game in Godot 4.2+ made to test and learn firsthand how to make scripts, integrate modular composition, and use various nodes. Its purpose is to have a great variety of mechanisms and commented info to reinforce my knowledge in certain aspects and to serve as a foundation for people wanting to learn Godot as well! This game will also be uploaded in [itch.io](itch.io) after completion, but this version will be always here *and open source*.

Strata is a __*experimental* simple horizontal sidescrolling shooter with further roguelike elements__ to spice things up. The game should contain a hierarchy of simple scripts:

* Controllable 2D character
* Moving parallax background, including:
    * Dynamic speed and height
    * Centralized movement script
* Enemies behavior and collision
* Firstly a singular simple stage, then:
    * Both random and planned events
    * Different stages
    * Difficulty progression
* Modular components, such as:
    * Health
    * Hitbox
    * Projectile
    * Item
    * Stage
* Game state controller, with:
    * Pause 
    * Main menu
    * Game over screen
    * Keybinding menu

After completion, this repository will also bear a <kbd>.pdf</kbd> file where each detail, issue, and solution will be registered. After gathering more experience both in Godot and overall game design, it is **highly** probable that I'll redo some aspects of the game, but I'll also surely document the differences and explain the reason behind them.