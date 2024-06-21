extends RayCast2D

signal target_health_at_max
signal target_missed

const frames_to_repeat_heal : int = 15
const heal_charge_time : float = 0.8

@export var laser_max_width = 25
@export var laser_heal : int = 1
@export var laser_line : Line2D
@export var aim_line : Line2D
@export var debug : bool = false

@onready var laser_tween : Tween
@onready var end_emitter = $EndEmitter
@onready var start_emitter = $StartEmitter

var heal_available : bool = false
var heal_frames : int
var cast_point
var charging : bool = false
var cast_available : bool = true
var casting : bool = false
var target : Object
var laser_speed = 0.8

func _ready():
	randomize()
	
	if laser_line.visible: laser_line.visible = false # Just in case I left it visible
	
	laser_line.points[-1] = Vector2.ZERO
	if aim_line: aim_line.points[-1] = Vector2.ZERO

func set_target(new_target):
	if enabled: await deactivate(2)
	if is_instance_valid(new_target): 
		target = new_target

func _physics_process(_delta):
	cast_point = target_position
	force_raycast_update()
	
	if is_colliding():
		if aim_line: aim_line.material.set_shader_parameter("line_colliding", true)
		cast_point = to_local(get_collision_point())
		target = get_collider()
		if enabled and heal_available:
			if target is HitboxComponent:
				target.health_component.change_health(laser_heal, false, self)
				heal_available = false
				heal_frames = 0
				
				if target.health_component.current_health == target.health_component.max_health:
					target_health_at_max.emit()
					target_missed.emit()
					deactivate(2)
			
			if !is_instance_valid(target): 
				target_missed.emit()
				deactivate(2)
	else:
		if aim_line: aim_line.material.set_shader_parameter("line_colliding", false)
	
	if heal_frames < frames_to_repeat_heal:
		heal_frames += 1
	elif heal_frames == frames_to_repeat_heal:
		heal_available = true
	
	laser_line.points[-1] = cast_point
	if aim_line: aim_line.points[-1] = cast_point
	end_emitter.position = cast_point

func set_casting(cast):
	casting = cast
	set_physics_process(cast)
	if casting: activate()
	else: deactivate()

func charge(urgency_factor : float = 1):
	if enabled: await deactivate()
	charging = true
	
	if aim_line:
		var aiming_tween = get_tree().create_tween()
		aiming_tween.tween_property(aim_line, "width", 2, laser_speed)
	
	await get_tree().create_timer(heal_charge_time / urgency_factor, false).timeout
	
	charging = false
	set_casting(true)

func activate(timeout : float = 0.0):
	laser_line.visible = true
	
	laser_tween = get_tree().create_tween()
	laser_tween.tween_property(laser_line, "width", laser_max_width, laser_speed)
	
	end_emitter.emitting = true
	start_emitter.emitting = true
	
	if aim_line: aim_line.width = 0
	
	enabled = true
	await laser_tween.finished
	laser_tween.kill()
	
	if timeout > 0:
		await get_tree().create_timer(timeout, false).timeout
		set_casting(false)

func deactivate(urgency_factor : float = 1):
	end_emitter.emitting = false
	start_emitter.emitting = false
	
	laser_tween = get_tree().create_tween()
	laser_tween.tween_property(laser_line, "width", 0, laser_speed * urgency_factor)
	await laser_tween.finished
	enabled = false
	laser_tween.kill()
	
	laser_line.visible = false
