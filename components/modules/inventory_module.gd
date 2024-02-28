class_name InventoryModule extends Node

signal buff_activated
signal buff_deactivated(source)

@onready var selection_control = $InventoryUILayer/SelectionControl
@onready var selection_options = $InventoryUILayer/SelectionControl/SelectionOptions

@export var equipment_module : EquipmentModule
@export var selected_primary : String
@export var selected_secondary : String

## Name and description
# Capitalized strings for UI usage
## Types
# 0, Passive - Items that only have to be on inventory for its effect to take hold. You can carry and combine 5 of those.
# 1, Active - Items that need to be used to cause a certain effect. You can only carry one of those.
## Tiers
# 0 - Common
# 1 - Uncommon
# 2 - Rare
# 3 - Unique
# 4 - Legendary
## Categories
# 0 - Human-made
# 1 - Alien-made
# 2 - Hybrid, highly adapted for vehicles
## Effect
# type - Defines how the item is collected, stored and used
#	- boost
#	- stack
# target -
#	- primary_rof
# value - Commonly float value that multiples with 1 to add buffs into certain actions.
## Starter
# true/false - Declares if this item can be selected in the loadout screen at the start of the run or maybe bought with scrap.

const items_data_path = "res://data/items_data.json"
var items_dict : Dictionary

var active_buffs : Dictionary = {}

func _ready():
	assert(FileAccess.file_exists(items_data_path))
	var load_items_data = FileAccess.open(items_data_path, FileAccess.READ)
	items_dict = JSON.parse_string(load_items_data.get_as_text())
	items_dict = items_dict["items"]
	
	selected_primary = Profile.current_run_data.get_value("INVENTORY", "PRIMARY_WEAPON")
	selected_secondary = Profile.current_run_data.get_value("INVENTORY", "SECONDARY_WEAPON")
	
	if equipment_module:
		load_items()
	else:
		print('No equipment detected, values are not loaded to player yet')
	
func load_items():
	for item in Profile.current_run_data.get_value("INVENTORY", "ITEMS_STORED"):
		match items_dict[item]["item_effect"]["type"]:
			'boost':
				var buff_period = null
				if items_dict[item]["temporary"]:
					buff_period = items_dict[item]["item_effect"]["period"]
				create_buff(
					items_dict[item]["item_name"],
					items_dict[item]["item_effect"]["target"],
					items_dict[item]["item_effect"]["value"],
					buff_period
				)

func change_equipment(target_equipment, value):
	match target_equipment:
		0, "selected_primary": selected_primary = value
		1, "selected_secondary": selected_secondary = value
		_: push_error("Invalid equipment type")

func create_buff(source, target_status, value, period = null):
	var temporary : bool = false
	if period: temporary = true
	
	if target_status is Array and value is Array:
		for target in target_status.size():
			create_buff(source, target_status[target - 1], value[target - 1], period)
		return
	
	match target_status:
		0, "primary_damage_buff":
			equipment_module.add_buff("primary_damage_buff", value)
		1, "primary_rof_buff":
			equipment_module.add_buff("primary_rof_buff", value)
		2, "secondary_damage_buff":
			equipment_module.add_buff("secondary_damage_buff", value)
		3, "secondary_rof_buff":
			equipment_module.add_buff("secondary_rof_buff", value)
		4, "secondary_additional_amount":
			equipment_module.add_buff("secondary_additional_amount", value)
		5, "dash_cooldown_factor":
			pass
		6, "dash_speed_buff":
			pass
	
	active_buffs[source] = {
		"buff" = target_status,
		"buff_value" = value,
		"buff_period" = period
	}
	
	equipment_module.update_equipment()
	buff_activated.emit()
	if temporary:
		await get_tree().create_timer(period).timeout
		buff_deactivated.emit(source)

func _on_buff_deactivated(source):
	await equipment_module.reset_buffs()
	load_items()
	active_buffs.erase(source)

## Item Selection
var buttons_available : Array

func _process(delta): # debug
	if Input.is_action_just_pressed("dash"):
		present_choice(["ICAmplifier","AdditionalHardpoint","PlasteelWing"])

func present_choice(items):
	assert(items is Array)
	for item in items:
		var button_scene = load("res://components/ui/selection_button.tscn")
		var button = button_scene.instantiate()
		print(items_dict[item])
		
		button.set_button_properties(
			items_dict[item]["item_name"],
			items_dict[item]["item_properties"]["item_icon"],
			items_dict[item]["item_description"],
			items_dict[item]["item_properties"]["item_tier"]
		)
		
		selection_options.call_deferred("add_child", button)
		buttons_available.append(button)

func choose_item():
	pass
