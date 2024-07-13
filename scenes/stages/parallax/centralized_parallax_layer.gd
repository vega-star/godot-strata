class_name CentralizedParallaxLayer
extends ParallaxBackground

signal color_cycle_finished(node)

@export_range(0,10) var speed_factor : float = 1

@export_group('Layers Nodes Connections')
@export var layers : Array[ParallaxLayer] = []
@export var layer_speed : Array[int]
@export var layer_modulation_strength : Array[float]
@export var canvas_modulate : CanvasModulate

@export_group('Layers Modulation')
@export var initial_modulate : Color = Color.WHITE
@export var target_modulate : Color
@export var modulate_timer : float

func _ready():
	assert(layers.size() == layer_speed.size())
	canvas_modulate.color = Color.WHITE
	initiate_color_cycle(canvas_modulate, "color", target_modulate, modulate_timer)
	#for l in layers.size():
	#	var target_layer = layers[l - 1]
	#	var modulation_strength = layer_modulation_strength[l - 1]
	#	target_layer.modulate = initial_modulate
	#	initiate_color_cycle(target_layer, "modulate", target_modulate * modulation_strength, modulate_timer)

func _physics_process(delta):
	for l in layers.size():
		var target_layer = layers[l - 1]
		var target_speed = layer_speed[l - 1]
		target_layer.motion_offset.x -= target_speed * speed_factor * delta

func initiate_color_cycle(node : Object, property : String, modulate_to : Color, period : float):
	var color_tween = create_tween()
	color_tween.tween_property(node, property, modulate_to, period)
	await color_tween.finished
	color_cycle_finished.emit(node)
