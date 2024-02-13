extends Node

# NODE FUNCTION: Instantiates and spawns enemies with their correct scenes and rules. 
# Can recieve a random or a specific enemy call from ThreatManager. Random calls will never be bosses or minibosses.

signal enemy_spawned(enemy_name, type)
signal challenge_completed()

var debug : bool: # Inherits debug from ThreatManager var
	set(debug_toggle):
		debug = debug_toggle

@onready var full_enemy_list : Dictionary = {
	"striker_1": {"scene": "res://entities/dummy_enemies/enemy.tscn", "type": 0},
	"striker_swarm_1": {"scene": "res://entities/dummy_enemies/enemy.tscn", "type": 1, "rules": {"spawn_override": "center", "swarm": {"method": 0, "separation": 30, "amount": 5}}},
	"striker_swarm_2": {"scene": "res://entities/dummy_enemies/enemy.tscn", "type": 1, "rules": {"spawn_override": "bottom", "swarm": {"method": 1, "separation": 50, "amount": 3}}},
	"vanguard": {"scene": "res://entities/enemies/vanguard.tscn", "type": 2, "rules": {"spawn_override": "center"}},
	"vanguard_1": {"scene": "res://entities/dummy_enemies/enemy.tscn", "type": 1},
	"vanguard_2": {"scene": "res://entities/dummy_enemies/enemy.tscn", "type": 1, "rules": {"spawn_override": "center"}},
	"aegis_1": {"scene": "res://entities/dummy_enemies/enemy.tscn", "type": 3, "rules": {"spawn_override": "center"}},
	"cargo_ship": {"scene": "res://entities/enemies/cargo-ship.tscn", "type": 1, "rules": {"spawn_override": "bottom"}}
}

@onready var enemy_list : Dictionary = full_enemy_list

@onready var spawn_positions : Dictionary = {
	"bottom": $ScreenArea/SpawnArea/BottomSpawnPos,
	"center": $ScreenArea/SpawnArea/CenterSpawnPos,
	"top": $ScreenArea/SpawnArea/TopSpawnPos
}

@onready var initial_global_position : Vector2 = Vector2.ZERO
@onready var spawn_area = $ScreenArea/SpawnArea
@onready var enemies_container = $"../EnemiesContainer"

func _ready():
	
	var rand_position = spawn_area.position + Vector2(randf() * spawn_area.size.x, randf() * spawn_area.size.y)
	initial_global_position = rand_position # Generates a random coordinate for enemies to spawn on
	
	randomize()

func generate_threat(enemy, rule_override = null):
	var enemy_load = load(enemy_list[enemy]["scene"])
	var selected_enemy = enemy_load.instantiate()
	var rules : Dictionary
	
	if rule_override: # Rules forced by events
		assert(rule_override is Dictionary)
		rules = rule_override
	elif enemy_list[enemy].size() >= 3: # Default rules inherited by enemy data
		rules = enemy_list[enemy]["rules"]
	
	if rules:
		for r in rules: # Iterates through each rule in a match/case scenario
			match r:
				"spawn_override":
					var spawn_override : String = rules["spawn_override"]
					if debug: print('{0} CHECK | Spawn override forced {0} to spawn in {1}'.format({0:enemy.to_upper(), 1:spawn_override}))
					selected_enemy.global_position = spawn_positions[spawn_override].global_position
					initial_global_position = selected_enemy.global_position
				"swarm":
					var spawn_method = rules["swarm"]["method"]
					var spawn_separation = rules["swarm"]["separation"]
					var spawn_amount = rules["swarm"]["amount"]
					if debug: print('{0} CHECK | Swarm of {1} queued in swarm_constructor'.format({0:enemy.to_upper(), 1:spawn_amount}))
					swarm_constructor(enemy_load, spawn_method, spawn_separation, spawn_amount)
	else: # No rules - Random position, random proprieties, etc.
		var rand_position = spawn_area.position + Vector2(randf() * spawn_area.size.x, randf() * spawn_area.size.y)
		selected_enemy.global_position = rand_position
	
	match enemy_list[enemy]["type"]: # Labels each enemy to a specific group. Can be useful in the future.
		0: # - Single enemy
			selected_enemy.add_to_group('enemy')
			pass
		1: # - Enemy cluster
			selected_enemy.add_to_group('enemy')
			pass
		2: # - Mini-boss
			selected_enemy.add_to_group('miniboss')
			selected_enemy.enemy_defeated.connect(_on_challenge_completed)
			pass
		3: # - Boss
			selected_enemy.add_to_group('boss')
			pass
		_:
			selected_enemy.add_to_group('unset')
			push_warning('UNSET ENEMY TYPE')
	
	enemies_container.call_deferred("add_child", selected_enemy) # Adds enemy to EnemiesContainer
	enemy_spawned.emit(enemy,full_enemy_list[enemy]["type"])

func swarm_constructor(enemy_load, method, separation, amount):
	for n in amount:
		var enemy = enemy_load.instantiate()
		enemy.global_position = initial_global_position
		match method: # Defines the format the swarm will be spawned
			0: # Vertical
				enemy.global_position.y -= separation * n
			1: # Horizontal
				enemy.global_position.x += separation * n
			2: # Random
				var rand_position = spawn_area.position + Vector2(randf() * spawn_area.size.x, randf() * spawn_area.size.y)
				enemy.global_position = rand_position
		
		enemies_container.call_deferred("add_child", enemy) # Adds enemy to EnemiesContainer

func _on_challenge_completed(): # Relays the signal to unpause timer
	challenge_completed.emit()
