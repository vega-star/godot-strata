class_name EquipmentModule extends Node

signal item_picked
signal equipment_loaded
signal ammo_changed(current_ammo, previous_ammo)
signal effect_changed
signal effect_activated
signal effect_deactivated(source)

## EquipmentModule reacts to the player inputs and uses equipped guns, ammo, active items, and such.
#
# Previously, most of these functions were present directly in the player script, which it's not practical for adding new features.
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
@export var debug : bool

## Equipped items and weapons
var selected_primary : String
var selected_secondary : String
var base_primary_rof
var base_secondary_rof
var secondary_projectiles_amount : int = 1

var ammo : int
var max_ammo : int
var regenerate_ammo : bool
var ammo_regeneration : bool
var ammo_regeneration_cooldown : float

## Effect variables
var active_buffs : Array

var primary_damage_factor : float = 1.0
var primary_rof_factor : float = 1.0

var additional_ammo : int = 0
var ammo_regeneration_cd_factor : float = 1
var secondary_damage_factor : float = 1.0
var secondary_rof_factor : float = 1.0
#endregion

func _ready():
	randomize()
	
	assert(FileAccess.file_exists(weapons_data_path))
	var load_weapons_data = FileAccess.open(weapons_data_path, FileAccess.READ)
	weapons_dict = JSON.parse_string(load_weapons_data.get_as_text())
	
	assert(FileAccess.file_exists(items_data_path))
	var load_items_data = FileAccess.open(items_data_path, FileAccess.READ)
	items_dict = JSON.parse_string(load_items_data.get_as_text())
	items_dict = items_dict["items"]
	
	owner.fire_primary.connect(_on_player_primary_fired)
	owner.fire_secondary.connect(_on_player_secondary_fired)
	
	await load_equipment()
	await load_items(true)
	update_player_values()

func _process(_delta):
	if regenerate_ammo:
		if !ammo_regeneration:
			ammo_regeneration = true
			await get_tree().create_timer(ammo_regeneration_cooldown, false).timeout
			add_ammo(1)
			ammo_regeneration = false

#region Equipment
func load_equipment(set_primary = null, set_secondary = null): ## Loads equipment properly at the start of the scene. Can be used again after changes in Inventory.
	## Set or load primary
	if set_primary: selected_primary = set_primary
	else: selected_primary = Profile.current_run_data.get_value("INVENTORY", "PRIMARY_WEAPON")
	eqquiped_primary = weapons_dict["primary"][selected_primary]
	
	## Set or load secondary
	if set_secondary: selected_secondary = set_secondary
	else: selected_secondary = Profile.current_run_data.get_value("INVENTORY", "SECONDARY_WEAPON")
	eqquiped_secondary = weapons_dict["secondary"][selected_secondary]
	
	## Load base values
	primary_weapon_scene = load(eqquiped_primary["projectile_scene"])
	secondary_weapon_scene = load(eqquiped_secondary["projectile_scene"])
	
	base_primary_rof = eqquiped_primary["base_rate_of_fire"]
	base_secondary_rof = eqquiped_secondary["base_rate_of_fire"]
	secondary_projectiles_amount = eqquiped_secondary["base_amount"]
	regenerate_ammo = eqquiped_secondary["base_regeneration"]
	if regenerate_ammo: ammo_regeneration_cooldown = eqquiped_secondary["base_regeneration_cooldown"] * ammo_regeneration_cd_factor
	
	equipment_loaded.emit()

func reload_ammo(start : bool = false):
	max_ammo = (
		Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO") + Profile.current_run_data.get_value("EFFECTS", "BONUS_AMMO")
	)
	UI.UIOverlay.set_max_ammo = max_ammo
	if start:
		ammo = max_ammo
		UI.UIOverlay.set_ammo = max_ammo
		Profile.current_run_data.set_value("INVENTORY", "CURRENT_AMMO", max_ammo)
		health_component.reset_health()

func load_items(start : bool = false):
	reset_buff()
	for item in Profile.current_run_data.get_value("INVENTORY", "ITEMS_STORED"):
		print(item)
		match items_dict[item]["item_type"]:
			"passive":
				var buff_period = null
				if items_dict[item]["item_properties"]["temporary"]:
					buff_period = items_dict[item]["item_effect"]["period"]
				create_buff(
					items_dict[item]["item_name"],
					items_dict[item]["item_effect"]["target"],
					items_dict[item]["item_effect"]["value"],
					buff_period,
					items_dict[item]["item_properties"]["accumulate"]
				)
	# Patch certain effects
	reload_ammo(start)

func change_equipment(target_equipment, value):
	match target_equipment:
		0, "selected_primary": selected_primary = value
		1, "selected_secondary": selected_secondary = value
		_: push_error("Invalid equipment type")
	load_equipment()

func update_player_values():
	owner.set_primary_rof = base_primary_rof * primary_rof_factor
	owner.set_secondary_rof = base_secondary_rof * secondary_rof_factor
	
	owner.status_change.emit()
	UI.UIOverlay.update_hud()

## Weapon usage
func _on_player_primary_fired(start_position):
	var primary_shot = primary_weapon_scene.instantiate()
	primary_shot.global_position = start_position
	primary_shot.projectile_damage *= primary_damage_factor
	projectile_container.add_child(primary_shot)

# Secondary weapon
func _on_player_secondary_fired(reference, _secondary_ammo):
	ammo -= 1
	ammo_changed.emit(ammo, ammo + 1)
	Profile.add_run_data("STATISTICS", "AMMO_CONSUMED", 1)
	
	var interval = (base_secondary_rof * secondary_rof_factor) / 30
	for amount in secondary_projectiles_amount: # For multiple projectiles weapon
		var secondary_shot = secondary_weapon_scene.instantiate()
		secondary_shot.global_position = reference.global_position
		projectile_container.add_child(secondary_shot)
		if secondary_projectiles_amount > 1: await get_tree().create_timer(interval).timeout

func update_ammo(new_ammo, _previous_ammo):
	print(new_ammo)
	ammo = new_ammo
	Profile.current_run_data.set_value("INVENTORY", "CURRENT_AMMO", new_ammo)
	UI.UIOverlay.set_ammo = new_ammo
	UI.UIOverlay.update_hud()

func add_ammo(ammo_value):
	if ammo + ammo_value > max_ammo: # Cap the value to prevent overflow
		ammo_changed.emit(max_ammo, ammo)
	else: # Simply add ammo
		ammo_changed.emit(ammo + ammo_value, ammo)
		Profile.add_run_data("STATISTICS", "AMMO_RECOVERED", ammo_value)
#endregion

#region Buffs
func reset_buff():
	primary_damage_factor = 1.0
	primary_rof_factor = 1.0
	secondary_damage_factor = 1.0
	secondary_rof_factor = 1.0
	additional_ammo= 0
	Profile.current_run_data.set_value("EFFECTS", "BONUS_AMMO", 0)
	active_buffs.clear()

func infer_effect(effect, value, positive : bool = true):
	match effect:
		"primary_damage_buff":
			if positive: 
				primary_damage_factor *= value
			else: 
				primary_damage_factor /= value
		"primary_rof_buff":
			if positive: 
				primary_rof_factor /= value
			else: 
				primary_rof_factor *= value
		"secondary_rof_buff":
			if positive:
				secondary_rof_factor /= value
			else:
				secondary_rof_factor *= value
		"additional_ammo":
			if positive:
				additional_ammo += value
				Profile.add_run_data("EFFECTS", "BONUS_AMMO", value)
				await reload_ammo()
				add_ammo(value)
			else:
				additional_ammo -= value
				Profile.current_run_data.set_value("EFFECTS", "BONUS_AMMO", additional_ammo)
				await reload_ammo()
				if ammo - value > max_ammo: update_ammo(max_ammo, ammo)
				elif ammo - value > 0: update_ammo(ammo - value, ammo)
				else: update_ammo(0, ammo)
		"dash_cooldown_factor":
			pass
		"dash_speed_buff":
			pass
		_:
			push_error('{0} | Buff request received, but status is invalid. No change has been made.'.format({0:effect}))
	effect_changed.emit()

func create_buff(source, target_status, value, period = null, accumulate : bool = false):
	var temporary : bool = false
	var source_found : bool = false
	if period: temporary = true
	
	## Source management
	if active_buffs.has(source): # Check if it already exists interpolate source name
		source_found = true
		var source_num = active_buffs.count(source)
		source = '{0}_{1}'.format({0:source, 1:source_num})
		print(source)
	
	if !accumulate: # Check if it can accumulate or not
		if source_found:
			if debug: print('Buff not valid because another one of this kind is active. Toggle accumulate on if you still want it to work.')
			return
	
	if target_status is Array and value is Array: # Re-executes function from each item in a array
		for target in target_status.size():
			var target_index = target - 1
			create_buff(source, target_status[target_index], value[target_index], period)
		return
	
	## Apply buff. If prompted, wait for buff to timeout and deactivate it
	infer_effect(target_status, value)
	
	active_buffs.append(source)
	Profile.current_run_data.set_value("EFFECTS", "ACTIVE_EFFECTS", active_buffs)
	
	effect_activated.emit()
	if temporary:
		await get_tree().create_timer(period).timeout
		effect_deactivated.emit(source, target_status, value)

func _on_effect_deactivated(source, target_status, value):
	if debug: print('%s | Deactivated' % source)
	infer_effect(target_status, value, false)
	active_buffs.erase(source)
	Profile.current_run_data.set_value("EFFECTS", "ACTIVE_EFFECTS", active_buffs)
#endregion

#region Item Selection
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
	await get_tree().create_timer(0.5).timeout
	print(buttons_available[int(buttons_available.size() / 2)])
	buttons_available[int(buttons_available.size() / 2)].grab_focus()

func choose_item(item_id):
	UI.set_pause(false)
	buttons_available.clear()
	$InventoryUILayer/SelectionControl.visible = false
	
	for n in selection_options.get_children():
		selection_options.remove_child(n)
		n.queue_free()
	
	await Profile.add_run_data("INVENTORY", "ITEMS_STORED", item_id)
	item_picked.emit()
	load_items()
#endregion
