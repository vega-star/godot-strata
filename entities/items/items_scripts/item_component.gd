extends Area2D

signal item_set

## Functionality
# Most of this component behavior is controlled by DropComponent, which also spawns the item and calculates the random drop chances.

## Values
	# 0 - Selectable item, boss drops, etc. Needs to call 'set_items()' after instantiation to work
	# 1 - Health Capsule
	# 2 - Secondary Ammo
	# 3 - Damage Boost

## Node connections
@onready var sprite = $ItemSprite
@onready var collision = $ItemCollision

## Main variables
var value : int = 1
var effect_name : String
var type : int
var items : Array = []
var items_data : Dictionary = {
	"selectable_item": {
		"item_id": 0,
		"item_sprite": "res://assets/textures/prototypes/selectable_item.png",
		"item_collision_size": 6,
		"item_properties": {
			"accumulate": false
		}
	},
	"health_capsule": {
		"item_id": 1,
		"item_sprite": "res://assets/textures/items/health-capsule.png",
		"item_collision_size": 4,
		"item_properties": {
			"accumulate": false
		}
	},
	"secondary_ammo": {
		"item_id": 2,
		"item_sprite": "res://assets/textures/items/bomb-ammo.png",
		"item_collision_size": 4,
		"item_properties": {
			"accumulate": false
		}
	},
	"damage_boost": {
		"item_id": 3,
		"item_sprite": "res://assets/textures/prototypes/primary_up.png",
		"item_collision_size": 4,
		"item_properties": {
			"accumulate": false
		}
	}
}
var data : Dictionary
var selectable_item_sprite = preload("res://assets/textures/prototypes/selectable_item.png")

# Behavior
@onready var player = get_tree().get_first_node_in_group("player")
var player_position : Vector2

@export var item_is_magnetic : bool = true
var strength_increasing : bool = false
var strength : float = 0
var max_strength : float = 500
@export var item_drift : float = 1
@export var max_item_drift : float = 120

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
		set_drop(area)

func set_values(new_value, drift, max_drift = null, new_effect_name = null):
	value = new_value
	item_drift = drift
	if max_drift: max_item_drift = max_drift
	if new_effect_name: effect_name = new_effect_name
	else: effect_name = 'UNNAMED_EFFECT'

func set_properties(target_sprite, hitbox_size):
	print(target_sprite)
	
	sprite.set_texture(target_sprite)
	collision.shape.radius = hitbox_size

func set_items(array): # For selectable items
	assert(items is Array)
	items = array
	item_set.emit()

func set_type(new_value):
	type = new_value
	assert(type is int)
	match type:
		0: # Selectable item
			data = items_data["selectable_item"]
		1: # Health Capsule
			data = items_data["health_capsule"]
		2: # Secondary Ammo
			data = items_data["secondary_ammo"]
		3: # Damage Boost
			data = items_data["damage_boost"]
		_:
			push_warning("TYPE UNSET | DICTIONARY FOR ITEMS WILL BE EMPTY")

func set_drop(area):
	match type:
		0: # Selectable item
			area.get_owner().equipment_module.present_choice(items)
		1: # Health Capsule
			area.get_owner().health_component.change_health(value, false)
		2: # Secondary Ammo
			area.get_owner().equipment_module.add_ammo(value)
		3: # Damage Boost
			area.get_owner().equipment_module.create_buff(effect_name, "primary_damage_buff", value, 5)
	queue_free()
