extends Node2D

@onready var player_spawn_pos = $PlayerSpawnPos
@onready var player_projectile_container = $ProjectileContainer
@onready var hud = $UILayer/UIOverlay
@onready var player_health_component = $Player/HealthComponent
@onready var gameoverscreen = $GameOver
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	assert(player!=null)
	player.global_position = player_spawn_pos.global_position
	player.fire_primary.connect(_on_player_primary_fired)
	player.fire_secondary.connect(_on_player_primary_fired)
	hud.hp = player_health_component.max_health

func _on_player_primary_fired(primary_projectile_scene, location):
	var primary_shot = primary_projectile_scene.instantiate()
	primary_shot.global_position = location
	player_projectile_container.add_child(primary_shot)

func _on_player_secondary_fired(secondary_projectile_scene, location):
	var secondary_shot = secondary_projectile_scene.instantiate()
	secondary_shot.global_position = location
	player_projectile_container.add_child(secondary_shot)

func _on_player_health_change(_previous_value, new_value): # Update HP right only after change
	hud.hp = new_value
