extends ParallaxBackground

signal color_cycle_finished(node)

@export_range(0,10) var speed_factor : float = 1
@export var layers : Array[ParallaxLayer] = []
@export var layer_speed : Array[int]

func _ready():
	assert(layers.size() == layer_speed.size())

func _physics_process(delta):
	for l in layers.size():
		var target_layer = layers[l - 1]
		var target_speed = layer_speed[l - 1]
		target_layer.motion_offset.x -= target_speed * speed_factor * delta

func initiate_color_cycle(node : Object, modulate_to : Color, period : float):
	var color_tween = create_tween()
	color_tween.tween_property(node, "modulate", modulate_to, period)
	await color_tween.finished
	color_cycle_finished.emit(node)
