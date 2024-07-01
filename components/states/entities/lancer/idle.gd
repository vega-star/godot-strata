extends State

## Lancer Idle
# Unique temporary state before avail. Will change to 'avail' after a variable period of time and check conditions
# Idle time gets shortened based on health so the fight gets slightly faster with time

const base_idle_timer : float = 1
const clamp_minimum : float = 0.4
const clamp_maximum : float = 1

@export var health_component : HealthComponent

func enter():
	var health_factor = health_component.current_health / health_component.max_health
	health_factor = clamp(health_factor, clamp_minimum, clamp_maximum)
	
	await get_tree().create_timer(base_idle_timer * health_factor, false).timeout
	transitioned.emit(self, 'avail')
