extends ParallaxBackground

@export var speed_factor : float = 1

const sky_speed = 15
const stars_speed = 5
const close_clouds_speed = 80
const medium_cloud_speed = 50
const far_clouds_speed = 20
const water_speed = 500

func _process(delta):
	$Sky.motion_offset.x -= sky_speed * speed_factor * delta 
	$Stars.motion_offset.x -= stars_speed * speed_factor * delta 
	$MediumClouds.motion_offset.x -= medium_cloud_speed * speed_factor * delta
	$FarClouds.motion_offset.x -= far_clouds_speed * speed_factor * delta
	$WaterLevel.motion_offset.x -= water_speed * speed_factor * delta
	$CloserClouds.motion_offset.x -= close_clouds_speed * speed_factor * delta
