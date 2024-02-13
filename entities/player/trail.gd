extends Line2D

var current_pos
var source_pos
@export var append_line : NodePath
@export var line_speed : float = 10
@export var trail_length : int = 50

func _ready():
	source_pos = get_node(append_line)
	pass

func _process(delta):
	global_position = Vector2(0,0)
	current_pos = source_pos.global_position
	add_point(current_pos)
	
	if get_point_count() > trail_length:
		remove_point(0)
	# current_pos = global_position
	# clamp(width, 0, 50)
