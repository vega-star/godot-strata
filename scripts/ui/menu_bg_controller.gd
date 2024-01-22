extends CanvasLayer

var sea_speed : float = 50

var door_opening_sequence : bool = false

func _ready():
	await get_tree().create_timer(3).timeout
	door_opening_sequence = true

func _process(delta):
	$MainParallax/Sea.motion_offset.y += sea_speed * delta
	if door_opening_sequence == true:
		$MainParallax/DoorLeft.position.x = lerp($MainParallax/DoorLeft.position.x, ($MainParallax/DoorLeft.position.x - 10), 0.01)
		$MainParallax/DoorRight.position.x = lerp($MainParallax/DoorRight.position.x, ($MainParallax/DoorRight.position.x + 10), 0.01)
