class_name ThreatManager extends Node

# NODE FUNCTION: Contains and orchestrates a schedule of events that will happen in a stage. 
# In the future, the ThreatManager will send data to a radar informing the player of certain events like boss-fights. 
# The stage timer is intended to be guide which events are generated. Each stage should have one of these nodes.

signal boss_killed(boss_name,battle_time)
signal enemy_spawned(enemy_name,type)
signal event_completed(event_name,event_type)
signal scene_loaded()

# Each stage should also have a configuration file that loads before the events and sets certain parameters to other processes
var stage_scene : String = ""
var stage_allowed_random_enemies : Array = []
var stage_length_in_minutes : float = 0.0
var final_stage : bool = false

@onready var stage_timer = $"../StageTimer"
@onready var threat_generator = $ThreatGenerator
@onready var current_stage = owner.get_name()
@export var debug : bool = false
var stage_timer_toggled : bool = false
var timer_period_expired : bool = false

func call_threat(enemy, rule_check : bool = false):
	threat_generator.generate_threat(enemy, rule_check)

func _ready():
	randomize()
	
	if debug:
		threat_generator.debug = true
		print("ThreatManager located in %s with debug active" % current_stage)
	var raw_events_file : String = "res://stages/schedules/{0}_events.json".format({0:current_stage})
	var raw_stage_file : String = "res://stages/schedules/{0}_stage.json".format({0:current_stage})
	
	await load_stage_file(raw_stage_file)
	load_events_file(raw_events_file)


func _on_threat_spawned_relay(enemy_name, type):
	enemy_spawned.emit(enemy_name,type)

func load_stage_file(file_path):
	assert(FileAccess.file_exists(file_path))
	var load_stage_info = FileAccess.open(file_path, FileAccess.READ)
	var stage_info = JSON.parse_string(load_stage_info.get_as_text())
	assert(stage_info is Dictionary)
	stage_scene = stage_info["stage_scene"]
	stage_allowed_random_enemies = stage_info["allowed_random_enemies"]
	stage_length_in_minutes = stage_info["stage_length_in_minutes"]
	final_stage = stage_info["final_stage"]
	var stage_length_in_seconds = stage_length_in_minutes * 60
	
	stage_timer.set_wait_time(stage_length_in_seconds)
	stage_timer.start()
	if debug: print("STAGE_TIMER STARTED WITH A TOTAL OF {0} SECONDS | PAUSED/STOPPED: {1}/{2}".format({0:stage_length_in_seconds, 1:stage_timer.paused, 2:stage_timer.is_stopped()}))
	scene_loaded.emit()

func load_events_file(file_path): # Loads a json and turns it into a dictionary
	assert(FileAccess.file_exists(file_path))
	var load_events_schedule = FileAccess.open(file_path, FileAccess.READ)
	var events_schedule = JSON.parse_string(load_events_schedule.get_as_text())
	assert(events_schedule is Dictionary)
	load_events(events_schedule)

func load_events(events_schedule): # Iterates through each event
	for event in events_schedule:
		await execute_event(events_schedule[event], event) # The 'await' functions guarantees events will follow a timed sequence

func execute_event(event, event_name = "UNNAMED EVENT"):
	var timer_period_expired = false
	if debug:
		print("{0} LOADED | TYPE: {1}\nDESCRIPTION: {2}".format({0:event_name,1:event["event_type"],2:event["event_description"]}))
	
	# "filler":
	#				var filler = $"../StageTimer".get_time_left() - float(event["event_properties"]["stop_before"])
	#				print('FILLER GENERATED | Filler timer/Real time remaining: {0}/{1}'.format({0:filler,1:$"../StageTimer".get_time_left()}))
	
	if event["event_properties"]["set_timer"] == true: # Locks event duration to a timer
		set_event_timer(event)
	
	match event["event_type"]:
		"random_period":
			var spawn_cooldown = false 
			while !timer_period_expired and !spawn_cooldown:
				spawn_cooldown = true
				var select_random = randi() % stage_allowed_random_enemies.size()
				threat_generator.generate_threat(stage_allowed_random_enemies[select_random])
				await get_tree().create_timer(event["event_properties"]["spawn_interval"], false, true).timeout
				spawn_cooldown = false
		"spawn_enemy":
			pass
		"spawn_sequence":
			pass
		"spawn_miniboss":
			pass
		"spawn_boss":
			pass
	
	# Completes event sending a signal, if it may be necessary to update other nodes in the source scene
	event_completed.emit(event_name,event["event_type"])

func set_event_timer(event):
	for property in event["event_timer"]:
		var property_value = event["event_timer"][property]
		match property:
			"pause_stage_timer":
				if property_value == true:
					if debug: print("EVENT CAUSED STAGE_TIMER TO PAUSE")
					stage_timer_toggled = true
					stage_timer.paused = true
					await boss_killed
			"timer_period":
				if debug: print("EVENT TIMER INITIATED WITH {0} SECONDS | APPROXIMATELY {1} STAGE SECONDS LEFT".format({0:property_value, 1:int(stage_timer.get_time_left())}))
				await get_tree().create_timer(property_value, false, true).timeout
				timer_period_expired = true
