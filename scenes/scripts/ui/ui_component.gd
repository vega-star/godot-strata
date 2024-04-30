class_name UIComponent extends Node

## Signals
signal game_paused(mode)

## Node connections
@onready var UIOverlay = $UIOverlay
@onready var InfoHUD = $InfoHUD
@onready var PauseMenu = $PauseMenuLayer
@onready var GameOver = $GameOver
@onready var ScreenTransition = $ScreenTransitionLayer
@onready var ScreenEffect = $ScreenEffect

## Data forwarding
var stage
var fade_time : float
var stage_timer : Timer

const main_menu_path = "res://scenes/ui/main_menu.tscn"

func _ready():
	if UIOverlay.visible: UIOverlay.visible = false
	
	fade_time = ScreenTransition.fade_time

func set_stage(stage_node, timer, start_run : bool = false):
	stage = stage_node
	UIOverlay.visible = true
	stage_timer = timer
	
	if start_run: Profile.start_run()
	Profile.save_previous_data() # Sets a data checkpoint to rollback in case of retry
	
	stage.stage_ended.connect(end_stage)

func end_stage(turbo : bool = false): ## Clear cached data from stage on UI, such as events
	if stage.stage_active: # It means the end_stage_sequence has not happened
		await stage.end_stage_sequence(turbo)
	
	UI.UIOverlay.bars.clear_events()

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

