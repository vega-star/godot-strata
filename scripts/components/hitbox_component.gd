class_name HitboxComponent extends Node

@export var health_component : HealthComponent

func generate_damage(damage):
	if health_component:
		print("Damage generated on {0}".format({0:owner.get_path()}))
		health_component.infer_damage(damage)
