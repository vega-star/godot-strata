extends Control

@onready var transition_layer = $ScreenTransitionLayer
@onready var transition_time = transition_layer.fade_time
var run_started : bool = false
var items_dict : Dictionary
var weapons_dict : Dictionary
const items_data_path = "res://data/items_data.json"
const weapons_data_path = "res://data/weapons_data.json"

var primary_weapons : Array
var secondary_weapons : Array
var starter_items : Array

var selected_primary : String
var selected_secondary : String
var selected_item : String

@export var debug : bool = false

func _ready():
	var primary_weapons_list = $CustomizeLoadout/CustomizeLoadoutContainer/LoadoutLists/PrimaryWeaponsList
	var secondary_weapons_list = $CustomizeLoadout/CustomizeLoadoutContainer/LoadoutLists/SecondaryWeaponsList
	var starter_items_list = $CustomizeLoadout/CustomizeLoadoutContainer/LoadoutLists/StarterItemsList
	primary_weapons_list.clear()
	secondary_weapons_list.clear()
	starter_items_list.clear()
	
	assert(FileAccess.file_exists(weapons_data_path))
	var load_weapons_data = FileAccess.open(weapons_data_path, FileAccess.READ)
	weapons_dict = JSON.parse_string(load_weapons_data.get_as_text())
	
	assert(FileAccess.file_exists(items_data_path))
	var load_items_data = FileAccess.open(items_data_path, FileAccess.READ)
	items_dict = JSON.parse_string(load_items_data.get_as_text())
	items_dict = items_dict["items"]
	
	## Primary
	for primary in weapons_dict["primary"]:
		primary_weapons.append(primary)
		primary_weapons_list.add_item(
			weapons_dict["primary"][primary]["weapon_properties"]["weapon_name"]
			# weapons_dict["primary"][primary]["weapon_properties"]["weapon_small_icon"]
		)
	
	## Secondary
	for secondary in weapons_dict["secondary"]:
		secondary_weapons.append(secondary)
		secondary_weapons_list.add_item(
			weapons_dict["secondary"][secondary]["weapon_properties"]["weapon_name"]
		)
	
	## Items
	for item in items_dict:
		starter_items.append(item)
		starter_items_list.add_item(
			items_dict[item]["item_name"]
		)
	
	## Pre-select items that were selected in the previous run
	if Profile.profiles_data.has_section_key(Profile.selected_profile, "SAVED_LOADOUT"):
		var saved_loadout = Profile.profiles_data.get_value(Profile.selected_profile, "SAVED_LOADOUT")
		# selected_primary = Profile.profiles_data.get_value(Profile.selected_profile, "SAVED_LOADOUT", [0])
		for i in primary_weapons.size():
			if primary_weapons[i] == saved_loadout[0]:
				primary_weapons_list.select(i)
				selected_primary = saved_loadout[0]
		
		for i in secondary_weapons.size():
			if secondary_weapons[i] == saved_loadout[1]:
				secondary_weapons_list.select(i)
				selected_secondary = saved_loadout[1]
		
		for i in starter_items.size():
			if starter_items[i] == saved_loadout[2]:
				starter_items_list.select(i)
				selected_item = saved_loadout[2]
	
	transition_layer.visible = true
	transition_layer.fade('IN')
	await get_tree().create_timer(transition_time).timeout
	$StartButton.grab_focus()
	transition_layer.visible = false

func _on_start_button_pressed(): # StartButton
	confirm_selection()
	
	transition_layer.fade('OUT')
	transition_layer.visible = true
	await get_tree().create_timer(transition_time).timeout
	get_tree().change_scene_to_file("res://scenes/strata_scene.tscn")

func _on_return_to_main_menu_pressed():
	transition_layer.visible = true
	transition_layer.fade('OUT')
	await get_tree().create_timer(transition_time).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_config_button_pressed():
	Options.visible = true

func _on_options_visibility_changed():
	print('Main menu recieved return from options menu')

## Loadout Lists
func _on_primary_weapons_list_item_selected(index):
	if debug: print(primary_weapons[index])
	selected_primary = primary_weapons[index]

func _on_secondary_weapons_list_item_selected(index):
	if debug: print(secondary_weapons[index])
	selected_secondary = secondary_weapons[index]

func _on_starter_items_list_item_selected(index):
	if debug: print(starter_items[index])
	selected_item = starter_items[index]

func confirm_selection():
	Profile.start_run()
	
	Profile.profiles_data.set_value(Profile.selected_profile, "SAVED_LOADOUT", [
		selected_primary,
		selected_secondary,
		selected_item
	])
	Profile.save_profile_data()
	
	Profile.current_run_data.set_value("INVENTORY", "PRIMARY_WEAPON", selected_primary)
	Profile.current_run_data.set_value("INVENTORY", "SECONDARY_WEAPON", selected_secondary)
	# Profile.current_run_data.set_value("INVENTORY", "ITEMS_STORED", item_array)
	Profile.add_run_data("INVENTORY", "ITEMS_STORED", selected_item)
