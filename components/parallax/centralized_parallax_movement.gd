extends ParallaxBackground

@onready var background_layer_1 = $L_03
@onready var background_layer_2 = $L_02
@onready var background_layer_3 = $L_01

@export var first_bgl_speed = 150
@export var bgl_multiply_factor = 2.5
@export var raw_speed_factor : float = 1

var bgl_1 = first_bgl_speed * raw_speed_factor
var bgl_2 = bgl_1 * bgl_multiply_factor
var bgl_3 = bgl_2 * bgl_multiply_factor

func _process(delta):
	background_layer_1.motion_offset.x -= bgl_1 * delta
	background_layer_2.motion_offset.x -= bgl_2 * delta
	background_layer_3.motion_offset.x -= bgl_3 * delta
