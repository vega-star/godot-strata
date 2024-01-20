extends Node2D

var enemy_load = load("res://entities/enemy_prop/enemy.tscn")
var spawn_positions = null
@onready var spawn_area = $SpawnArea

func _ready():
	randomize()

func spawn_enemy():
	var enemy = enemy_load.instantiate()
	
	var rand_position = spawn_area.position + Vector2(randf() * spawn_area.size.x, randf() * spawn_area.size.y)
	
	enemy.global_position = rand_position
	add_child(enemy)

func _on_spawn_timer_timeout():
	spawn_enemy()
