extends State

@export var diver_carrier : Enemy

var locked_release : bool = false
var release_order : int = 0

const release_timeout : float = 2

## Deploy divers
# Timed sequence for deploying diver units from a Diver Carrier

func state_physics_update(_delta):
	if !locked_release:
		locked_release = true
		var order_size : int
		if diver_carrier.spawn_top:
			order_size = diver_carrier.top_divers.size()
		elif diver_carrier.spawn_bottom:
			order_size = diver_carrier.bottom_divers.size()
			
		if release_order < order_size:
			if diver_carrier.spawn_top: 
				diver_carrier.release_attachment(diver_carrier.top_divers[release_order])
			
			if diver_carrier.spawn_bottom: 
				diver_carrier.release_attachment(diver_carrier.bottom_divers[release_order])
			
			release_order += 1
			
			await get_tree().create_timer(release_timeout).timeout
		elif release_order == order_size:
			return
		
		locked_release = false
