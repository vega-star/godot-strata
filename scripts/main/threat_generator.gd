extends Node

# NODE FUNCTION: Instantiates and spawns enemies with their correct scenes and rules. 
# Can recieve a random or a specific enemy call from ThreatManager. Random calls will never be bosses or minibosses.

signal enemy_spawned(enemy_name,type)

# Enemy types:
# 0 - Single enemy
# 1 - Enemy cluster
# 2 - Mini-boss
# 3 - Boss

var debug : bool: # Inherits debug from ThreatManager var
	set(debug_toggle):
		debug = debug_toggle

@onready var full_enemy_list : Dictionary = {
	"striker_1": {"scene": "res://entities/enemy_prop/enemy.tscn", "type": 0},
	"striker_swarm_1": {"scene": "res://entities/enemy_prop/enemy.tscn", "type": 1, "rules": {"spawn_override": "center", "swarm": {"method": 0, "separation": 30, "amount": 5}}},
	"striker_swarm_2": {"scene": "res://entities/enemy_prop/enemy.tscn", "type": 1, "rules": {"spawn_override": "bottom", "swarm": {"method": 1, "separation": 50, "amount": 3}}},
	"vanguard_1": {"scene": "res://entities/enemy_prop/enemy.tscn", "type": 2},
	"vanguard_2": {"scene": "res://entities/enemy_prop/enemy.tscn", "type": 2, "rules": {"spawn_override": "center"}},
	"aegis_1": {"scene": "res://entities/enemy_prop/enemy.tscn", "type": 3, "rules": {"spawn_override": "center"}}
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

func generate_threat(enemy, rule_check : bool = false):
	var enemy_load = load(enemy_list[enemy]["scene"])
	var selected_enemy = enemy_load.instantiate()
	
	if rule_check: # Prevents error when trying to spawn an enemy event without a rule set
		var rules = enemy_list[enemy]["rules"]
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
	
	else: # No rule - Random position
		var rand_position = spawn_area.position + Vector2(randf() * spawn_area.size.x, randf() * spawn_area.size.y)
		selected_enemy.global_position = rand_position
		enemies_container.add_child(selected_enemy)
		if debug: print("Enemy %s spawned by ThreatGenerator" % enemy)
		enemy_spawned.emit(enemy,full_enemy_list[enemy]["type"])
	pass

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
		enemies_container.add_child(enemy)
		if debug: print('SWARM CONSTRUCTOR | Entity number {0} spawned on {1}'.format({0:n + 1, 1:enemy.global_position}))
