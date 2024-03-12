extends Node

# NODE FUNCTION: Instantiates and spawns enemies with their correct scenes and rules. 
# Can recieve a random or a specific enemy call from ThreatManager. Random calls will never be bosses or minibosses.

signal enemy_spawned(enemy_name, type)
signal challenge_completed()

var danger_player = UI.InfoHUD.danger_player

var debug : bool: # Inherits debug from ThreatManager var
	set(debug_toggle):
		debug = debug_toggle

const enemy_data = "res://data/enemy_data.json"
@onready var enemy_dict : Dictionary

@onready var spawn_positions : Dictionary = {
	"bottom": $ScreenArea/SpawnArea/BottomSpawnPos,
	"center": $ScreenArea/SpawnArea/CenterSpawnPos,
	"top": $ScreenArea/SpawnArea/TopSpawnPos,
	"bottom_forward": $ScreenArea/SpawnAreaForward/BottomSpawnPos,
	"center_forward": $ScreenArea/SpawnAreaForward/CenterSpawnPos,
	"top_forward": $ScreenArea/SpawnAreaForward/TopSpawnPos
}

@onready var initial_global_position : Vector2 = Vector2.ZERO
@onready var spawn_area = $ScreenArea/SpawnArea
@onready var enemies_container = $"../EnemiesContainer"

func _ready():
	randomize()
	var rand_position = spawn_area.position + Vector2(randf() * spawn_area.size.x, randf() * spawn_area.size.y)
	initial_global_position = rand_position # Generates a random coordinate for enemies to spawn on
	
	assert(FileAccess.file_exists(enemy_data))
	
	var load_enemy_data = FileAccess.open(enemy_data, FileAccess.READ)
	enemy_dict = JSON.parse_string(load_enemy_data.get_as_text())
	assert(enemy_dict is Dictionary)

func generate_threat(enemy, rule_override = null):
	var enemy_load = load(enemy_dict[enemy]["scene"])
	var selected_enemy = enemy_load.instantiate()
	var rules : Dictionary
	var challenge : bool
	
	if rule_override: # Rules forced by events
		assert(rule_override is Dictionary)
		rules = rule_override
	elif enemy_dict[enemy]["contain_rules"]: # Default rules inherited by enemy data
		rules = enemy_dict[enemy]["rules"]
	
	if rules:
		for r in rules: # Iterates through each rule in a match/case scenario
			var rule_property = rules[r]
			match r:
				"spawn_override":
					var spawn_override : String = rule_property
					if debug: print('{0} CHECK | Spawn override forced {0} to spawn in {1}'.format({0:enemy.to_upper(), 1:spawn_override}))
					selected_enemy.global_position = spawn_positions[spawn_override].global_position
					initial_global_position = selected_enemy.global_position
				"notify_danger":
					var modulate_color : Color = Color.WHITE
					var timeout : float = 4
					danger_player.display_danger(rule_property, timeout, modulate_color)
				"swarm":
					var spawn_method = rule_property["method"]
					var spawn_separation = rule_property["separation"]
					var spawn_amount = rule_property["amount"]
					var spawn_delay = rule_property["delay"]
					if debug: print('{0} CHECK | Swarm of {1} queued in swarm_constructor, using method {2}'.format({0:enemy.to_upper(), 1:spawn_amount, 2:spawn_method}))
					swarm_constructor(enemy_load, spawn_method, spawn_separation, spawn_amount, spawn_delay)
				"challenge":
					if debug: print('Challenge initialized')
					challenge = rule_property
	else: # No rules - Random position, random proprieties, etc.
		var rand_position = spawn_area.position + Vector2(randf() * spawn_area.size.x, randf() * spawn_area.size.y)
		selected_enemy.global_position = rand_position
	
	match enemy_dict[enemy]["type"]: # Labels each enemy to a specific group. Can be useful in the future.
		0: selected_enemy.add_to_group('enemy')
		1: selected_enemy.add_to_group('enemy')
		2: selected_enemy.add_to_group('composite_enemy')
		3: selected_enemy.add_to_group('miniboss')
		4: selected_enemy.add_to_group('boss') 
		_: selected_enemy.add_to_group('unset')
	
	if challenge:
		selected_enemy.enemy_defeated.connect(_on_challenge_completed)
	
	enemies_container.call_deferred("add_child", selected_enemy) # Adds enemy to EnemiesContainer
	enemy_spawned.emit(enemy,enemy_dict[enemy]["type"])

func swarm_constructor(enemy_load, method, separation, amount, delay = 0):
	for n in amount:
		var enemy = enemy_load.instantiate()
		enemy.global_position = initial_global_position
		match int(method): # Defines the format the swarm will be spawned
			0: # Vertical
				enemy.global_position.y -= separation * n
			1: # Horizontal
				enemy.global_position.x += separation * n
			2: # Random
				var rand_position = spawn_area.position + Vector2(randf() * spawn_area.size.x, randf() * spawn_area.size.y)
				enemy.global_position = rand_position
			_:
				print('No method for swarm spawning, they will spawn on top of each other')
		if delay > 0:
			print(amount, delay)
			await get_tree().create_timer(delay).timeout
		enemies_container.call_deferred("add_child", enemy) # Adds enemy to EnemiesContainer

func _on_challenge_completed(): # Relays the signal to unpause timer
	challenge_completed.emit()
