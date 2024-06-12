extends ProgressBar

signal module_on
signal module_off

@onready var module_bar_label = $ModuleBarLabel
@onready var damage_bar = $DamageBar

var module_health_component : HealthComponent
var module_alive : bool = true

func set_bar(listener : HealthComponent):
	module_health_component = listener
	max_value = module_health_component.max_health
	value = max_value
	module_health_component.health_changed.connect(update_health)

func update_health():
	var current_health = module_health_component.current_health
	value = current_health
	if damage_bar: damage_bar._set_health(current_health)
	
	if value <= 0 and module_alive:
		module_off.emit()
		module_alive = false
	elif !module_alive and value > 0:
		module_on.emit()
		module_alive = true

func _on_module_on():
	visible = true

func _on_module_off():
	visible = false
