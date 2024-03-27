extends Area2D

@export var item_is_magnetic : bool = true
var strength : float = 0
var max_strength : float = 500
@export var heal_value : int = 1
@export var item_drift : float = 1
@export var max_item_drift : float = 120

@onready var player = get_tree().get_first_node_in_group("player")
var player_position : Vector2
var strength_increasing : bool = false

func _physics_process(delta):
	if !strength_increasing:
		strength_increasing = true
		var tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
		tween.tween_property(self, "strength", max_strength, 3)
	
	if item_is_magnetic:
		if is_instance_valid(player): player_position = player.global_position
		var direction = global_position.direction_to(player_position)
		var distance = global_position.distance_to(player_position)
		
		global_position += (direction * strength) * delta
	else:
		global_position.x -= item_drift * delta
		lerp(item_drift, max_item_drift, 0.9)

func _on_presence_checker_screen_exited(): # Deletes item if it goes away from the screen
	queue_free()

func _on_area_entered(area):
	if area is HitboxComponent:
		area.get_owner().health_component.change_health(heal_value, false)
		
		# AudioManager.emit_sound_effect
		
		queue_free()
