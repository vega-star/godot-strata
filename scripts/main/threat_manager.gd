class_name ThreatManager extends Node

# NODE FUNCTION: Contains and orchestrates a schedule of events that will happen in a stage. 
# In the future, the ThreatManager will send data to a radar informing the player of certain events like boss-fights. 
# The stage timer is intended to be guide which events are generated. Each stage should have one of these nodes.

signal enemy_spawned(enemy_name,type)
signal event_completed(event_name,event_type)
signal stage_timer_toggled(paused : bool)
signal scene_loaded()

# Each stage should also have a configuration file that loads before the events and sets certain parameters to other processes
var stage_scene : String = ""
var stage_allowed_random_enemies : Array = []
var stage_length_in_minutes : float = 0.0
var final_stage : bool = false
var challenge_enemy

@onready var stage_timer = $"../StageTimer"
@onready var threat_generator = $ThreatGenerator
@onready var enemy_container = $EnemiesContainer
@onready var current_stage = owner.get_name()
@export var debug : bool = false
var is_stage_timer_toggled : bool = false
var timer_period_expired : bool = false

# Threads
var period_thread : Thread = Thread.new()

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
		# await event_completed # Waits for an event to completely finish before starting another event

func execute_event(event, event_name = "UNNAMED EVENT"):
	var filler_time = null
	timer_period_expired = false
	if debug:
		print("{0} EVENT LOADED | TYPE: {1}\n\tDESCRIPTION: {2}".format({0:event_name,1:event["event_type"],2:event["event_description"]}))
	
	match event["event_type"]:
		"filler":
			filler_time = $"../StageTimer".get_time_left() - float(event["event_timer"]["filler_stop_before"])
			print('\tFILLER QUEUED | Filler timer/Real time remaining: {0}/{1}'.format({0:filler_time,1:$"../StageTimer".get_time_left()}))
		"random_period":
			period_thread.start(period_loop.bind(event, 0))
			if debug: print('\t%s PERIOD STARTED' % event["event_type"])
		"spawn_enemy":
			threat_generator.generate_threat(event["event_properties"]["enemy"])
		"spawn_single_random_enemy":
			var select_random = randi() % stage_allowed_random_enemies.size() # This array comes from the [Stage Name]_stage.json file
			threat_generator.generate_threat(stage_allowed_random_enemies[select_random])
		"spawn_sequence":
			spawn_sequence(event["event_properties"]["enemy_array"], event["event_properties"]["sequence_cooldown"])
		"spawn_miniboss":
			threat_generator.generate_threat(event["event_properties"]["miniboss"])
			await enemy_spawned
			challenge_enemy = get_tree().get_first_node_in_group("Miniboss")
		"spawn_boss":
			threat_generator.generate_threat(event["event_properties"]["boss"])
			await enemy_spawned
			challenge_enemy = get_tree().get_first_node_in_group("Boss")
	
	if event["event_properties"]["set_timer"]: # Locks event duration to a timer
		await set_event_timer(event, filler_time)
	
	# Completes event sending a signal, if it may be necessary to update other nodes in the source scene
	event_completed.emit(event_name,event["event_type"])
	timer_period_expired = true
	return

func set_event_timer(event, override = null): # Sets the timer that toggles 'timer_period_expired' and can pause the stage timer until a certain entity is killed.
	for property in event["event_timer"]:
		var property_value = event["event_timer"][property]
		match property:
			"pause_stage_timer":
				if property_value == true:
					if debug: print("CHALLENGE ENEMY %s EVENT CAUSED STAGE_TIMER TO PAUSE" % challenge_enemy)
					toggle_stage_timer(true)
					await challenge_enemy.challenge_killed
					toggle_stage_timer(false)
			"stop_before":
				await get_tree().create_timer(override, false).timeout # Waits for a previously calculated time
			"timer_period":
				if debug: print("\tEVENT TIMER INITIATED WITH {0} SECONDS | APPROXIMATELY {1} STAGE SECONDS LEFT".format({0:property_value, 1:int(stage_timer.get_time_left())}))
				await get_tree().create_timer(property_value, false).timeout
				if debug: print("\tEVENT TIMER ENDED")
	return

func period_loop(event, period_type): # Contains most repetitive timed loops of a period
	var spawn_cooldown = false 
	match period_type:
		0: # Random
			var loop_count = 0
			while !spawn_cooldown:
				if timer_period_expired: break
				spawn_cooldown = true
				if debug: loop_count += 1
				if debug: print('\t{0}º PERIOD LOOP INTERATION'.format({0:loop_count}))
				var select_random = randi() % stage_allowed_random_enemies.size() # Remember, this array comes from the [Stage Name]_stage.json file
				threat_generator.generate_threat(stage_allowed_random_enemies[select_random])
				await get_tree().create_timer(event["event_properties"]["spawn_interval"], false).timeout
				spawn_cooldown = false
	if debug: print('\t%s PERIOD LOOP ENDED' % event["event_type"])
	period_thread.wait_to_finish()
	return

func spawn_sequence(enemy_array, sequence_cooldown): # Plays a simple sequence from a given array of enemies
	for enemy in enemy_array:
		threat_generator.generate_threat(enemy)
		await get_tree().create_timer(sequence_cooldown, false).timeout

func toggle_stage_timer(paused : bool):
	is_stage_timer_toggled = paused
	stage_timer.set_paused(paused)
	stage_timer_toggled.emit(paused)

func _on_boss_killed():
	pass

func _exit_tree():
	pass
