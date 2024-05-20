extends Line2D

# Main variables
@export var source_node : Node
@export var line_gradient : Gradient
@export var burnout_gradient : Gradient
@export var trail_length : int = 20
@export var movement_speed = 15

var trail_size_difference : float = 1.5
var trail_size_flicker : float = 1.2
var range_value : float  = 0.2

func _ready():
	randomize()
	
	if line_gradient:
		gradient = line_gradient
	else: 
		line_gradient = gradient

func _physics_process(_delta):
	var pos = _get_pos()
	
	add_point(pos)
	
	if get_point_count() > trail_length: # Clear last point
		remove_point(0)
	
	for p in range(get_point_count()): # Tail flicker
		var rand_vector := Vector2( randf_range(-range_value, range_value), randf_range(-range_value, range_value) )
		points[p] += (Vector2.LEFT * movement_speed + ( rand_vector * trail_size_flicker))

func _get_pos():
	return source_node.global_position.rotated(source_node.rotation) 

func burst(toggle_burst : bool):
	match toggle_burst:
		true:
			gradient = burnout_gradient
		false:
			gradient = line_gradient
