extends Node

# NODE FUNCTION: Instantiates and spawns enemies with their correct scenes and rules. 
# Can recieve a random or a specific enemy call from ThreatManager. Random calls will never be bosses or minibosses.

signal enemy_spawned(enemy_name, type)
signal enemy_loaded
signal challenge_completed()

var use_sub_threads : bool = true
var loaded_entity : PackedScene
var entity_scene_path : String
var entity_loading : bool = false
var entity_load_progress : Array = []

var danger_player = UI.InfoHUD.danger_player
var rotation_angle : float = 0
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
	"top_forward": $ScreenArea/SpawnAreaForward/TopSpawnPos,
	"far_top": $ScreenArea/SpawnArea/FarTop,
	"far_bottom": $ScreenArea/SpawnArea/FarBottom
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
	
	set_process(false)

func _process(delta):
	var load_status = ResourceLoader.load_threaded_get_status(entity_scene_path, entity_load_progress)
	match load_status:
		0, 2: #? THREAD_LOAD_INVALID_RESOURCE, THREAD_LOAD_FAILED
			set_process(false)
			printerr("ERROR LOADING SCENE | Scene path may be wrong or invalid")
			return
		1: #? THREAD_LOAD_IN_PROGRESS
			emit_signal("progress_changed", entity_load_progress[0])
		3: #? THREAD_LOAD_LOADED
			loaded_entity = ResourceLoader.load_threaded_get(entity_scene_path)
			emit_signal("enemy_loaded")
			set_process(false)

func generate_threat(enemy, rule_override = null):
	## Main variables
	var rules : Dictionary
	var container = enemies_container
	var invoke_challenge : bool = false
	
	## Start
	entity_scene_path = enemy_dict[enemy]["scene"]
	var state = ResourceLoader.load_threaded_request(entity_scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)
	else:
		printerr("ERROR REQUESTING SCENE | Scene path may be wrong or invalid")
		return
	
	await enemy_loaded
	var selected_enemy = loaded_entity.instantiate()
	
	if rule_override: # Rules forced by events
		assert(rule_override is Dictionary)
		rules = rule_override
	elif enemy_dict[enemy]["contain_rules"]: # Default rules inherited by enemy data
		rules = enemy_dict[enemy]["rules"]
	
	if rules:
		for r in rules: # Iterates through each rule in a match/case scenario
			var rule_property = rules[r]
			match r:
				"property_override": #? - Recieves a dictionary with properties and their respective values. 
					#! - If the dictionary comes from a JSON file, it will not be compatible with certain Godot types such as Vector2.
					assert(rule_property is Dictionary)
					for p in rule_property:
						var value = rule_property[p]
						selected_enemy.set_deferred(p, value)
				"spawn_override": #? - Either sets spawn on a predefined position or area, or receives a Vector2 coordinate
					if rule_property is Vector2:
						selected_enemy.global_position = rule_property
						initial_global_position = selected_enemy.global_position
					if rule_property is String:
						selected_enemy.global_position = spawn_positions[rule_property].global_position
						initial_global_position = selected_enemy.global_position
				"rotated":
					rotation_angle = rule_property
					selected_enemy.set_rotation_degrees(rule_property)
				"notify_danger":
					print('notifying danger')
					var modulate_color : Color = Color.WHITE
					UI.InfoHUD.display_danger(
						rule_property["direction"],
						rule_property["horizontal"],
						rule_property["timeout"],
						modulate_color
					)
				"swarm":
					swarm_constructor(
						loaded_entity,
						rule_property["method"],
						rule_property["separation"], 
						rule_property["amount"], 
						rule_property["delay"]
					)
					return # Prevents spawning of an additional enemy that is not present in the swarm itself
				"challenge":
					invoke_challenge = rule_property
				"container_override":
					container = rule_property
				"set_boss_bar":
					UI.UIOverlay.set_boss_bar(selected_enemy)
				_:
					print('Unmatched rule detected: %s' % r)
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
	
	if invoke_challenge:
		selected_enemy.enemy_defeated.connect(_on_challenge_completed)
	
	container.call_deferred("add_child", selected_enemy)
	enemy_spawned.emit(enemy,enemy_dict[enemy]["type"])
	return selected_enemy

func swarm_constructor(enemy_load, method, separation, amount, delay = 0):
	for n in amount:
		var enemy = enemy_load.instantiate()
		enemy.set_rotation_degrees(rotation_angle)
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
			await get_tree().create_timer(delay).timeout
		
		enemies_container.call_deferred("add_child", enemy) # Adds enemy to EnemiesContainer
	
	## Reset previous values
	rotation_angle = 0

func _on_challenge_completed(): # Relays the signal to unpause timer
	challenge_completed.emit()
