extends CanvasLayer

var sea_speed : float = 50

var door_opening_sequence : bool = false

func _ready():
	await get_tree().create_timer(3).timeout

func _process(delta):
	$MainParallax/StarsBG.motion_offset.x += 10 * delta
