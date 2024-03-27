extends Node2D

## Constants
const base_timeout : float = 2
const base_duration : float = 0.5
const base_y_offset : int = 25
const base_x_offset : int = 15
const base_weight : int = 0.995
const heal_label : LabelSettings = preload("res://assets/themes/labels/heal_indicator_label.tres")

## Properties
var counter : int
var indicator_ready : bool = false
var x_offset : float
var set_top_level:
	set(value):
		assert(value is bool)
		set_as_top_level(value)

func _ready():
	randomize()
	
	x_offset = randf_range(-base_x_offset, base_x_offset)

func _physics_process(delta):
	if indicator_ready:
		$Indicator.global_position.x += x_offset * delta
		$Indicator.global_position.y -= base_y_offset * delta
		
		## Increase counter and free after completion
		if counter < int(base_duration * 60):
			counter += 1
		else: call_deferred("queue_free")

func set_indicator(value, type, timeout : float = base_timeout):
	#? Type: boolean that defines if the health change is negative (true) or positive (false)
	## Config
	if type: pass
	else: $Indicator.set_label_settings(heal_label)
	
	## Start
	$Indicator.set_text(str(value))
	indicator_ready = true
