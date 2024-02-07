extends Node2D

# Node variables
@onready var player_spawn_pos = $PlayerSpawnPos
@onready var player_projectile_container = $ProjectileContainer
@onready var player_health_component = $Player/HealthComponent
@onready var hud_component = $UILayer/UIOverlay
@onready var gameoverscreen = $GameOver
@onready var player = $Player
@onready var stage_timer = $StageTimer
@onready var threat_manager = $ThreatManager

# Transition component
@onready var transition_controller = $ScreenTransitionLayer
@onready var transition_time = transition_controller.fade_time

# Signals
@onready var is_timer_paused = false
signal timer_pause

func _ready():
	transition_controller.visible = true
	assert(player!=null)
	
	player.global_position = player_spawn_pos.global_position
	
	hud_component.hp = player_health_component.max_health
	hud_component.secondary_ammo_counter = player.equipment_module.max_secondary_ammo
	
	player.equipment_module.ammo_changed.connect(_on_player_secondary_ammo_changed)
	
	await threat_manager.scene_loaded
	await get_tree().create_timer(transition_time).timeout
	transition_controller.visible = false

func _on_player_health_change(_previous_value, new_value): # Update HP right only after change
	hud_component.hp = new_value

func _on_player_secondary_ammo_changed(current_ammo, _previous_ammo):
	hud_component.secondary_ammo_counter = current_ammo

func _on_timer_pause(): # Timer switch
	if is_timer_paused: is_timer_paused = false
	else: is_timer_paused = true

func _on_stage_timer_timeout(): # Stage finished listener
	end_stage_sequence()

func _process(_delta):
	if !is_timer_paused:
		hud_component.stage_progress = stage_timer.time_left

func end_stage_sequence():
	player.lock_controls.emit()
	var player_move_to_center = get_tree().create_tween()
	player_move_to_center.tween_property(player,"position.x",600, 0.95)
	
	$ScreenTransitionLayer.visible = true
	$ScreenTransitionLayer/StageCompleted.visible = true
	
	await get_tree().create_timer(transition_time).timeout
	$ScreenTransitionLayer/ScreenTransition.visible = true
	transition_controller.fade('out')
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

