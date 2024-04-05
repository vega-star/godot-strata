extends Control

@onready var event_label = $EventLabel
@onready var event_sprite = $EventSprite

@export var event_movement : int = 20
@export var name_color : Color = Color.WHITE
@export var type_color : Color = Color.WHITE

var base_text : String = '[b]EVENT:[/b] [color={3}]{0}[/color]/n
[b]TYPE:[/b] [color={4}]{1}[/color]/n/n
{2}'
var event_text : String
var event_name : String
var event_type : String
var timestamp : float
var icon : Texture2D
var description : String
var movement_time : float = 0.2
var movement_active : bool = false
var initial_y : int
var target_y : int

func _ready():
	initial_y = position.y
	target_y = position.y - event_movement

func set_event(
		new_event_name : String,
		new_timestamp : float,
		new_icon : Texture2D,
		new_description : String
	):
	
	event_name = new_event_name
	timestamp = new_timestamp
	icon = new_icon
	description = new_description
	
	event_sprite.set_texture(icon)
	
	event_text = base_text.format({
		0:event_name.capitalize(),
		1:event_type.capitalize(),
		2:description,
		3:name_color,
		4:type_color
	})
	
	event_label.set_text(event_text)

# Elevate
func _on_mouse_entered(): arise(true)
func _on_focus_entered(): arise(true)

# Lower
func _on_mouse_exited(): arise(false)
func _on_focus_exited(): arise(false)

func arise(mode : bool = true):
	var movement_tween = get_tree().create_tween()
	movement_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if mode:
		movement_tween.tween_property(self, "position", Vector2(position.x, target_y), movement_time).set_trans(Tween.TRANS_EXPO)
	else:
		movement_tween.tween_property(self, "position", Vector2(position.x, initial_y), movement_time).set_trans(Tween.TRANS_EXPO)
	await movement_tween.finished
	event_label.visible = mode
