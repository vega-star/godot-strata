class_name UIComponent extends Node

## Signals
signal stage_set
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

func set_stage(stage_node, timer):
	stage = stage_node
	UIOverlay.visible = true
	UIOverlay.toggle_info(true)
	stage_timer = timer
	
	stage.stage_ended.connect(end_stage)
	stage_set.emit()

func end_stage(turbo : bool = false): ## Clear cached data from stage on UI, such as events
	if !is_instance_valid(stage): 
		# The stage was freed and this function is being called for the second time. 
		# It will clear events again, but will not call end_stage_sequence.
		UI.UIOverlay.bars.clear_events()
		return
	
	if stage.stage_active: 
		# The stage is ending early and end_stage_sequence has not happened yet, will call immediately with turbo
		# Turbo means it will skip custcenes and other sequences and finish everything it needs to
		await stage.end_stage_sequence(turbo)
	
	UIOverlay.bars.clear_events()
	UIOverlay.toggle_info(false)
	UIOverlay.visible = false

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

