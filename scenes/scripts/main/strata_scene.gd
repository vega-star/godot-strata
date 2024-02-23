extends Node2D

signal stage_started

# Stage Properties
@export var stage_name : String = "StrataScene"

# Options
var config = ConfigFile.new()
var config_load = config.load("user://config.cfg")

# Node variables
@onready var player_spawn_pos = $PlayerSpawnPos
@onready var player_projectile_container = $ProjectileContainer
@onready var player_health_component = $Player/HealthComponent
@onready var player : CharacterBody2D = $Player
@onready var player_camera = $StageCamera
@onready var stage_timer = $StageTimer
@onready var stage_manager = $StageManager
@onready var threat_generator = $StageManager/ThreatGenerator

# UIComponent
@onready var hud_component = $UIComponent/UIOverlay
@onready var gameoverscreen = $UIComponent/GameOver
@onready var transition_controller = $UIComponent/ScreenTransitionLayer
@onready var transition_time = transition_controller.fade_time

# Profile
var stage_start_time
var stage_elapsed_time
var stage_final_time

# Loop controllers
var random_loop_available : bool = true
var random_loop_interval : float
var random_loop_active : bool
@onready var set_random_loop:
	set(value):
		random_loop_active = value
@onready var set_random_loop_interval:
	set(value):
		random_loop_interval = value

func _ready():
	transition_controller.visible = true
	assert(player!=null)
	
	Options.options_changed.connect(load_options)
	load_options()
	
	hud_component.hp = player_health_component.max_health
	hud_component.secondary_ammo_counter = player.equipment_module.max_secondary_ammo
	
	player.equipment_module.ammo_changed.connect(_on_player_secondary_ammo_changed)
	player.player_killed.connect(gameoverscreen.game_over_prompt)
	
	start_stage_sequence()
	await stage_manager.scene_loaded
	
	await get_tree().create_timer(transition_time).timeout
	transition_controller.visible = false

func _process(_delta): # Updates stage timer bar
	hud_component.stage_progress = stage_timer.time_left
	
	# Spawns enemies randomly
	if random_loop_active and random_loop_available:
		random_loop_available = false
		var select_random = randi() % stage_manager.stage_dict["allowed_random_enemies"].size() # Remember, this array comes from the [Stage Name]_stage.json file
		threat_generator.generate_threat(stage_manager.stage_dict["allowed_random_enemies"][select_random])
		await get_tree().create_timer(random_loop_interval, false).timeout
		random_loop_available = true

func _on_player_health_change(_previous_value, new_value): # Update HP right only after change
	hud_component.hp = new_value

func _on_player_secondary_ammo_changed(current_ammo, _previous_ammo):
	hud_component.secondary_ammo_counter = current_ammo

func _on_stage_timer_timeout(): # Executes when StageTimer finishes
	end_stage_sequence()

func pause_stage_timer(toggle : bool):
	stage_timer.set_paused(toggle)

func start_stage_sequence(): # Starting animations, fade-in, etc.
	
	# Locking controls and starting animation
	var player_move_to_action = get_tree().create_tween()
	player_move_to_action.tween_property(player, "position", $PlayerSpawnPos.global_position, 0.99)
	
	player.controls_lock(true)
	await get_tree().create_timer(2).timeout
	
	# Unlocking controls and starting timer
	player.controls_lock(false)
	
	$UIComponent/UIOverlay/ProgressBar.visible = true
	
	stage_started.emit()
	stage_timer.start()
	
	stage_start_time = Time.get_unix_time_from_system()

func end_stage_sequence(): # Fade-out, stage finished screen, etc.
	stage_final_time = Time.get_unix_time_from_system()
	
	save_stage_performance(stage_final_time)
	
	var stage_time = int(stage_final_time - stage_start_time)
	var time_sec = stage_time % 60
	var time_min = (stage_time/60) % 60
	var time_h = (stage_time/60)/60
	
	var time_diff =  "%02d:%02d:%02d" % [time_h, time_min, time_sec]
	
	player.switch_controls_lock.emit()
	var player_move_to_center = get_tree().create_tween()
	player_move_to_center.tween_property(player,"global_position.x",1200, 0.95)
	
	$UIComponent/ScreenTransitionLayer.visible = true
	$UIComponent/ScreenTransitionLayer/StageCompleted.visible = true
	
	await get_tree().create_timer(transition_time).timeout
	$UIComponent/ScreenTransitionLayer/ScreenTransition.visible = true
	transition_controller.fade('out')
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func save_stage_performance(final_time):
	var stage_time = int(final_time - stage_start_time)
	var time_sec = stage_time % 60
	var time_min = (stage_time/60) % 60
	var time_h = (stage_time/60)/60
	
	var time_diff =  "%02d:%02d:%02d" % [time_h, time_min, time_sec]
	
	var stage_performance : Dictionary = {
		"ITEMS_COLLECTED_AT_STAGE": ["Item1","Item2"],
		"TIME_ELAPSED_AT_STAGE": time_diff
	}
	Profile.add_run_data("STAGES", stage_name, stage_performance)

func load_options():
	config_load = config.load("user://config.cfg")
	player_camera.toggle_shake(config.get_value("MAIN_OPTIONS","SCREEN_SHAKE"))
