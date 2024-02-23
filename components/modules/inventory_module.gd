class_name InventoryModule extends Node

signal buff_activated
signal buff_deactivated(source)

@export var equipment_module : EquipmentModule
@export var selected_primary : String = "default_laser"
@export var selected_secondary : String = "default_missile"

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
# type - 
#	- boost
# target -
#	- primary_rof
# value - Commonly float value that multiples with 1 to add buffs into certain actions.
## Starter
# true/false - Declares if this item can be selected in the loadout screen at the start of the run or maybe bought with scrap.

var items_dict : Dictionary = {
	001: {
		"item_name": "Rotary Autocannon",
		"item_description": "Projectiles from primary weapon are shot from a fast RPM rotary cannon. Rate of fire increased by 15%",
		"item_type": "passive",
		"item_tier": 0, # Common, human-made
		"item_category": 0,
		"item_effect": {
			"type": 'boost', 
			"target": 'primary_rof_buff',
			"value": 1.15
			# "period": 4
		},
		"temporary": false,
		"starter": true
	}
}

var equipment : Dictionary = {
	"selected_weapons" = ["default_laser", "default_missile"],
	"inventory" = {
		"primary_weapons" = [
			"default_laser",
			"default_minigun"
		],
		"secondary_weapons" = [
			"default_bomb",
			"default_missile"
		]
	},
	"items" = [
		001
	]
}

var active_buffs : Dictionary = {}

func _ready():
	load_equipment()

func load_equipment():
	equipment_module.set_primary = equipment["selected_weapons"][0]
	equipment_module.set_secondary = equipment["selected_weapons"][1]
	
	for item in equipment["items"]:
		match items_dict[item]["item_effect"]["type"]:
			'boost':
				var buff_period = null
				if items_dict[item]["temporary"]:
					buff_period = items_dict[item]["item_effect"]["period"]
				boost(
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

func boost(source, target_status, buff, buff_period = null):
	var temporary : bool = false
	if buff_period: temporary = true
	
	match target_status:
		0, "primary_damage_buff":
			equipment_module.add_buff("primary_damage_buff", buff)
		1, "primary_rof_buff":
			equipment_module.add_buff("primary_rof_buff", buff)
		2, "secondary_damage_buff":
			equipment_module.add_buff("secondary_damage_buff", buff)
		3, "secondary_rof_buff":
			equipment_module.add_buff("secondary_rof_buff", buff)
		4, "secondary_additional_amount":
			equipment_module.add_buff("secondary_additional_amount", buff)
	
	active_buffs[source] = {
		"buff" = target_status,
		"buff_value" = buff,
		"buff_period" = buff_period
	}
	
	equipment_module.update_equipment()
	buff_activated.emit()
	if temporary:
		await get_tree().create_timer(buff_period).timeout
		buff_deactivated.emit(source)
