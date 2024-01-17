extends Node2D

@onready var player_spawn_pos = $PlayerSpawnPos
@onready var laser_container = $LaserContainer
@onready var hud = $UIOverlay
@onready var player_health_component = $Player/HealthComponent
@onready var gameoverscreen = $GameOver
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	assert(player!=null)
	player.global_position = player_spawn_pos.global_position
	player.laser_shot.connect(_on_player_laser_shot)
	hud.hp = player_health_component.max_health

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

func _on_player_laser_shot(laser_scene, location):
	var laser = laser_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)

func _on_player_killed():
	await get_tree().create_timer(1.5).timeout
	gameoverscreen.visible = true

func _on_player_health_change(_previous_value, new_value): # Update HP right only after change
	hud.hp = new_value
