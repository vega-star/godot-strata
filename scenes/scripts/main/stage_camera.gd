extends Camera2D

# Main variables
const minimum_strength = 0.05
@export var base_shake_strength : float = 10.0
@export var shake_decay : float = 3.0
var enable_camera_shake : bool
var shake_random = RandomNumberGenerator.new()
var shake_strength : float

func _ready():
	randomize()

func _process(delta):
	if enable_camera_shake:
		shake_strength = lerpf(shake_strength, 0.0, shake_decay * delta)
		if shake_strength > minimum_strength:
			print(shake_strength)
			offset = get_shake_offset(delta)
		else:
			offset = Vector2(0,0)

func toggle_shake(toggle : bool):
	enable_camera_shake = toggle

func start_shake(strength : float = base_shake_strength):
	shake_strength = strength

func get_shake_offset(delta, effect_multiplier = 1) -> Vector2:
	return Vector2(
		shake_random.randf_range(-shake_strength,shake_strength),
		shake_random.randf_range(-shake_strength,shake_strength)
	)

func config_shake(new_strength, new_decay, start : bool = false):
	base_shake_strength = new_strength
	shake_decay = new_decay
	if start: start_shake(new_strength)
