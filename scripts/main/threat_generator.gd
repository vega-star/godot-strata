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
	"striker_swarm_1": {"scene": "res://entities/enemy_prop/enemy.tscn", "type": 1, "rules": {"swarm": {"method": 0, "separation": 80, "amount": 3}, "spawn_override": "center"}},
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

@onready var spawn_area = $ScreenArea/SpawnArea
@onready var enemies_container = $"../EnemiesContainer"

func _ready():
	randomize()

func generate_threat(enemy, rule_check : bool = false):
	var enemy_load = load(enemy_list[enemy]["scene"])
	var selected_enemy = enemy_load.instantiate()
	
	if rule_check: # Prevents error when trying to spawn an enemy without a rule set
		var rules = enemy_list[enemy]["rules"]
		for r in rules: # Iterates through each rule in a match/case scenario
			match r:
				"swarm":
					var spawn_quantity = rules["swarm"]["amount"]
					if debug: print('{0} CHECK | Swarm of {1} queued'.format({0:enemy.to_upper(), 1:spawn_quantity}))
					pass
				"spawn_override":
					var spawn_override : String = rules["spawn_override"]
					if debug: print('{0} CHECK | Spawn override forced {0} to spawn in {1}'.format({0:enemy.to_upper(), 1:spawn_override}))
					selected_enemy.global_position = spawn_positions[spawn_override].global_position
	
	# if rules == "spawn_override": # Specific position
	#	var spawn_override : String = full_enemy_list[enemy]["override"]["spawn_override"]
	# 	selected_enemy.global_position = spawn_positions[spawn_override].global_position
	else: # Random position
		var rand_position = spawn_area.position + Vector2(randf() * spawn_area.size.x, randf() * spawn_area.size.y)
		selected_enemy.global_position = rand_position
	
	enemies_container.add_child(selected_enemy)
	if debug: print("Enemy %s spawned by ThreatGenerator" % enemy)
	enemy_spawned.emit(enemy,full_enemy_list[enemy]["type"])
	pass
