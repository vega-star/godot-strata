extends AnimatedSprite2D

const default_strength : float = 2
const default_norminal_rc : Color = Color(3.0, 3.0, 3.5)
const default_critical_rc : Color = Color(5.0, 0.5, 0.5)
const default_norminal_rc_no_glow : Color = Color(1.0, 1.0, 1.0)
const default_critical_rc_no_glow : Color = Color(1.0, 0.3, 0.4)

@export_group("Node Connections")
@export var health_component : HealthComponent

@export_group("Core Properties")
@export_range(0, 10) var strength : float = default_strength
@export var nominal_color : Color = default_norminal_rc
@export var critical_color : Color = default_critical_rc

@onready var core_light = $CoreLight

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(health_component)
	
	## Renderer check
	var renderer = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	match renderer:
		"forward_plus": pass
		"gl_compatibility": 
			print('Compatibility version') # Web version has no glow currently
			strength = 1
			nominal_color = default_norminal_rc_no_glow
			critical_color = default_critical_rc_no_glow
		_: printerr('RENDERER INVALID | Current renderer: {0}'.format({0:renderer}))
	
	set_modulate(nominal_color * strength)
	health_component.health_change.connect(update_core)

func update_core(_previous_value : int, new_value : int, _type : bool):
	var new_color : Color
	var max_value = health_component.max_health
	
	var r_map = remap(new_value, max_value, 0, nominal_color.r, critical_color.r)
	var g_map = remap(new_value, max_value, 0, nominal_color.g, critical_color.g)
	var b_map = remap(new_value, max_value, 0, nominal_color.b, critical_color.b)
	
	new_color = Color(r_map, g_map, b_map)
	set_modulate(new_color * strength)
	
	if core_light:
		core_light.set_color(new_color)
