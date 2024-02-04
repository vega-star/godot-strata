class_name HitboxComponent extends Node

@export var health_component : HealthComponent
@export var hitbox_cooldown : float = 0.05
@export var debug : bool = true
var is_hitbox_on_cooldown = false

func generate_damage(damage):
	if health_component and !is_hitbox_on_cooldown:
		is_hitbox_on_cooldown = true
		health_component.infer_damage(damage)
		if debug == true: print("{0} damage generated on {1}".format({0:damage,1:owner.get_path().get_concatenated_names()}))
		await get_tree().create_timer(hitbox_cooldown, false, true).timeout
		is_hitbox_on_cooldown = false
