class_name ThreatManager extends Node

# NODE FUNCTION: Contains and orchestrates a schedule of events that will happen in a stage. 
# In the future, the ThreatManager will send data to a radar informing the player of certain events like boss-fights. 
# The stage timer is intended to be guide which events are generated. Each stage should have one of these nodes.

signal enemy_spawned(enemy_name,type)
signal event_completed()
signal stage_timer_toggled(paused : bool)
signal scene_loaded()

## Nodes
@export var stage_timer : Timer
@onready var threat_generator = $ThreatGenerator
@onready var enemy_container = $EnemiesContainer
@onready var drop_component = $DropComponent
@onready var current_stage = owner.get_name()
@onready var message_player = UI.InfoHUD.message_player

## Properties
@export var debug : bool = false
@export var debug_generator : bool = false
# Each stage should also have a configuration file that loads before the events and sets certain parameters to other processes
var preload_stage_length : float
var stage_scene : String = ""
var stage_allowed_random_enemies : Array = []
var stage_length_in_seconds : float
var stage_length_in_minutes : float = 0.0
var challenge_enemy

## Dictionaries
var stage_dict : Dictionary
var events_dict : Dictionary 

func call_threat(enemy, rule_check : bool = false):
	threat_generator.generate_threat(enemy, rule_check)

func _ready():
	randomize()
	
	if debug_generator:
		threat_generator.debug = true
		print("ThreatGenerator located in %s with debug active" % current_stage)
	var raw_events_file : String = "res://scenes/stages/schedules/{0}_events.json".format({0:current_stage})
	var raw_stage_file : String = "res://scenes/stages/stagefiles/{0}_stage.json".format({0:current_stage})
	
	await load_stage_file(raw_stage_file)
	load_events_file(raw_events_file)
	await owner.stage_started # The scene controls when the schedule starts
	
	UI.InfoHUD.toggle_message_layer(true)
	
	load_events()

func _on_threat_spawned_relay(enemy_name, type):
	enemy_spawned.emit(enemy_name,type)

func load_stage_file(file_path):
	assert(FileAccess.file_exists(file_path))
	var load_stage_info = FileAccess.open(file_path, FileAccess.READ)
	stage_dict = JSON.parse_string(load_stage_info.get_as_text())
	assert(stage_dict is Dictionary)
	stage_scene = stage_dict["stage_scene"]
	stage_allowed_random_enemies = stage_dict["allowed_random_enemies"]
	stage_length_in_minutes = stage_dict["stage_length_in_minutes"]
	stage_length_in_seconds = stage_length_in_minutes * 60
	
	stage_timer.set_wait_time(stage_length_in_seconds)
	UI.UIOverlay.set_stage_bar(stage_length_in_minutes * 60)
	
	if debug: print("STAGE_TIMER STARTED WITH A TOTAL OF {0} SECONDS".format({0:stage_length_in_seconds}))
	scene_loaded.emit()

func load_events_file(file_path): # Loads a json and turns it into a dictionary
	assert(FileAccess.file_exists(file_path))
	var load_events_schedule = FileAccess.open(file_path, FileAccess.READ)
	events_dict = JSON.parse_string(load_events_schedule.get_as_text())
	assert(events_dict is Dictionary)
	preload_events()

func preload_events(): ## Pre-loads events to mark checkpoints, event markers, etc.
	if debug: print('LIST OF PRELOADED EVENTS:')
	for event in events_dict:
		preload_event(events_dict[event], event)

func load_events(): ## Iterates through each event sequentially
	for event in events_dict:
		execute_event(events_dict[event], event) # The 'await' functions guarantees events will follow a timed sequence
		await event_completed # Waits for an event to completely finish before starting another event

func preload_event(event, event_name = "UNNAMED_EVENT"):
	var icon_id : String
	var timestamp : float
	var z_level : int = 0
	
	if event["set_timer"]:
		if !event["event_properties"]["event_timer"].has("timer_period"): return
		var event_time = float(event["event_properties"]["event_timer"]["timer_period"])
		timestamp = preload_stage_length
		preload_stage_length += event_time
	
	if event["event_icon"] is String:
		icon_id = str(event["event_icon"])
	elif event["event_icon"]:
		match event["event_type"]:
			"filler": icon_id = "message_yellow"
			"message": icon_id = "message"
			"toggle_random": icon_id = "exclamation_mark"
			"spawn_enemy": icon_id = "exclamation_mark"
			"spawn_single_random_enemy": icon_id = "exclamation_mark"
			"spawn_sequence": icon_id = "boss"
			"spawn_challenge": 
				icon_id = "boss"
				z_level = 2
			"spawn_item": icon_id = "item"
			_:
				icon_id = "exclamation_mark"
				push_error("EVENT_TYPE INVALID | Check for typos")
	elif !event["event_icon"]:
		if debug: print('%s | Event icon skipped, turned off' % event_name)
		return
	else:
		push_warning('Event icon unset, not boolean nor string, returning null')
		return
	
	var event_data : Dictionary = {
		"event_name": event_name,
		"event_type": event["event_type"],
		"event_description": event["event_description"],
		"icon_id": icon_id,
		"timestamp": timestamp,
		"z_level": z_level
	}
	
	UI.UIOverlay.display_event(event_data)

func execute_event(event, event_name = "UNNAMED_EVENT"):
	var filler_time : float
	var rule_override : Dictionary
	
	if event["has_rules"]:
		rule_override = event["event_properties"]["rules"]
		assert(rule_override is Dictionary)
	
	if debug: print("{0} EVENT LOADED | TYPE: {1}\n\tDESCRIPTION: {2}".format({0:event_name,1:event["event_type"],2:event["event_description"]}))
	
	match event["event_type"]:
		"filler":
			filler_time = $"../StageTimer".get_time_left() - float(event["event_properties"]["event_timer"]["filler_stop_before"])
			print('\tFILLER QUEUED | Filler timer/Real time remaining: {0}/{1}'.format({0:filler_time,1:$"../StageTimer".get_time_left()}))
		"message":
			var message_set : bool = event["event_properties"]["message_set"]
			var message_timeout : float = event["event_properties"]["message_timeout"]
			if !message_set:
				message_player.request_message(
					int(event["event_properties"]["message_content"]),
					message_timeout
				)
			else:
				message_player.request_message(
					str(event["event_properties"]["message_content"]),
					message_timeout
				)
		"toggle_random":
			var toggle_value = event["event_properties"]["active"]
			owner.set_random_loop = toggle_value
			if toggle_value: owner.set_random_loop_interval = event["event_properties"]["random_spawn_interval"]
		"spawn_enemy":
			threat_generator.generate_threat(event["event_properties"]["enemy"], rule_override)
		"spawn_single_random_enemy":
			var select_random = randi() % stage_allowed_random_enemies.size() # This array comes from the [Stage Name]_stage.json file
			threat_generator.generate_threat(stage_allowed_random_enemies[select_random], rule_override)
		"spawn_sequence":
			spawn_sequence(event["event_properties"]["enemy_array"], event["event_properties"]["sequence_cooldown"], rule_override)
		"spawn_challenge":
			threat_generator.generate_threat(event["event_properties"]["enemy"], rule_override)
		"spawn_item":
			var drop_dict = event["event_properties"]["item_selection"]
			var override_drop : bool = event["event_properties"]["override_drop"]
			var drop_position = $ThreatGenerator/ScreenArea/SpawnArea/CenterSpawnPos.global_position
			
			if override_drop:
				drop_component.drop_item(drop_dict["items"], drop_position)
			else:
				await drop_component.config_drop(
					drop_dict["type"],
					drop_dict["items"],
					drop_dict["chances"],
					drop_dict["range"],
					drop_dict["quantity"],
					drop_dict["repeat"],
					drop_position
				)
				drop_component.request_drop()
		_:
			push_error('%s | INVALID EVENT TYPE' % event_name)
	
	if event["set_timer"]: # Ties event duration to a in-game timer
		set_event_timer(event, filler_time)
		await event_completed
	else:
		await get_tree().create_timer(1, false).timeout
		event_completed.emit()
	return
 
func set_event_timer(event, event_name = "UNNAMED EVENT", override = null): # Sets the timer that toggles 'timer_period_expired' and can pause the stage timer until a certain entity is killed.
	for property in event["event_properties"]["event_timer"]:
		var property_value = event["event_properties"]["event_timer"][property]
		match property:
			"pause_stage_timer":
				if property_value: # Switch that only unpauses the game after the challenge is completed
					# Note that if the signal isn't connected to the enemy, ThreatGenerator will not send the signal and timer will stay paused forever
					# Also, if the enemy spawned by the ThreatGenerator doesn't emit a enemy_defeated signal, it will not pause at all
					pause_stage_timer(true)
					await threat_generator.challenge_completed
					pause_stage_timer(false)
			"stop_before":
				await get_tree().create_timer(override, false).timeout # Waits for a previously calculated time
			"timer_period":
				if debug: print("\tEVENT TIMER INITIATED WITH {0} SECONDS | APPROXIMATELY {1} STAGE SECONDS LEFT".format({0:property_value, 1:int(stage_timer.get_time_left())}))
				await get_tree().create_timer(property_value, false).timeout
				if debug: print("\tEVENT TIMER ENDED")
			"wait_for_message":
				if property_value:
					pause_stage_timer(true)
					await message_player.message_displayed
					pause_stage_timer(false)
	
	event_completed.emit()
	return

func spawn_sequence(enemy_array, sequence_cooldown, rule_override = null): # Plays a simple sequence from a given array of enemies
	for enemy in enemy_array:
		threat_generator.generate_threat(enemy, rule_override)
		await get_tree().create_timer(sequence_cooldown, false).timeout
	return

func pause_stage_timer(toggle : bool):
	stage_timer.set_paused(toggle)

func _exit_tree():
	UI.InfoHUD.toggle_message_layer(false)
