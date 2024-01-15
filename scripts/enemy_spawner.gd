extends Node2D

var enemy_load = load("res://entities/enemy_prop/enemy.tscn")
var spawn_positions = null

func _ready():
	randomize()
	spawn_positions = $SpawnPositions.get_children()

func spawn_enemy():
	var index = randi() % spawn_positions.size()
	var enemy = enemy_load.instantiate()
	enemy.global_position = spawn_positions[index].global_position
	add_child(enemy)

func _on_spawn_timer_timeout():
	spawn_enemy()
