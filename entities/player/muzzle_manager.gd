extends Node2D

var muzzle_positions : Dictionary = {
	1: Vector2(54, 0),
	2: Vector2(51, -20),
	3: Vector2(51, 20)
}

func add_muzzle():
	var new_muzzle = Marker2D.new()
	var new_muzzle_id = self.get_child_count() + 1
	
	if muzzle_positions.has(new_muzzle_id):
		new_muzzle.position = muzzle_positions[new_muzzle_id]
		
		add_child(new_muzzle)
	else:
		printerr('NO MUZZLE LOCATIONS AVAILABLE, MAX NUMBER ACHIEVED')
