extends ProgressBar

signal lethal_damage

@export var source_bar : ProgressBar
@export var timer_period : float = 1.5

@onready var timer : Timer = $Timer

const tween_duration : float = 0.5
var health = 0

func _ready():
	max_value = source_bar.max_value
	value = source_bar.max_value
	health = value
	timer.timeout.connect(_timeout)

func _set_health(new_health):
	var previous_health = health
	health = new_health
	
	if health <= 0: lethal_damage.emit()
	if health < previous_health: timer.start(timer_period)
	else: value = source_bar.value

func _timeout():
	var health_tween = get_tree().create_tween()
	health_tween.tween_property(self, "value", source_bar.value, tween_duration)
