extends ParallaxBackground

@onready var left_side = $LeftSide
@onready var right_side = $RightSide

const screen_size_y : int = 540
const sides_speed : float = 0.5

func _physics_process(delta):
	left_side.motion_offset.y += sides_speed
	right_side.motion_offset.y -= sides_speed
