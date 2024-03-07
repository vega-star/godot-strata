extends Area2D

signal enemy_died

const enemy_id = 0
const enemy_name = "enemy"
const alpha_modulation = 0.5

@export var score_value = 10
@export var speed = 150
@export var contact_damage = 1
@export var self_sprite : Sprite2D
@onready var self_hitbox : HitboxComponent = $HitboxComponent
@onready var combat_component : CombatComponent = $CombatComponent
@onready var drop_component : DropComponent = $DropComponent
const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15

# Debug / testing
@export var bulk_updating : bool = false

func _ready():
	if !self_sprite: self_sprite = $EnemySprite

func _physics_process(delta):
	global_position.x -= speed * delta

func _on_area_entered(body):
	if body is Player: # Generate damage to itself if it collides with player
		self_hitbox.generate_damage(contact_damage)
		
	if body is HitboxComponent:
		body.generate_damage(contact_damage)

func _on_visible_on_screen_notifier_2d_screen_exited(): # Deletes the enemy entity if it somehow goes beyond the left side of the screen
	queue_free()

func die(): # Entity death sequence, called by HealthComponent when health <= 0
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
	if type:
		for n in damage_effect_flicker_count:
			self_sprite.modulate = Color(0,0,0)
			await get_tree().create_timer(damage_effect_flicker).timeout
			self_sprite.modulate = Color(255,255,255)
			await get_tree().create_timer(damage_effect_flicker).timeout
