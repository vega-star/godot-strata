extends RayCast2D

@export var laser_damage : int = 1
@export var laser_line : Line2D
@export var aim_line : Line2D
@export var charging_emitter : CPUParticles2D
@export var source_emitter : CPUParticles2D
@export var beam_emitter : CPUParticles2D
@export var end_emitter : CPUParticles2D
@export var debug : bool = false

@onready var laser_tween : Tween
var cast_point
var charging : bool = false
var cast_available : bool = true
var casting : bool = false
var target : Object

var laser_speed = 0.2
var laser_max_width = 25

func _ready():
	randomize()
	
	## Default node connections
	if !laser_line: laser_line = $LaserLine
	if !charging_emitter: charging_emitter = $Emitters/ChargingEmitter
	if !source_emitter: source_emitter = $Emitters/SourceEmitter
	if !beam_emitter: beam_emitter = $Emitters/BeamEmitter
	if !end_emitter: end_emitter = $Emitters/EndEmitter
	
	laser_line.points[-1] = Vector2.ZERO
	aim_line.points[-1] = Vector2.ZERO

func _process(_delta):
	cast_point = target_position
	force_raycast_update()
	
	if is_colliding():
		aim_line.material.set_shader_parameter("line_colliding", true)
		cast_point = to_local(get_collision_point())
		target = get_collider()
		if enabled:
			target.generate_damage(laser_damage)
	else:
		aim_line.material.set_shader_parameter("line_colliding", false)
	
	laser_line.points[-1] = cast_point
	aim_line.points[-1] = cast_point
	beam_emitter.position.x = cast_point.length() / 2
	end_emitter.position = cast_point


func set_casting(cast):
	casting = cast
	set_physics_process(cast)
	if casting: activate()
	else: deactivate()

func charge():
	if enabled: await deactivate()
	charging = true
	end_emitter.emitting = false
	charging_emitter.emitting = true
	charging_emitter.speed_scale = 0
	
	var aiming_tween = get_tree().create_tween()
	aiming_tween.tween_property(aim_line, "width", 4, laser_speed)
	
	var charging_tween = get_tree().create_tween()
	charging_tween.tween_property(charging_emitter, "speed_scale", 5, 5)
	await get_tree().create_timer(5, false).timeout
	
	charging_emitter.emitting = false
	charging_tween.kill()
	aiming_tween.kill()
	charging = false
	set_casting(true)

func activate():
	charging_emitter.emitting = false
	source_emitter.emitting = true
	beam_emitter.emitting = true
	end_emitter.emitting = true
	
	aim_line.width = 0
	
	laser_tween = get_tree().create_tween()
	laser_tween.tween_property(laser_line, "width", laser_max_width, laser_speed)
	enabled = true
	await laser_tween.finished
	laser_tween.kill()

func deactivate():
	source_emitter.emitting = false
	beam_emitter.emitting = false
	end_emitter.emitting = false
	
	laser_tween = get_tree().create_tween()
	laser_tween.tween_property(laser_line, "width", 0, laser_speed)
	await laser_tween.finished
	enabled = false
	laser_tween.kill()
