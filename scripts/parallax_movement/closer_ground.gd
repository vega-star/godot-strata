extends ParallaxLayer

var BG_SPEED = -500

func _process(delta):
	self.motion_offset.x += BG_SPEED * delta
