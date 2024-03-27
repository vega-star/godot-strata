extends Node2D

signal stage_started

# Stage Properties
@export var stage_id : String = "StrataScene"
@export var stage_title : String = 'STAGE ZERO'
@export var stage_description : String = 'SIMULATION'
@export var stage_ending_text : String = 'RETURNING TO MAIN MENU'
@export var next_stage_path : String = "res://scenes/ui/main_menu.tscn"
@export var save_stage_data : bool = true
@export var stage_parallax : ParallaxBackground

# Options
var config = ConfigFile.new()
var config_load = config.load("user://config.cfg")

# Node variables
@onready var player_spawn_pos = $PlayerStartPosition
@onready var player_projectile_container = $ProjectileContainer
@onready var player_health_component = $Player/HealthComponent
@onready var player : CharacterBody2D = $Player
@onready var player_camera = $StageCamera
@onready var stage_timer = $StageTimer
@onready var stage_manager = $StageManager
@onready var threat_generator = $StageManager/ThreatGenerator

# UIComponent
@onready var hud_component = UI.UIOverlay
@onready var gameoverscreen = UI.GameOver
@onready var transition_controller = UI.ScreenTransition

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
	assert(player!=null)
	
	Options.options_changed.connect(load_options)
	load_options()
	
	# player.equipment_module.ammo_changed.connect(_on_player_secondary_ammo_changed)
	player.player_killed.connect(gameoverscreen.game_over_prompt)
	
	start_stage_sequence()
	await Signal(stage_manager, "scene_loaded")

func _process(_delta): # Updates stage timer bar
	hud_component.stage_progress = stage_timer.time_left
	
	# Spawns enemies randomly
	if random_loop_active and random_loop_available:
		random_loop_available = false
		var select_random = randi() % stage_manager.stage_dict["allowed_random_enemies"].size() # Remember, this array comes from the [Stage Name]_stage.json file
		threat_generator.generate_threat(stage_manager.stage_dict["allowed_random_enemies"][select_random])
		await get_tree().create_timer(random_loop_interval, false).timeout
		random_loop_available = true

func _on_stage_timer_timeout(): # Executes when StageTimer finishes
	end_stage_sequence()

func pause_stage_timer(toggle : bool):
	stage_timer.set_paused(toggle)

func start_stage_sequence(): # Starting animations, fade-in, etc.
	hud_component.set_ammo = Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO")
	
	# Locking controls and starting animation
	var player_move_to_action = get_tree().create_tween()
	player_move_to_action.tween_property(player, "position", player_spawn_pos.global_position, 0.99)
	
	var parallax_tween = get_tree().create_tween()
	stage_parallax.speed_factor = 3
	parallax_tween.tween_property(stage_parallax, "speed_factor", 1, 3)
	
	player.controls_lock(true)
	await UI.fade('IN')
	
	UI.InfoHUD.display_title(stage_title, stage_description)
	
	await get_tree().create_timer(2, false).timeout
	
	# Unlocking controls and starting timer
	player.controls_lock(false)
	
	UI.set_stage(stage_timer, true)
	stage_started.emit()
	stage_timer.start()
	stage_start_time = Time.get_unix_time_from_system()

func end_stage_sequence(): # Fade-out, stage finished screen, etc.
	stage_final_time = Time.get_unix_time_from_system()
	
	if save_stage_data:
		save_stage_performance(stage_final_time)
	
	player.controls_lock(true)
	var player_move_to_center = get_tree().create_tween()
	player_move_to_center.tween_property(player,"global_position.x",1200, 2)
	
	UI.InfoHUD.display_title("{0} COMPLETED".format({0:stage_title}), "", 5)
	await get_tree().create_timer(2).timeout
	UI.InfoHUD.display_title("{0} COMPLETED".format({0:stage_title}), "%s" % stage_ending_text, 5)
	await get_tree().create_timer(3).timeout
	
	await UI.fade('OUT')
	LoadManager.load_scene(next_stage_path)

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
	Profile.add_run_data("STAGES", stage_id, stage_performance)

func load_options():
	config_load = config.load("user://config.cfg")
	player_camera.toggle_shake(config.get_value("MAIN_OPTIONS","SCREEN_SHAKE"))
