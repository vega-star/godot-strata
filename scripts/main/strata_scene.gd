extends Node2D

# Node variables
@onready var player_spawn_pos = $PlayerSpawnPos
@onready var player_projectile_container = $ProjectileContainer
@onready var hud = $UILayer/UIOverlay
@onready var player_health_component = $Player/HealthComponent
@onready var gameoverscreen = $GameOver
@onready var player = $Player
@onready var stage_timer = $StageTimer
@onready var transition_controller = $ScreenTransitionLayer
@onready var transition_time = transition_controller.fade_time
@onready var threat_manager = $ThreatManager

# Stage Timer
@export var stage_time_in_minutes : float = 3
@onready var stage_time_in_seconds : float = stage_time_in_minutes * 60

# Signals
@onready var is_timer_paused = false
signal timer_pause

func _ready():
	assert(player!=null)
	
	player.global_position = player_spawn_pos.global_position
	player.fire_primary.connect(_on_player_primary_fired)
	player.fire_secondary.connect(_on_player_secondary_fired)
	
	hud.hp = player_health_component.max_health
	hud.bomb_counter = $Player.secondary_ammo
	
	# Stage Timer Start
	hud.stage_start_time = stage_time_in_seconds
	stage_timer.wait_time = stage_time_in_seconds
	stage_timer.start()
	
	await get_tree().create_timer(transition_time).timeout
	$ScreenTransitionLayer.visible = false
	$ScreenTransitionLayer/ScreenTransition.visible = false

func _on_player_primary_fired(primary_projectile_scene, location):
	var primary_shot = primary_projectile_scene.instantiate()
	primary_shot.global_position = location
	player_projectile_container.add_child(primary_shot)

func _on_player_secondary_fired(secondary_projectile_scene, location, secondary_ammo):
	var secondary_shot = secondary_projectile_scene.instantiate()
	secondary_shot.global_position = location
	player_projectile_container.add_child(secondary_shot)
	hud.bomb_counter = secondary_ammo - 1

func _on_player_health_change(_previous_value, new_value): # Update HP right only after change
	hud.hp = new_value

func _on_timer_pause(): # Timer switch
	if is_timer_paused: is_timer_paused = false
	else: is_timer_paused = true

func _on_stage_timer_timeout(): # Stage finished listener
	end_stage_sequence()

func _process(delta):
	threat_manager.schedule_time = stage_timer.time_left
	
	if !is_timer_paused:
		hud.stage_progress = stage_timer.time_left

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
