extends ParallaxLayer

var BG_SPEED = -100

func _process(delta):
	self.motion_offset.x += BG_SPEED * delta
