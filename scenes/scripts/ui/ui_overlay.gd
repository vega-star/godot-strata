extends CanvasLayer

#region MAIN VARIABLES
@export_group("Node Connections")
@export var ui_animation_player : AnimationPlayer
@export var heat_bar : TextureProgressBar
@export var bars : Control

@export_group("UI Configuration")
@export var selected_health_skin = "classic_hp" ## HP texture
@export var selected_ammo_skin = "classic_ammo" ## Ammo texture
@export var show_boss_bar : bool = true
@export var hide_progress_bar : bool = false
@export var debug : bool = false ## Print displayed values on update

@export_group("UI Values")
@export var limit_hp_slots : int = 3 ## How many full-sized containers until it shifts to small containers
@export var limit_secondary_ammo : int = 3 ## How many full-sized containers until it shifts to small containers

@onready var power_indicator = $HUD/Info/Elements/PowerIndicator/IndicatorLight
@onready var roll_indicator = $HUD/Info/Elements/RollIndicator/IndicatorLight

## HUD Constructor Data
## Briefing
# This is used by a hud constructor that builds a series of control nodes and position them in a modular, fully scalable way
# This is totally spaghetti code and I *REALLY* do not recommend using it, for even I sincerely don't understand it fully sometimes
# I made this when I was first learning Godot and it was pretty good practice, but it's not pratical AT ALL and too complex

@onready var hud_nodes_list : Dictionary = {
	"main_nodes": {
		"hp": {
			"container": $HUD/Info/Health/Container,
			"short_container": $HUD/Info/Health/SmallContainer,
			"cell": $HUD/Info/Health/Container/HealthCounter,
			"short_cell": $HUD/Info/Health/SmallContainer/HealthCounter,
			"start": $HUD/Info/Health/Start,
			"end": $HUD/Info/Health/End
		},
		"ammo": {
			"container": $HUD/Info/Ammo/Container,
			"short_container": $HUD/Info/Ammo/SmallContainer,
			"cell": $HUD/Info/Ammo/Container/AmmoCounter,
			"short_cell": $HUD/Info/Ammo/SmallContainer/AmmoCounter,
			"start": $HUD/Info/Ammo/Start,
			"end": $HUD/Info/Ammo/End
		}}}

const hud_elements_list : Dictionary = {
	"old_hp": {
		"type": 0, # HP
		"start_position_x": 38,
		"start_position_y": 0,
		"position_offset": 0,
		"has_start_sprite": true, 
		"has_end_sprite": true, 
		"sprites": {
			"cell_sprite_path": "res://assets/textures/ui/hud/classic/hp_cell.png",
			"short_cell_sprite_path": "res://assets/textures/ui/hud/classic/hp_short_cell.png",
			"container_sprite_path": "res://assets/textures/ui/hud/classic/hpbar_container.png",
			"short_container_sprite_path": "res://assets/textures/ui/hud/classic/hpbar_container_short.png",
			"start_sprite": "res://assets/textures/ui/hud/classic/hpbar_start.png",
			"end_sprite": "res://assets/textures/ui/hud/classic/hpbar_end.png",
			"heat_bar": "res://assets/textures/ui/hud/classic/heat_bar.png",
			"heat_bar_danger": "res://assets/textures/ui/hud/classic/heat_bar_danger_tall.png"
		},
		"containers": {
			"container_size_h": 52,
			"container_size_y": 38,
			"short_container_size_h": 26,
			"short_container_size_y": 38
		},
		"cells": {
			"cell_size_h": 52,
			"cell_size_y": 38,
			"short_cell_size_h": 26,
			"short_cell_size_y": 38
		}
	},
	"old_ammo": {
		"type": 1, # Ammo
		"start_position_x": 0,
		"start_position_y": 0,
		"position_offset": 5,
		"has_end_sprite": false,
		"has_start_sprite": false,
		"sprites": {
			"cell_sprite_path": "res://assets/textures/ui/hud/classic/bomb_cell.png",
			"short_cell_sprite_path": "res://assets/textures/ui/hud/classic/bomb_short_cell.png",
			"container_sprite_path": "res://assets/textures/ui/hud/classic/bomb_container.png",
			"short_container_sprite_path": "res://assets/textures/ui/hud/classic/bomb_short_container.png"
		},
		"containers": {
			"container_size_h": 26,
			"container_size_y": 26,
			"short_container_size_h": 16,
			"short_container_size_y": 26
		},
		"cells": {
			"cell_size_h": 26,
			"cell_size_y": 26,
			"short_cell_size_h": 16,
			"short_cell_size_y": 26
		}
	},
	"classic_hp": {
		"type": 0, # HP
		"revert_position": false,
		"start_position_x": 46,
		"start_position_y": 0,
		"position_offset": 0,
		"has_end_sprite": true,
		"has_start_sprite": true,
		"sprites": {
			"cell_sprite_path": "res://assets/textures/ui/hud/neptune/health_capsule.png",
			"short_cell_sprite_path": "res://assets/textures/ui/hud/neptune/health_capsule_small.png",
			"container_sprite_path": "res://assets/textures/ui/hud/neptune/health_container.png",
			"short_container_sprite_path": "res://assets/textures/ui/hud/neptune/health_container_small.png",
			"start_sprite": "res://assets/textures/ui/hud/neptune/bar_start.png",
			"end_sprite": "res://assets/textures/ui/hud/neptune/bar_end.png",
			"heat_bar": "res://assets/textures/ui/hud/neptune/heat_bar.png",
			"heat_bar_danger": "res://assets/textures/ui/hud/neptune/heat_bar_alarm.png"
		},
		"containers": {
			"container_size_h": 32,
			"container_size_y": 38,
			"short_container_size_h": 20,
			"short_container_size_y": 38
		},
		"cells": {
			"cell_size_h": 32,
			"cell_size_y": 38,
			"short_cell_size_h": 20,
			"short_cell_size_y": 38
		}
	},
	"classic_ammo": {
		"type": 1, # Ammo
		"revert_position": true,
		"start_position_x": 46,
		"start_position_y": 0,
		"position_offset": 0,
		"has_end_sprite": true,
		"has_start_sprite": true,
		"sprites": {
			"cell_sprite_path": "res://assets/textures/ui/hud/neptune/ammo_capsule.png",
			"short_cell_sprite_path": "res://assets/textures/ui/hud/neptune/ammo_capsule_short.png",
			"container_sprite_path": "res://assets/textures/ui/hud/neptune/ammo_container.png",
			"short_container_sprite_path": "res://assets/textures/ui/hud/neptune/ammo_container_small.png",
			"start_sprite": "res://assets/textures/ui/hud/neptune/mixed_bar_start.png",
			"end_sprite": "res://assets/textures/ui/hud/neptune/bar_end.png",
		},
		"containers": {
			"container_size_h": 32,
			"container_size_y": 38,
			"short_container_size_h": 20,
			"short_container_size_y": 38,
			"end_sprite_size": 20,
		},
		"cells": {
			"cell_size_h": 32,
			"cell_size_y": 38,
			"short_cell_size_h": 20,
			"short_cell_size_y": 38
		}}}

# Setters
@onready var set_hp:
	set(hp):
		adapt_hud(hud_elements_list[selected_health_skin], "hp", hp, limit_hp_slots)
@onready var set_max_hp:
	set(max_hp):
		construct_hud(hud_elements_list[selected_health_skin], "hp", max_hp, limit_hp_slots)
@onready var set_ammo:
	set(ammo):
		adapt_hud(hud_elements_list[selected_ammo_skin], "ammo", ammo, limit_secondary_ammo)
@onready var set_max_ammo:
	set(max_ammo):
		construct_hud(hud_elements_list[selected_ammo_skin], "ammo", max_ammo, limit_secondary_ammo)
@onready var stage_progress = bars.progress_bar :
	set(progress_value): ## Recieves and updates stage progress on hud bar
		bars.progress_bar.value = progress_value
#endregion

const heat_bar_factor : int = 25

var current_excess_hp : int
var current_excess_ammo : int
var stage_size : float
var heat_bar_danger : Texture2D
var heat_percentage : float
var heat_urgent : bool
var heating_alert : bool

func _ready():
	Profile.statistics_changed.connect(update_ui_elements)
	update_hud()
	update_ui_elements()
	heat_bar_danger = load(hud_elements_list[selected_health_skin]["sprites"]["heat_bar_danger"])

func _physics_process(delta):
	if heat_urgent and !heating_alert:
		heating_alert = true
		bars.heat_bar.set_over_texture(heat_bar_danger)
		await get_tree().create_timer(heat_bar_factor / heat_percentage).timeout
		bars.heat_bar.set_over_texture(null)
		await get_tree().create_timer(heat_bar_factor / heat_percentage).timeout
		heating_alert = false

func set_stage_bar(max_value): ## Sets the progress bar max value equal to the StageTimer total time in seconds
	bars.progress_bar.set_max(max_value)
	stage_size = max_value

func construct_hud(hud_element, type, set_value, limit):
	## Building the containers
	# Containers are positioned over or behind bars and are just cosmetic. They aren't supposed to change much during a stage
	# However, they need to change if the player catches an empty HP container to raise its max HP, so an update_hud function to switch the boolean below works just fine.
	var offset_value = clamp(-(set_value - limit), 0, 1024)
	var start_position : Vector2
	var hud_nodes = hud_nodes_list["main_nodes"][type]
	var reverse_position : bool = hud_element["revert_position"]
	var has_end_sprite : bool = hud_element["has_end_sprite"]
	var has_start_sprite : bool = hud_element["has_start_sprite"]
	
	if reverse_position: start_position = Vector2(get_viewport().get_visible_rect().size.x - hud_element["start_position_x"], hud_element["start_position_y"])
	else: start_position = Vector2(hud_element["start_position_x"], hud_element["start_position_y"])
	
	if !has_end_sprite: if hud_nodes["end"]: hud_nodes["end"].visible = false
	if !has_start_sprite: if hud_nodes["start"]: hud_nodes["start"].visible = false
	
	## Configuring TextureRect nodes
	hud_nodes["container"].set_texture(load(hud_element["sprites"]["container_sprite_path"]))
	# hud_nodes["container"].size = Vector2(0,0)
	hud_nodes["container"].set_custom_minimum_size(Vector2(
	hud_element["containers"]["container_size_h"],hud_element["containers"]["container_size_y"]))
	hud_nodes["short_container"].set_texture(load(hud_element["sprites"]["short_container_sprite_path"]))
	# hud_nodes["short_container"].size = Vector2(0,0)
	hud_nodes["short_container"].set_custom_minimum_size(Vector2(hud_element["containers"]["short_container_size_h"], hud_element["containers"]["short_container_size_y"]))
	hud_nodes["cell"].set_texture(load(hud_element["sprites"]["cell_sprite_path"]))
	hud_nodes["cell"].set_custom_minimum_size(Vector2(0, hud_element["cells"]["short_cell_size_y"]))
	hud_nodes["short_cell"].set_texture(load(hud_element["sprites"]["short_cell_sprite_path"]))
	hud_nodes["short_cell"].set_custom_minimum_size(Vector2(0, hud_element["cells"]["short_cell_size_y"]))
	
	## Adapting size, position and visibility
	if reverse_position: # Reversed
		if set_value <= limit: # If the value is lower than limit, construct bar without short containers.
			hud_nodes["container"].set_position(start_position - Vector2((hud_element["containers"]["container_size_h"] * set_value), 0))
			hud_nodes["container"].size.x = hud_element["containers"]["container_size_h"] * set_value
			hud_nodes["short_container"].visible = false
			
			if hud_element["has_end_sprite"]:
				hud_nodes["end"].set_texture(load(hud_element["sprites"]["end_sprite"]))
				hud_nodes["end"].position.x = start_position.x - (hud_element["containers"]["container_size_h"] * set_value) - hud_element["containers"]["end_sprite_size"]
		else: # Else, the overflow value will become short containers to shorten occupied screen area
			hud_nodes["container"].set_position(start_position - Vector2((hud_element["containers"]["container_size_h"] * limit), 0))
			hud_nodes["container"].size.x = hud_element["containers"]["container_size_h"] * limit
			hud_nodes["short_container"].visible = true
			hud_nodes["short_container"].size.x = hud_element["containers"]["short_container_size_h"] * (set_value - limit)
			hud_nodes["short_container"].set_position(Vector2(hud_nodes["container"].global_position.x - hud_nodes["short_container"].size.x, 0))
			
			if hud_element["has_end_sprite"]:
				hud_nodes["end"].set_texture(load(hud_element["sprites"]["end_sprite"]))
				hud_nodes["end"].position.x = start_position.x - (hud_element["containers"]["container_size_h"] * limit) - hud_element["containers"]["short_container_size_h"] * (set_value - limit) - hud_element["containers"]["end_sprite_size"]
	else: # Normal
		hud_nodes["container"].set_position(start_position)
		
		if set_value <= limit: # If the value is lower than limit, construct bar without short containers.
			hud_nodes["container"].size.x = hud_element["containers"]["container_size_h"] * set_value
			hud_nodes["short_container"].visible = false
			
			if hud_element["has_end_sprite"]:
				hud_nodes["end"].set_texture(load(hud_element["sprites"]["end_sprite"]))
				hud_nodes["end"].position.x = start_position.x + (hud_element["containers"]["container_size_h"] * set_value)
		else: # Else, the overflow value will become short containers to shorten occupied screen area
			hud_nodes["short_container"].set_position(Vector2(start_position.x + (hud_element["containers"]["container_size_h"] * limit), start_position.y))
			hud_nodes["container"].size.x = hud_element["containers"]["container_size_h"] * limit
			hud_nodes["short_container"].visible = true
			hud_nodes["short_container"].size.x = hud_element["containers"]["short_container_size_h"] * (set_value - limit)
			
			if hud_element["has_end_sprite"]:
				hud_nodes["end"].set_texture(load(hud_element["sprites"]["end_sprite"]))
				hud_nodes["end"].position.x = start_position.x + (hud_element["containers"]["container_size_h"] * limit) + hud_element["containers"]["short_container_size_h"] * (set_value - limit)
	
	# Guidance values
	match type:
		"hp": current_excess_hp = clamp(set_value - limit, 0, 1024)
		"ammo": current_excess_ammo = clamp(set_value - limit, 0, 1024)
	
func adapt_hud(hud_element, type, set_value, limit):
	var offset_value = clamp(-(set_value - limit), 0, 1024)
	var hud_nodes = hud_nodes_list["main_nodes"][type]
	var start_position : Vector2
	var reverse_position : bool = hud_element["revert_position"]
	var current_excess : int
	
	match type:
		"hp": current_excess = current_excess_hp
		"ammo": current_excess = current_excess_ammo
	
	if reverse_position: 
		start_position = Vector2(get_viewport().get_visible_rect().size.x - hud_element["start_position_x"], hud_element["start_position_y"])
		hud_nodes["cell"].position = Vector2.ZERO
		hud_nodes["short_cell"].position = Vector2.ZERO
		
		if set_value <= limit: # Set current value on active bar
			hud_nodes["cell"].size.x = set_value * hud_element["cells"]["cell_size_h"]
			hud_nodes["cell"].position.x = offset_value * hud_element["cells"]["cell_size_h"]
			hud_nodes["short_cell"].visible = false
		else:
			hud_nodes["cell"].size.x = hud_element["cells"]["cell_size_h"] * limit
			hud_nodes["short_cell"].visible = true
			hud_nodes["short_cell"].size.x = hud_element["cells"]["short_cell_size_h"] * (set_value - limit)
			hud_nodes["short_cell"].position.x = hud_element["cells"]["short_cell_size_h"] * (current_excess - (set_value - limit))
	else:
		start_position = Vector2(hud_element["start_position_x"], hud_element["start_position_y"])
		
		if set_value <= limit: # Set current value on active bar
			hud_nodes["cell"].size.x = set_value * hud_element["cells"]["cell_size_h"]
			hud_nodes["short_cell"].visible = false
		else:
			hud_nodes["cell"].size.x = hud_element["cells"]["cell_size_h"] * limit
			hud_nodes["short_cell"].visible = true
			hud_nodes["short_cell"].size.x = hud_element["cells"]["short_cell_size_h"] * (set_value - limit)
			hud_nodes["short_cell"].position.x = (start_position.x + (hud_element["cells"]["cell_size_h"] * limit)) + hud_element["position_offset"]

func update_heat(new_value, set_max : float = 0):
	heat_percentage = (new_value / bars.heat_bar.max_value) * 100
	if set_max > 0: 
		bars.heat_bar.max_value = set_max
	
	if heat_percentage > 70: heat_urgent = true
	else: heat_urgent = false
	bars.heat_bar.value = new_value

func update_hud():
	set_max_hp = Profile.current_run_data.get_value("INVENTORY", "MAX_HEALTH")
	if Profile.current_run_data.has_section_key("EFFECTS", "BONUS_AMMO"): set_max_ammo = Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO") + Profile.current_run_data.get_value("EFFECTS", "BONUS_AMMO")
	else: set_max_ammo = Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO")

func update_ui_elements():
	var score = Profile.current_run_data.get_value("STATISTICS", "SCORE")
	$HUD/Info/Elements/ScoreBar.text = "SCORE: " + str(score)

#region BARS FUNCTION PASS
func set_boss_bar(boss_node):
	bars.set_boss_bar(boss_node)

func display_event(event_data):
	bars.display_event(event_data)

func toggle_info(toggle : bool):
	if ui_animation_player.is_playing(): await ui_animation_player.animation_finished
	if toggle: ui_animation_player.play('toggle_ui')
	else: ui_animation_player.play_backwards('toggle_ui')
#endregion
