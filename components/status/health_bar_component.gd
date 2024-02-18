class_name HealthBarComponent extends Node2D

@export var health_component : HealthComponent
@onready var health_bar : Node = $HealthBar
@onready var health_bar_sync = health_bar:
	set(health_value):
		health_bar.value = health_value

@export var fixed_rotation : bool = false

## Simply shows a health bar above the entity. Bosses could have a different component layer
# For it to work, we need:
# 1. Set the ProgressBar size equal to max_health of entity
# 2. HealthComponent updating the health_bar value every time a change happens

func _ready():
	var initial_health = health_component.max_health
	health_bar.set_max(initial_health)
	health_bar.value = initial_health

func _process(delta):
	if fixed_rotation:
		global_rotation = 0
