class_name MuzzleComponent
extends Node2D

signal muzzles_ready

const muzzle_angle_limit : Vector2 = Vector2(-25, 25)
const muzzle_initial_position : Vector2 = Vector2(54, 0)
const separation : int = 20

var angle_limit : int = (-muzzle_angle_limit.x + muzzle_angle_limit.y)
var muzzles_generating : bool = false
var muzzles : Array

@export var muzzle_type : int = 0
@export var max_muzzle_limit : int = 10

func _ready(): clear_muzzles()

func add_muzzle(add : int = 1):
	muzzles_generating = true
	for n in add:
		var new_muzzle = Marker2D.new()
		if self.get_child_count() < max_muzzle_limit:
			muzzles.append(new_muzzle)
			await add_child(new_muzzle)
		else:
			printerr('NO MUZZLE LOCATIONS AVAILABLE, MAX NUMBER ACHIEVED')
	update_muzzles()
	muzzles_ready.emit()
	muzzles_generating = false

func set_muzzle(value : int):
	if muzzles_generating: await muzzles_ready
	await clear_muzzles()
	add_muzzle(value)

func update_muzzles():
	print('update requested')
	var quantity = muzzles.size()
	var distance : int = 1
	var direction : bool = true
	
	for m in muzzles:
		var n : int = m.get_index() # The node order
		m.position = muzzle_initial_position # Set in default position
		
		match muzzle_type:
			0: # Default | Straight vertically arranged
				if n == 0: pass
				else:
					if direction:
						m.position.y -= separation * distance
						direction = false
					else: 
						m.position.y += separation * distance
						direction = true
					
					if int(n) % 2 == 1: pass
					else: distance += 1
			1: # Centralized | All projectiles come from a central point (the default position), but diverge in angle
				var new_angle = muzzle_angle_limit.x + (angle_limit / (quantity - 1)) * n
				m.rotation_degrees = new_angle
			_:
				printerr("INVALID MUZZLE TYPE RECEIVED") # Invalid!

func clear_muzzles(): 
	for m in self.get_children(): remove_child(m)
	muzzles.clear()
