extends CanvasLayer

@onready var hide_button = $PracticeMenu/HideButton

## SIGNALS
signal weapon_updated

## MAIN VARIABLES
var player
var weapons_dict : Dictionary
var primary_weapons : Array
var secondary_weapons : Array
var starter_items : Array
var selected_primary : String
var selected_secondary : String
var selected_item : String

## CONSTANTS
const minimized_offset : int = 180
const items_data_path = "res://data/items_data.json"
const weapons_data_path = "res://data/weapons_data.json"

## INITIALIZE
func _ready():
	## Prepare nodes
	var primary_weapons_list = $PracticeMenu/PracticeTabs/Player/ContainerSeparator/WeaponsContainer/LoadoutLists/PrimaryWeaponsList
	var secondary_weapons_list = $PracticeMenu/PracticeTabs/Player/ContainerSeparator/WeaponsContainer/LoadoutLists/SecondaryWeaponsList
	primary_weapons_list.clear()
	secondary_weapons_list.clear()
	
	player = get_tree().get_first_node_in_group("player")
	player.fire_secondary.connect(_on_player_fire_secondary)
	
	## Load data
	assert(FileAccess.file_exists(weapons_data_path))
	var load_weapons_data = FileAccess.open(weapons_data_path, FileAccess.READ)
	weapons_dict = JSON.parse_string(load_weapons_data.get_as_text())
	
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
	
	selected_primary = primary_weapons[0]
	Profile.current_run_data.set_value("INVENTORY", "PRIMARY_WEAPON", selected_primary)
	
	selected_secondary = secondary_weapons[0]
	Profile.current_run_data.set_value("INVENTORY", "SECONDARY_WEAPON", selected_secondary)
	
	print(weapons_dict)
	
	## Finish
	await get_tree().create_timer(3).timeout
	hide_button.button_pressed = true

## HIDE/SHOW MENU
func _on_hide_button_toggled(toggled_on):
	var hide_tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if toggled_on:
		hide_button.flip_v = true
		hide_tween.tween_property(self, "offset", Vector2(0, 0), 1)
	else:
		hide_button.flip_v = false
		hide_tween.tween_property(self, "offset", Vector2(0, minimized_offset), 1)

## WEAPONS
func _on_primary_weapons_selected(index):
	selected_primary = primary_weapons[index]
	AudioManager.emit_sound_effect(null, "select_sound_1", false, true)
	Profile.current_run_data.set_value("INVENTORY", "PRIMARY_WEAPON", selected_primary)
	player.equipment_module.load_equipment(selected_primary, null)

func _on_secondary_weapons_selected(index):
	selected_secondary = secondary_weapons[index]
	AudioManager.emit_sound_effect(null, "select_sound_1", false, true)
	Profile.current_run_data.set_value("INVENTORY", "SECONDARY_WEAPON", selected_secondary)
	player.equipment_module.load_equipment(null, selected_secondary)

func _on_weapon_updated():
	$PracticeMenu/PracticeTabs/Player/ContainerSeparator/WeaponProperties/PrimaryDamage/SpinBox.set_value(
		weapons_dict["primary"][selected_primary]["base_damage"]
	)
	$PracticeMenu/PracticeTabs/Player/ContainerSeparator/WeaponProperties/PrimaryPass/SpinBox.set_value(
		weapons_dict["primary"][selected_primary]["base_projectile_passthrough"]
	)
	$PracticeMenu/PracticeTabs/Player/ContainerSeparator/WeaponProperties/SecondaryAmmo/SpinBox.set_value(
		Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO") + Profile.current_run_data.get_value("EFFECTS", "BONUS_AMMO")
	)
	$PracticeMenu/PracticeTabs/Player/ContainerSeparator/WeaponProperties/SecondaryAmount/SpinBox.set_value(
		Profile.current_run_data.get_value("INVENTORY", "CURRENT_AMMO")
	)

func _on_player_fire_secondary():
	$PracticeMenu/PracticeTabs/Player/ContainerSeparator/WeaponProperties/SecondaryAmount/SpinBox.set_value(
		Profile.current_run_data.get_value("INVENTORY", "CURRENT_AMMO")
	)

func _on_secondary_ammo_altered():
	var value = $PracticeMenu/PracticeTabs/Player/ContainerSeparator/WeaponProperties/SecondaryAmount/SpinBox.get_value()
	player.equipment_module.update_ammo(value)

func _on_secondary_max_ammo_altered():
	var value = $PracticeMenu/PracticeTabs/Player/ContainerSeparator/WeaponProperties/SecondaryMax/SpinBox.get_value()
	Profile.current_run_data.set_value("INVENTORY", "MAX_AMMO", value)
	player.equipment_module.reload_ammo()
