extends Control

@onready var main_menu = get_parent().get_parent()
@export var debug : bool = false

var run_started : bool = false
var items_dict : Dictionary
var weapons_dict : Dictionary
const items_data_path = "res://data/items_data.json"
const weapons_data_path = "res://data/weapons_data.json"
const first_stage = "res://scenes/stages/stage_one.tscn"

const tutorial_stage_path = "res://scenes/stages/strata_scene.tscn"
const practice_stage_path = "res://scenes/stages/practice_stage.tscn"

var primary_weapons : Array
var secondary_weapons : Array
var starter_items : Array

var selected_primary : String
var selected_secondary : String
var selected_item : String

func _ready():
	## Patch debug
	if OS.is_debug_build():
		$Dashboard/PracticeButton.disabled = false
	
	## Make ready
	var primary_weapons_list = $Dashboard/CustomizeLoadoutContainer/LoadoutLists/PrimaryWeaponsList
	var secondary_weapons_list = $Dashboard/CustomizeLoadoutContainer/LoadoutLists/SecondaryWeaponsList
	var starter_items_list = $Dashboard/CustomizeLoadoutContainer/LoadoutLists/StarterItemsList
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
	else: # No previous selection in profile. Selecting the first of every option
		selected_primary = primary_weapons[0]
		selected_secondary = secondary_weapons[0]
		selected_item = starter_items[0]
	
	## Patches
	# $StartButton.position = Vector2(802, 368)

func set_focus():
	$Dashboard/StartButton.grab_focus()

func _on_start_button_pressed(): # StartButton
	if !run_started: 
		$AnimationPlayer.play("press_button")
		start_run(first_stage)
		AudioManager.emit_sound_effect(null, "analog-appliance-button", false, true)
	run_started = true

func _on_tutorial_button_pressed():
	start_run(tutorial_stage_path)

func _on_practice_button_pressed():
	start_run(practice_stage_path)

func _on_return_to_main_menu_pressed():
	owner.set_page_position(0, true)

func _on_config_button_pressed():
	Options.visible = true

func _on_options_visibility_changed():
	print('Main menu recieved return from options menu')

## Loadout Lists
func _on_primary_weapons_list_item_selected(index):
	if debug: print(primary_weapons[index])
	selected_primary = primary_weapons[index]
	AudioManager.emit_sound_effect(null, "select_sound_1", false, true)

func _on_secondary_weapons_list_item_selected(index):
	if debug: print(secondary_weapons[index])
	selected_secondary = secondary_weapons[index]
	AudioManager.emit_sound_effect(null, "select_sound_1", false, true)

func _on_starter_items_list_item_selected(index):
	if debug: print(starter_items[index])
	selected_item = starter_items[index]
	AudioManager.emit_sound_effect(null, "select_sound_1", false, true)

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
	Profile.add_run_data("INVENTORY", "ITEMS_STORED", selected_item)

func start_run(stage_path):
	await UI.fade('OUT')
	await confirm_selection()
	LoadManager.load_scene(stage_path)
