class_name EquipmentModule extends Node

signal ammo_changed(current_ammo, previous_ammo)

# Placeholder weapons dictionary.
var all_weapons = { 
	"default_laser": {
		"type": 0,
		"projectile_scene": "res://entities/projectiles/default_laser.tscn",
		"base_rate_of_fire": 20
		},
	"default_bomb": {
		"type": 1,
		"projectile_scene": "res://entities/projectiles/default_bomb.tscn",
		"base_rate_of_fire": 5,
		"base_amount": 1,
		"base_regeneration": false
	},
	"default_missile": {
		"type": 1,
		"projectile_scene": "res://entities/projectiles/default_missile.tscn",
		"base_rate_of_fire": 5,
		"base_amount": 3,
		"base_regeneration": true,
		"base_regeneration_cooldown": 5
	}
}

## EquipmentModule reacts to the player inputs and uses equipped guns, ammo, active items, and such.
#
# Not to be confused with InventoryModule, which stores information of all items collected by the player, equipped or not.
#
# Previously, most of these functions were present directly in the player script, which it's not so practical when adding new features.
# Modularization provides the developer with more control and perspective over the gameplay.
#region - Variables
@onready var inventory_module : InventoryModule = $"../InventoryModule"
@onready var projectile_container = $"../../ProjectileContainer"

@export var max_secondary_ammo : int = 8
var secondary_ammo : int

# Equipped items and weapons
var selected_primary : String
var set_primary:
	set(value):
		selected_primary = value
var selected_secondary : String
var set_secondary:
	set(value):
		selected_secondary = value

var base_primary_rof
var base_secondary_rof
var secondary_projectiles_amount : int = 1
var eqquiped_primary_weapon : Dictionary
var eqquiped_secondary_weapon : Dictionary
var primary_weapon_scene : PackedScene
var secondary_weapon_scene : PackedScene

var regenerate_ammo : bool
var ammo_regeneration : bool
var ammo_regeneration_cooldown : float

# Buff variables
@export var regeneration_cooldown_buff : float = 1
var primary_rof_buff : float = 1.0
var secondary_rof_buff : float = 1.0
var secondary_additional_amount : int = 0
#endregion

func _ready():
	owner.fire_primary.connect(_on_player_primary_fired)
	owner.fire_secondary.connect(_on_player_secondary_fired)
	
	secondary_ammo = max_secondary_ammo
	clamp(secondary_ammo, 0, max_secondary_ammo)
	
	update_equipment()

func _process(_delta):
	if regenerate_ammo:
		if !ammo_regeneration:
			ammo_regeneration = true
			await get_tree().create_timer(ammo_regeneration_cooldown, false).timeout
			add_ammo(1)
			ammo_regeneration = false

func update_equipment(): ## Loads equipment properly at the start of the scene. Can be used again after changes in Inventory.
	eqquiped_primary_weapon = all_weapons[selected_primary]
	eqquiped_secondary_weapon = all_weapons[selected_secondary]
	
	base_primary_rof = eqquiped_primary_weapon["base_rate_of_fire"]
	base_secondary_rof = eqquiped_secondary_weapon["base_rate_of_fire"]
	owner.set_primary_rof = base_primary_rof * primary_rof_buff
	owner.set_secondary_rof = base_secondary_rof * secondary_rof_buff
	
	secondary_projectiles_amount = eqquiped_secondary_weapon["base_amount"]
	regenerate_ammo = eqquiped_secondary_weapon["base_regeneration"]
	if regenerate_ammo: ammo_regeneration_cooldown = eqquiped_secondary_weapon["base_regeneration_cooldown"] * regeneration_cooldown_buff
	
	primary_weapon_scene = load(eqquiped_primary_weapon["projectile_scene"])
	secondary_weapon_scene = load(eqquiped_secondary_weapon["projectile_scene"])

func _on_player_primary_fired(start_position):
	var primary_shot = primary_weapon_scene.instantiate()
	primary_shot.global_position = start_position
	projectile_container.add_child(primary_shot)

func _on_player_secondary_fired(reference, _secondary_ammo):
	secondary_ammo -= 1
	ammo_changed.emit(secondary_ammo, secondary_ammo + 1)
	Profile.add_run_data("STATISTICS", "AMMO_CONSUMED", 1)
	
	var interval = (base_secondary_rof * secondary_rof_buff) / 500
	print(interval)
	for amount in secondary_projectiles_amount:
		var secondary_shot = secondary_weapon_scene.instantiate()
		secondary_shot.global_position = reference.global_position
		projectile_container.add_child(secondary_shot)
		if secondary_projectiles_amount > 1: await get_tree().create_timer(interval).timeout

func add_buff(status, buff):
	match status:
		"primary_rof_buff":
			primary_rof_buff *= buff
		"secondary_rof_buff":
			secondary_rof_buff *= buff
		"secondary_additional_amount":
			secondary_additional_amount += buff

func add_ammo(ammo_value):
	if secondary_ammo + ammo_value > max_secondary_ammo: # Cap the value to prevent overflow
		secondary_ammo = max_secondary_ammo
	else:
		secondary_ammo += ammo_value
		Profile.add_run_data("STATISTICS", "AMMO_RECOVERED", ammo_value)
	
	ammo_changed.emit(secondary_ammo, secondary_ammo - 1)
