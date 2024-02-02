extends Control

# Path variables

@onready var stage_progress_bar = $UILayer/HUD/StageProgressBar

# HUD Constructor Values

@export var limit_normal_hp_slots = 3
@export var limit_normal_bomb_slots = 5
const hp_cell_size : int = 52
const bomb_cell_size : int = 22
var hp_cell_size_defined : bool = false
var bomb_counter_frame_defined : bool = false

@onready var start_bar_size = $UILayer/HP_Bar/HP_Bar_Start.size.x

@onready var hp = $UILayer/HUD/HP_Container:
	set(hp_value):
		if hp_cell_size_defined == false:
			if hp_value <= 3: # Set correct MAX HP bar size
				$UILayer/HP_Bar/HP_Bar_Module.size.x = hp_cell_size * hp_value
				$UILayer/HP_Bar/HP_Bar_End.position.x =  start_bar_size + $UILayer/HP_Bar/HP_Bar_Module.size.x
				hp_cell_size_defined = true
			else: # Set excess HP to smaller modules
				$UILayer/HP_Bar/HP_Bar_Module.size.x = hp_cell_size * limit_normal_hp_slots
				$UILayer/HP_Bar/HP_Bar_Short_Module.visible = true
				$UILayer/HP_Bar/HP_Bar_Short_Module.position.x =  start_bar_size + $UILayer/HP_Bar/HP_Bar_Module.size.x
				$UILayer/HP_Bar/HP_Bar_Short_Module.size.x = (hp_cell_size / 2) * (hp_value - limit_normal_hp_slots)
				$UILayer/HP_Bar/HP_Bar_End.position.x =  start_bar_size + $UILayer/HP_Bar/HP_Bar_Module.size.x + $UILayer/HP_Bar/HP_Bar_Short_Module.size.x
				hp_cell_size_defined = true
		
		if hp_value <= limit_normal_hp_slots: # Set current HP
			hp.size.x = hp_value * hp_cell_size
			$UILayer/HUD/HP_Short_Container.visible = false
		else:
			hp.size.x = hp_cell_size * limit_normal_hp_slots
			$UILayer/HUD/HP_Short_Container.visible = true
			$UILayer/HUD/HP_Short_Container.size.x = (hp_cell_size / 2) * (hp_value - limit_normal_hp_slots)
			$UILayer/HUD/HP_Short_Container.position.x =  start_bar_size + $UILayer/HP_Bar/HP_Bar_Module.size.x

@onready var bomb_counter = $UILayer/HUD/Bomb_Container:
	set(bomb_count):
		bomb_counter.size.x = bomb_count * bomb_cell_size
		if bomb_counter_frame_defined == false:
			if bomb_counter.size.x <= bomb_cell_size * limit_normal_bomb_slots: # Set correct MAX BOMB slots
				$UILayer/Bomb_Count_Frame/Bomb_Module.size.x = bomb_cell_size * bomb_count
				bomb_counter_frame_defined = true
			else:
				$UILayer/Bomb_Count_Frame/Bomb_Module.size.x = bomb_cell_size * limit_normal_bomb_slots
				$UILayer/Bomb_Count_Frame/Short_Bomb_Module.visible = true
				$UILayer/Bomb_Count_Frame/Short_Bomb_Module.size.x = (bomb_cell_size / 2) * (bomb_count - limit_normal_bomb_slots)
				$UILayer/Bomb_Count_Frame/Short_Bomb_Module.position.x = $UILayer/Bomb_Count_Frame/Bomb_Module.position.x + $UILayer/Bomb_Count_Frame/Bomb_Module.size.x
				bomb_counter_frame_defined = true
		
		if bomb_count <= limit_normal_bomb_slots: # Set current HP
			bomb_counter.size.x = bomb_count * bomb_cell_size
			$UILayer/HUD/Bomb_Short_Container.visible = false
		else:
			bomb_counter.size.x = bomb_cell_size * limit_normal_bomb_slots
			$UILayer/HUD/Bomb_Short_Container.visible = true
			$UILayer/HUD/Bomb_Short_Container.size.x = (bomb_cell_size / 2) * (bomb_count - limit_normal_bomb_slots)
			$UILayer/HUD/Bomb_Short_Container.position.x = 9 + $UILayer/Bomb_Count_Frame/Bomb_Module.position.x + $UILayer/Bomb_Count_Frame/Bomb_Module.size.x

@onready var stage_progress = stage_progress_bar:
	set(progress_value):
		stage_progress_bar.value = progress_value

func _ready():
	stage_progress_bar.set_max($"../../ThreatManager".stage_length_in_minutes * 60)
	print("PROGRESS BAR SIZE: %f" % stage_progress_bar.max_value)
