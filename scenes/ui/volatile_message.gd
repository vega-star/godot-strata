extends Node2D

@onready var label = $Label

@export var flicker_frame : int = 5
@export var max_flicker_count : int = 10
@export var show_timeout : float = 3
@export var flicker_modulate : Color = Color.BLACK
@export var display_on_instantiation : bool = false

const upward_offset : int = -30

var flicker_on : bool = true
var flicker_count : int = 0
var flicker_total_count : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(false)
	if Options.photosens_mode: flicker_on = false
	label.visible = false
	if display_on_instantiation: 
		await get_tree().create_timer(show_timeout / 2).timeout
		display('3000')

func display(value : String):
	var display_tween = get_tree().create_tween()
	display_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	label.set_text(value)
	label.visible = true
	set_physics_process(true)
	display_tween.tween_property(label, "position", Vector2(label.position.x, upward_offset), show_timeout).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await get_tree().create_timer(show_timeout).timeout
	fade_out()

func fade_out():
	var display_tween = get_tree().create_tween()
	var modulate_tween = get_tree().create_tween()
	display_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	modulate_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	display_tween.tween_property(label, "position", Vector2(label.position.x, upward_offset * 2), show_timeout / 2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	modulate_tween.tween_property(label, "modulate", Color(0, 0, 0, 0), show_timeout / 2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await get_tree().create_timer(show_timeout / 2).timeout
	queue_free()

func _physics_process(delta):
	if flicker_count < flicker_frame and flicker_on: flicker_count += 1
	elif flicker_count >= flicker_frame and flicker_on:
		if flicker_total_count >= max_flicker_count: flicker_on = false; return
		if label.modulate == flicker_modulate: label.modulate = Color.WHITE
		else: flicker_total_count += 1; label.modulate = flicker_modulate
		flicker_count = 0
	else:
		label.modulate = Color.WHITE
