extends CanvasLayer

#region MAIN VARIABLES
## Properties
@export var selected_health_skin = "classic_hp"
@export var selected_ammo_skin = "classic_ammo"
@export var limit_hp_slots = 3
@export var limit_secondary_ammo = 7
@export var debug : bool = false

## Nodes
@onready var ui_animation_player = $UIAnimations
@onready var heat_bar = $HeatBar
@onready var bars = $Bars
@onready var stage_progress_bar = $Bars/StageProgressBar/Bar

## HUD Constructor Data
@onready var hud_elements_list : Dictionary = {
	"main_nodes": {
		"hp": {
			"container": $HP/HP_Container,
			"short_container": $HP/HP_Short_Container,
			"cell": $HUD/HP_Cells,
			"short_cell": $HUD/HP_Short_Cells,
			"start": $HP/HP_Start,
			"end": $HP/HP_End
		},
		"ammo": {
			"container": $SecondaryAmmo/Ammo_Container,
			"short_container": $SecondaryAmmo/Ammo_Short_Container,
			"cell": $HUD/Ammo_Cells,
			"short_cell": $HUD/Ammo_Short_Cells,
			"start": null,
			"end": null
		}
	},
	"classic_hp": {
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
	"classic_ammo": {
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
	"diamond_hp": {
		"type": 0, # HP
		"start_position_x": 8,
		"start_position_y": 8,
		"position_offset": 0,
		"has_end_sprite": false,
		"has_start_sprite": false,
		"sprites": {
			"cell_sprite_path": "res://assets/textures/ui/hud/diamond/diamond_cell.png",
			"short_cell_sprite_path": "res://assets/textures/ui/hud/diamond/diamond_short_cell.png",
			"container_sprite_path": "res://assets/textures/ui/hud/diamond/diamond_container.png",
			"short_container_sprite_path": "res://assets/textures/ui/hud/diamond/diamond_short_container.png"
		},
		"containers": {
			"container_size_h": 22,
			"container_size_y": 28,
			"short_container_size_h": 12,
			"short_container_size_y": 28
		},
		"cells": {
			"cell_size_h": 22,
			"cell_size_y": 28,
			"short_cell_size_h": 12,
			"short_cell_size_y": 28
		}
	}
}

## HP
@onready var set_hp:
	set(hp):
		adapt_hud(hud_elements_list[selected_health_skin], "hp", hp, limit_hp_slots)
@onready var set_max_hp:
	set(max_hp):
		construct_hud(hud_elements_list[selected_health_skin], "hp", max_hp, limit_hp_slots)

## Ammo
@onready var set_ammo:
	set(ammo):
		adapt_hud(hud_elements_list[selected_ammo_skin], "ammo", ammo, limit_secondary_ammo)
@onready var set_max_ammo:
	set(max_ammo):
		construct_hud(hud_elements_list[selected_ammo_skin], "ammo", max_ammo, limit_secondary_ammo)

## Stage bar
@onready var stage_progress = stage_progress_bar: # Recieves and updates stage progress on hud bar
	set(progress_value):
		stage_progress_bar.value = progress_value
#endregion

const heat_bar_factor : int = 25

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
		heat_bar.set_over_texture(heat_bar_danger)
		await get_tree().create_timer(heat_bar_factor / heat_percentage).timeout
		heat_bar.set_over_texture(null)
		await get_tree().create_timer(heat_bar_factor / heat_percentage).timeout
		heating_alert = false

func set_stage_bar(max_value): ## Sets the progress bar max value equal to the StageTimer total time in seconds
	stage_progress_bar.set_max(max_value)
	stage_size = max_value

func construct_hud(hud_element, type, set_value, limit):
	## Building the containers
	# Containers are positioned over or behind bars and are just cosmetic. They aren't supposed to change much during a stage
	# However, they need to change if the player catches an empty HP container to raise its max HP, so an update_hud function to switch the boolean below works just fine.
	var hud_nodes = hud_elements_list["main_nodes"][type]
	var start_position = Vector2(hud_element["start_position_x"], hud_element["start_position_y"])
	var has_end_sprite : bool = hud_element["has_end_sprite"]
	var has_start_sprite : bool = hud_element["has_start_sprite"]
	
	if !has_end_sprite:
		if hud_nodes["end"]:
			hud_nodes["end"].visible = false
	if !has_start_sprite:
		if hud_nodes["start"]:
			hud_nodes["start"].visible = false
	
	## Configuring TextureRect nodes
	hud_nodes["container"].set_texture(load(hud_element["sprites"]["container_sprite_path"]))
	hud_nodes["container"].size = Vector2(0,0)
	hud_nodes["container"].set_custom_minimum_size(Vector2(
		hud_element["containers"]["container_size_h"],
		hud_element["containers"]["container_size_y"])
	)
	hud_nodes["short_container"].set_texture(load(hud_element["sprites"]["short_container_sprite_path"]))
	hud_nodes["short_container"].size = Vector2(0,0)
	hud_nodes["short_container"].set_custom_minimum_size(Vector2(
		hud_element["containers"]["short_container_size_h"],
		hud_element["containers"]["short_container_size_y"])
	)
	
	hud_nodes["cell"].set_texture(load(hud_element["sprites"]["cell_sprite_path"]))
	hud_nodes["cell"].set_custom_minimum_size(Vector2(
		0,
		hud_element["cells"]["short_cell_size_y"])
	)
	hud_nodes["short_cell"].set_texture(load(hud_element["sprites"]["short_cell_sprite_path"]))
	hud_nodes["short_cell"].set_custom_minimum_size(Vector2(
		0,
		hud_element["cells"]["short_cell_size_y"])
	)
	
	## Adapting size, position and visibility
	hud_nodes["container"].set_position(start_position)
	if has_start_sprite: hud_nodes["cell"].set_position(start_position)
	
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
	
func adapt_hud(hud_element, type, set_value, limit):
	var hud_nodes = hud_elements_list["main_nodes"][type]
	var start_position = Vector2(hud_element["start_position_x"], hud_element["start_position_y"])
	
	if set_value <= limit: # Set current value on active bar
		hud_nodes["cell"].size.x = set_value * hud_element["cells"]["cell_size_h"]
		hud_nodes["short_cell"].visible = false
	else:
		hud_nodes["cell"].size.x = hud_element["cells"]["cell_size_h"] * limit
		hud_nodes["short_cell"].visible = true
		hud_nodes["short_cell"].size.x = hud_element["cells"]["short_cell_size_h"] * (set_value - limit)
		hud_nodes["short_cell"].position.x = (start_position.x + (hud_element["cells"]["cell_size_h"] * limit)) + hud_element["position_offset"]

func update_heat(new_value, set_max : float = 0):
	heat_percentage = (new_value / heat_bar.max_value) * 100
	if set_max > 0: 
		heat_bar.max_value = set_max
	
	if heat_percentage > 70: heat_urgent = true
	else: heat_urgent = false
	heat_bar.value = new_value

func update_hud():
	set_max_hp = Profile.current_run_data.get_value("INVENTORY", "MAX_HEALTH")
	if Profile.current_run_data.has_section_key("EFFECTS", "BONUS_AMMO"):
		set_max_ammo = Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO") + Profile.current_run_data.get_value("EFFECTS", "BONUS_AMMO")
	else:
		set_max_ammo = Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO")

func update_ui_elements():
	var score = Profile.current_run_data.get_value("STATISTICS", "SCORE")
	$ScoreBar.text = "SCORE: " + str(score)

#region BARS FUNCTION PASS
func set_boss_bar(boss_node):
	bars.set_boss_bar(boss_node)

func display_event(event_data):
	bars.display_event(event_data)
#endregion
