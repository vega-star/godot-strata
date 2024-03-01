class_name EquipmentModule extends Node

signal ammo_changed(current_ammo, previous_ammo)
signal buff_activated
signal buff_deactivated(source)

## EquipmentModule reacts to the player inputs and uses equipped guns, ammo, active items, and such.
#
# Previously, most of these functions were present directly in the player script, which it's not so practical when adding new features.
# Modularization provides the developer with more control and perspective over the gameplay.

#region - Variables
## Data variables
const weapons_data_path = "res://data/weapons_data.json"
const items_data_path = "res://data/items_data.json"
var items_dict : Dictionary
var weapons_dict : Dictionary
var eqquiped_primary : Dictionary
var eqquiped_secondary : Dictionary
var primary_weapon_scene : PackedScene
var secondary_weapon_scene : PackedScene
@export var health_component : HealthComponent
@export var inventory_module : InventoryModule
@onready var projectile_container = $"../../ProjectileContainer"
@onready var selection_control = $InventoryUILayer/SelectionControl
@onready var selection_options = $InventoryUILayer/SelectionControl/SelectionOptions

## Equipped items and weapons
var selected_primary : String
var selected_secondary : String
var base_primary_rof
var base_secondary_rof
var secondary_projectiles_amount : int = 1
var regenerate_ammo : bool
var ammo_regeneration : bool
var ammo_regeneration_cooldown : float
var secondary_ammo : int
var max_secondary_ammo : int

## Buff variables
var active_buffs : Dictionary = {}
var regeneration_cooldown_buff : float = 1
var primary_damage_buff : float = 1.0
var primary_rof_buff : float = 1.0
var secondary_damage_buff : float = 1.0
var secondary_rof_buff : float = 1.0
var secondary_additional_amount : int = 0
#endregion

func _ready():
	assert(FileAccess.file_exists(weapons_data_path))
	var load_weapons_data = FileAccess.open(weapons_data_path, FileAccess.READ)
	weapons_dict = JSON.parse_string(load_weapons_data.get_as_text())
	
	assert(FileAccess.file_exists(items_data_path))
	var load_items_data = FileAccess.open(items_data_path, FileAccess.READ)
	items_dict = JSON.parse_string(load_items_data.get_as_text())
	items_dict = items_dict["items"]
	
	owner.fire_primary.connect(_on_player_primary_fired)
	owner.fire_secondary.connect(_on_player_secondary_fired)
	
	update_equipment()
	load_items()
	load_equipment()
	
	present_choice(["AdditionalHardpoint", "PlasteelWing", "ICAmplifier"])

func _process(_delta):
	if regenerate_ammo:
		if !ammo_regeneration:
			ammo_regeneration = true
			await get_tree().create_timer(ammo_regeneration_cooldown, false).timeout
			add_ammo(1)
			ammo_regeneration = false

func update_equipment(set_primary = null, set_secondary = null): ## Loads equipment properly at the start of the scene. Can be used again after changes in Inventory.
	## Set or load primary
	if set_primary: selected_primary = set_primary
	else: selected_primary = Profile.current_run_data.get_value("INVENTORY", "PRIMARY_WEAPON")
	eqquiped_primary = weapons_dict["primary"][selected_primary]
	
	## Set or load secondary
	if set_secondary: selected_secondary = set_secondary
	else: selected_secondary = Profile.current_run_data.get_value("INVENTORY", "SECONDARY_WEAPON")
	eqquiped_secondary = weapons_dict["secondary"][selected_secondary]
	
	## Load base values
	base_primary_rof = eqquiped_primary["base_rate_of_fire"]
	base_secondary_rof = eqquiped_secondary["base_rate_of_fire"]
	secondary_projectiles_amount = eqquiped_secondary["base_amount"]
	regenerate_ammo = eqquiped_secondary["base_regeneration"]
	if regenerate_ammo: ammo_regeneration_cooldown = eqquiped_secondary["base_regeneration_cooldown"] * regeneration_cooldown_buff
	
	primary_weapon_scene = load(eqquiped_primary["projectile_scene"])
	secondary_weapon_scene = load(eqquiped_secondary["projectile_scene"])
	update_player_values()

func load_items():
	for item in Profile.current_run_data.get_value("INVENTORY", "ITEMS_STORED"):
		match items_dict[item]["item_type"]:
			"passive":
				var buff_period = null
				if items_dict[item]["item_properties"]["temporary"]:
					buff_period = items_dict[item]["item_effect"]["period"]
				create_buff(
					items_dict[item]["item_name"],
					items_dict[item]["item_effect"]["target"],
					items_dict[item]["item_effect"]["value"],
					buff_period
				)

func load_equipment():
	max_secondary_ammo = Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO")
	secondary_ammo = max_secondary_ammo

func update_player_values():
	var loaded_bonus_ammo = Profile.current_run_data.get_value("EFFECTS", "BONUS_AMMO")
	var max_ammo = Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO")
	max_secondary_ammo = max_ammo + loaded_bonus_ammo
	health_component.set_max_health = Profile.current_run_data.get_value("INVENTORY", "MAX_HEALTH")
	
	owner.set_primary_rof = base_primary_rof * primary_rof_buff
	owner.set_secondary_rof = base_secondary_rof * secondary_rof_buff
	
	owner.status_change.emit()
	UI.UIOverlay.update_hud()

func reset_buffs():
	primary_damage_buff = 1.0
	primary_rof_buff = 1.0
	secondary_damage_buff = 1.0
	secondary_rof_buff = 1.0
	secondary_additional_amount = 0
	Profile.current_run_data.set_value("EFFECTS", "BONUS_AMMO", 0)
	update_player_values()

## Weapon usage
func _on_player_primary_fired(start_position):
	var primary_shot = primary_weapon_scene.instantiate()
	primary_shot.global_position = start_position
	primary_shot.projectile_damage *= primary_damage_buff
	projectile_container.add_child(primary_shot)

func _on_player_secondary_fired(reference, _secondary_ammo):
	secondary_ammo -= 1
	ammo_changed.emit(secondary_ammo, secondary_ammo + 1)
	Profile.add_run_data("STATISTICS", "AMMO_CONSUMED", 1)
	
	var interval = (base_secondary_rof * secondary_rof_buff) / 30
	for amount in secondary_projectiles_amount:
		var secondary_shot = secondary_weapon_scene.instantiate()
		secondary_shot.global_position = reference.global_position
		projectile_container.add_child(secondary_shot)
		if secondary_projectiles_amount > 1: await get_tree().create_timer(interval).timeout

func add_ammo(ammo_value):
	if secondary_ammo + ammo_value > max_secondary_ammo: # Cap the value to prevent overflow
		secondary_ammo = max_secondary_ammo
	else:
		secondary_ammo += ammo_value
		Profile.add_run_data("STATISTICS", "AMMO_RECOVERED", ammo_value)
	ammo_changed.emit(secondary_ammo, secondary_ammo - 1)

func change_equipment(target_equipment, value):
	match target_equipment:
		0, "selected_primary": selected_primary = value
		1, "selected_secondary": selected_secondary = value
		_: push_error("Invalid equipment type")

func add_buff(status, buff):
	match status:
		"primary_damage_buff":
			primary_damage_buff *= buff
		"primary_rof_buff":
			primary_rof_buff /= buff
		"secondary_rof_buff":
			secondary_rof_buff /= buff
		"secondary_additional_amount":
			var loaded_bonus_ammo = Profile.current_run_data.get_value("EFFECTS", "BONUS_AMMO")
			secondary_additional_amount = loaded_bonus_ammo + buff
			Profile.current_run_data.set_value("EFFECTS", "BONUS_AMMO", secondary_additional_amount)
			update_player_values()
			add_ammo(secondary_additional_amount)
		_:
			print('Buff request received, but status is invalid. No change has been made.')

func create_buff(source, target_status, value, period = null, accumulate : bool = false):
	var temporary : bool = false
	if period: temporary = true
	
	if !accumulate:
		if active_buffs.has(source):
			return
	
	if target_status is Array and value is Array:
		for target in target_status.size():
			var target_index = target - 1
			create_buff(source, target_status[target_index], value[target_index], period)
		return
	
	match target_status:
		0, "primary_damage_buff":
			add_buff("primary_damage_buff", value)
		1, "primary_rof_buff":
			add_buff("primary_rof_buff", value)
		2, "secondary_damage_buff":
			add_buff("secondary_damage_buff", value)
		3, "secondary_rof_buff":
			add_buff("secondary_rof_buff", value)
		4, "secondary_additional_amount":
			add_buff("secondary_additional_amount", value)
		5, "dash_cooldown_factor":
			pass
		6, "dash_speed_buff":
			pass
	
	active_buffs[source] = {
		"buff" = target_status,
		"buff_value" = value,
		"buff_period" = period
	}
	
	update_equipment()
	buff_activated.emit()
	if temporary:
		await get_tree().create_timer(period).timeout
		buff_deactivated.emit(source)

func _on_buff_deactivated(source):
	await reset_buffs()
	load_items()
	active_buffs.erase(source)

## Item Selection
var buttons_available : Array

func present_choice(items):
	UI.set_pause(true)
	
	assert(items is Array)
	for item in items:
		var button_scene = load("res://scenes/selection_button.tscn")
		var button = button_scene.instantiate()
		
		button.set_button_properties(
			item,
			items_dict[item]["item_name"],
			items_dict[item]["item_properties"]["item_icon"],
			items_dict[item]["item_description"],
			items_dict[item]["item_properties"]["item_tier"]
		)
		
		button.selected.connect(choose_item)
		selection_options.call_deferred("add_child", button)
		buttons_available.append(button)
	$InventoryUILayer/SelectionControl.visible = true

func choose_item(item_id):
	UI.set_pause(false)
	
	$InventoryUILayer/SelectionControl.visible = false
	await Profile.add_run_data("INVENTORY", "ITEMS_STORED", item_id)
	load_items()
