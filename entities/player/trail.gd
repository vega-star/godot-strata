extends Line2D

var position_offset : Vector2
var current_pos : Vector2
@export var trail_length : int = 30
@export var movement_speed = 10
var trail_size_flicker : float = 1.2
var range_value : float  = 0.2

func _ready():
	randomize()
	position_offset = self.position

func _process(_delta):
	global_position = position_offset
	current_pos = owner.global_position
	add_point(current_pos)
	
	if get_point_count() > trail_length:
		remove_point(0)
	
	#for p in range(get_point_count()):
	#	var rand_vector := Vector2( randf_range(-range_value, range_value), randf_range(-range_value, range_value) )
	#	points[p] += (Vector2.LEFT * movement_speed + ( rand_vector * trail_size_flicker))
	
	for p in range(get_point_count()):
		points[p] += (Vector2.LEFT * movement_speed)

