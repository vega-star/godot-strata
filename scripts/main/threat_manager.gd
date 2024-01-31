class_name ThreatManager extends Node

# NODE FUNCTION: Contains and orchestrates a schedule of events that will happen in a stage. 
# In the future, the ThreatManager will send data to a radar informing the player of certain events like boss-fights. 
# The stage timer is intended to be guide which events are generated. Each stage should have one of these nodes.

signal enemy_spawned(enemy_name,type)

# Each stage should have a different list of elements in the allowed_enemies array. 
# This should only contain normal enemies on random generations, bosses are exception and will be called from the timed schedule.
var default_allowed_enemies : Array = ["striker_1","vanguard_2"]
@export var allowed_enemies : Array = []

@onready var schedule_time: # NEEDS: 'threat_manager.schedule_time = stage_timer.time_left' in Scene script
	set(time_remaining):
		schedule_time = time_remaining
@onready var threat_generator = $ThreatGenerator
@onready var current_stage = owner.get_name()
@export var debug : bool = false

func call_threat(enemy, rule_check : bool = false):
	threat_generator.generate_threat(enemy, rule_check)

func _ready():
	print("res://stages/schedules/%s.json" % current_stage)
	# var load_stage_schedule = FileAccess.open("res://stages/schedules/%s" % current_stage, FileAccess.READ)
	
	if debug:
		threat_generator.debug = true
		print("ThreatManager located in %s with debug active" % current_stage)
		allowed_enemies = default_allowed_enemies
		while true:
			call_threat(allowed_enemies[0])
			await get_tree().create_timer(1.5).timeout
			call_threat(allowed_enemies[1])
			await get_tree().create_timer(1.5).timeout
			call_threat("striker_swarm_1", true)
			await get_tree().create_timer(1.5).timeout
			call_threat("striker_swarm_2", true)
			print("Remaining stage time: %f" % schedule_time)

func _process(delta):
	pass

func _on_threat_spawned_relay(enemy_name, type):
	enemy_spawned.emit(enemy_name,type)
