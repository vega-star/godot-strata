extends Control

@onready var main_menu = get_parent().get_parent()
@onready var primary_weapons_list = $Dashboard/CustomizeLoadoutContainer/LoadoutLists/PrimaryWeaponsList
@onready var secondary_weapons_list = $Dashboard/CustomizeLoadoutContainer/LoadoutLists/SecondaryWeaponsList
@onready var starter_items_list = $Dashboard/CustomizeLoadoutContainer/LoadoutLists2/StarterItemsList

@export var compact_format : bool = false
@export var debug : bool = false

var run_started : bool = false
var items_dict : Dictionary
var weapons_dict : Dictionary
const items_data_path = "res://data/items_data.json"
const weapons_data_path = "res://data/weapons_data.json"
const first_stage = "res://scenes/stages/stage_one.tscn"

const tutorial_stage_path = "res://scenes/stages/stage_source.tscn"
const practice_stage_path = "res://scenes/stages/practice_stage.tscn"

var primary_weapons : Array
var secondary_weapons : Array
var starter_items : Array

var selected_primary : String
var selected_secondary : String
var selected_item : String

func _ready():
	## Patch debug
	#if OS.is_debug_build():
	#	$Dashboard/PracticeButton.disabled = false
	
	Options.language_changed.connect(_on_language_changed)
	
	load_items()

func load_items():
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
	
	construct_list(primary_weapons_list, primary_weapons, weapons_dict, "primary")
	construct_list(secondary_weapons_list, secondary_weapons, weapons_dict, "secondary")
	
	for item in items_dict: ## Items list
		starter_items.append(item)
		starter_items_list.add_item(items_dict[item]["item_name"])
	
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

func construct_list(list_node, list_array : Array, source_dict : Dictionary, source_type : String):
	if compact_format: 
		list_node.set_icon_scale(3)
		list_node.set_max_columns(0)
	for i in source_dict[source_type]:
		var status : bool = source_dict[source_type][i]["weapon_properties"]["unlocked"]; if !status: return # Not unlocked, ignore
		var icon_path = source_dict[source_type][i]["weapon_properties"]["weapon_icon"]
		var icon; if icon_path: icon = load(icon_path)
		list_array.append(i)
		if icon: 
			if compact_format: list_node.add_item("", icon)
			else: list_node.add_item(TranslationServer.tr(i).to_upper(), icon)
		else: list_node.add_item(TranslationServer.tr(i).to_upper())
		list_node.set_item_tooltip(secondary_weapons.find(i), TranslationServer.tr(source_dict[source_type][i]["weapon_properties"]["weapon_description"]))

func set_focus():
	$Dashboard/StartButton.grab_focus()

func _on_start_button_pressed(): # StartButton
	if !run_started: 
		$AnimationPlayer.play("press_button")
		start_run(first_stage)
		AudioManager.emit_sound_effect(null, "analog-appliance-button")
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
	AudioManager.emit_sound_effect(null, "select_sound_1")

func _on_secondary_weapons_list_item_selected(index):
	if debug: print(secondary_weapons[index])
	selected_secondary = secondary_weapons[index]
	AudioManager.emit_sound_effect(null, "select_sound_1")

func _on_starter_items_list_item_selected(index):
	if debug: print(starter_items[index])
	selected_item = starter_items[index]
	AudioManager.emit_sound_effect(null, "select_sound_1")

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
	
	Profile.save_previous_data()

func _on_language_changed():
	load_items()

func start_run(stage_path):
	await UI.fade('OUT')
	await confirm_selection()
	LoadManager.load_scene(stage_path)
