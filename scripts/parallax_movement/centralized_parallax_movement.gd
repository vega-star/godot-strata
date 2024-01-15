extends ParallaxBackground

@onready var background_layer_1 = $L_03
@onready var background_layer_2 = $L_02
@onready var background_layer_3 = $L_01

var bgl_1 = 100
var bgl_2 = 300
var bgl_3 = 500

# Speed Factor - dinamically change speed during manuevers
@export var speed_factor : float = 0

func _process(delta):
	background_layer_1.motion_offset.x -= bgl_1 * delta * speed_factor
	background_layer_2.motion_offset.x -= bgl_2 * delta * speed_factor
	background_layer_3.motion_offset.x -= bgl_3 * delta * speed_factor
