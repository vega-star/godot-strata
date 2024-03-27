extends Area2D

signal enemy_died

@export var enemy_name : String = "enemy"
const alpha_modulation = 0.5

@export var set_health_bar : bool = true
@export var score_value = 10
@export var speed = 150
@export var contact_damage = 1
@export var self_contact_damage = 1
@export var self_sprite : Sprite2D
@export var outline_color_on_damage : Color = Color.WHITE
@export var deployed : bool = true
@export var drifting : bool = true

@onready var hitbox_component : HitboxComponent = $HitboxComponent
@onready var combat_component : CombatComponent = $CombatComponent
@onready var drop_component : DropComponent = $DropComponent

const damage_effect_flicker_count = 2
const damage_effect_flicker = 0.15
const outside_screen_timeout = 10

# Debug / testing
var present_on_screen : bool
@export var bulk_updating : bool = false

func _ready():
	if !self_sprite: self_sprite = $EnemySprite

func _physics_process(delta):
	if drifting:
		global_position.x -= speed * delta

func _on_area_entered(body):
	if body is Player: # Generate damage to itself if it collides with player
		hitbox_component.generate_damage(self_contact_damage)
		
	if body is HitboxComponent:
		body.generate_damage(contact_damage, self)

func _on_screen_reentered():
	present_on_screen = true

func _on_visible_on_screen_notifier_2d_screen_exited(): # Deletes the enemy entity if it somehow goes beyond the left side of the screen
	present_on_screen = false
	request_deletion()

func request_deletion():
	await get_tree().create_timer(outside_screen_timeout).timeout
	
	if !present_on_screen: queue_free()

func die(_source): # Entity death sequence, called by HealthComponent when health <= 0
	enemy_died.emit()
	
	if !bulk_updating:
		Profile.add_run_data("STATISTICS", "ENEMIES_DEFEATED", 1)
		Profile.add_run_data("STATISTICS", "SCORE", score_value)
	else:
		# Bulk add example
		var bulk_dict = {
			"Data1": {
				section = "STATISTICS",
				stat = "ENEMIES_DEFEATED",
				value = 1},
			"Data2": {
				section = "STATISTICS",
				stat = "SCORE",
				value = score_value}
		}
		Profile.add_bulk_data(bulk_dict)
	
	queue_free()

func _on_health_component_health_change(_previous_value, _new_value, type):
	var has_shader : bool = is_instance_valid(self_sprite.get_material())
	var flicker_on : bool = true
	if Options.photosens_mode:
		flicker_on = false
	
	if type and flicker_on:
		if has_shader:
			var original_color : Color = self_sprite.material.get_shader_parameter("original_line_color")
			
			for n in damage_effect_flicker_count:
				self_sprite.material.set_shader_parameter("line_color", outline_color_on_damage)
				await get_tree().create_timer(damage_effect_flicker).timeout
				self_sprite.material.set_shader_parameter("line_color", original_color)
				await get_tree().create_timer(damage_effect_flicker).timeout
		else:
			for n in damage_effect_flicker_count:
				self_sprite.modulate = Color(0,0,0)
				await get_tree().create_timer(damage_effect_flicker).timeout
				self_sprite.modulate = Color(255,255,255)
				await get_tree().create_timer(damage_effect_flicker).timeout
