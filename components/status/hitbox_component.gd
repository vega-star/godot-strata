class_name HitboxComponent extends Node

@export var health_component : HealthComponent
@export var debug : bool = true

func generate_damage(damage):
	if health_component:
		health_component.infer_damage(damage)
		if debug == true: print("{0} damage generated on {1}".format({0:damage,1:owner.get_path().get_concatenated_names()}))
