class_name HealthBarComponent extends Node2D

const check_cooldown : int = 3

@export var health_component : HealthComponent
@export var lock_rotation : bool = true
@export var visibility_threshold : float = 80

@onready var health_bar : Node = $HealthBar
@onready var checker : Timer = $CheckTimer
@onready var health_bar_sync = health_bar:
	set(health_value):
		health_bar.value = health_value
@onready var set_health_bar_size:
	set(value):
		health_bar.set_max(value)
		health_bar.value = value

var max_health : int


## Simply shows a health bar above the entity. Bosses could have a different component layer
# For it to work, we need:
# 1. Set the ProgressBar size equal to max_health of entity
# 2. HealthComponent updating the health_bar value every time a change happens

func _ready():
	max_health = health_component.max_health
	set_health_bar_size = max_health
	health_bar.visible = false
	
	if (visibility_threshold < 0 && visibility_threshold > 100):
		push_warning(name, ' | THRESHOLD INVALID | Not a value between 0 and 100')
	
	visibility_threshold = (float(max_health) / 100) * visibility_threshold
	
	checker.wait_time = check_cooldown

func _process(_delta):
	if lock_rotation:
		global_rotation = 0.0

func _on_health_bar_value_changed(value):
	if value < max_health:
		health_bar.visible = true
	
	if value > visibility_threshold:
		checker.start(check_cooldown)

func _on_check_timer_timeout():
	health_bar.visible = false
