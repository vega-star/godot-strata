extends Line2D

# Main variables
var position_offset : Vector2

@export var line_gradient : Gradient
@export var randomize : bool = false
@export var trail_length : int = 30
@export var movement_speed = 10

# Randomizer
var trail_size_flicker : float = 1.2
var range_value : float  = 0.2

func _ready():
	if randomize:
		randomize()
	
	if line_gradient:
		gradient = line_gradient

func _process(_delta):
	var pos = _get_pos()
	
	add_point(pos)
	
	if get_point_count() > trail_length:
		remove_point(0)
	
	if randomize:
		for p in range(get_point_count()):
			var rand_vector := Vector2( randf_range(-range_value, range_value), randf_range(-range_value, range_value) )
			points[p] += (Vector2.LEFT * movement_speed + ( rand_vector * trail_size_flicker))
	else:
		for p in range(get_point_count()):
			points[p] += (Vector2.LEFT * movement_speed)

func _get_pos():
	return owner.global_position
