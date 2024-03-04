class_name UIComponent extends Control

## Signals
signal game_paused(mode)

## Node connections
@onready var UIOverlay = $UIOverlay
@onready var PauseMenu = $PauseMenuLayer
@onready var GameOver = $GameOver
@onready var ScreenTransition = $ScreenTransitionLayer
@export var stage_timer : Timer

## Data forwarding
var fade_time : float

const main_menu_path = "res://scenes/ui/main_menu.tscn"

func _ready():
	if UIOverlay.visible: UIOverlay.visible = false
	
	fade_time = ScreenTransition.fade_time

func set_stage(timer):
	UIOverlay.visible = true
	UIOverlay.stage_progress_bar.visible = true
	stage_timer = timer
	Profile.save_active_data(false, true)

func set_pause(mode : bool = true):
	get_tree().paused = mode
	game_paused.emit(mode)

func fade(mode):
	# ScreenTransition.fade(mode)
	match mode:
		0, 'IN':
			ScreenTransition.visible = true
			ScreenTransition.fade(mode)
			await get_tree().create_timer(fade_time).timeout
			ScreenTransition.visible = false
		1, 'OUT':
			ScreenTransition.visible = true
			ScreenTransition.fade(mode)
			await get_tree().create_timer(fade_time).timeout
			ScreenTransition.visible = false


