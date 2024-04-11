extends ParallaxBackground

@export var speed_factor : float = 1

const sky_speed = 15
const stars_speed = 5


const far_clouds_speed = 20
const before_far_cloud_speed = 50
const medium_cloud_speed = 50
const close_clouds_speed = 200
const even_closer_speed = 500

func _process(delta):
	$Sky.motion_offset.x -= sky_speed * speed_factor * delta 
	$Stars.motion_offset.x -= stars_speed * speed_factor * delta 
	
	## Clouds
	$FarClouds.motion_offset.x -= far_clouds_speed * speed_factor * delta
	$BeforeFarClouds.motion_offset.x -= before_far_cloud_speed * speed_factor * delta
	$MediumClouds.motion_offset.x -= medium_cloud_speed * speed_factor * delta
	$CloserClouds.motion_offset.x -= close_clouds_speed * speed_factor * delta
	$EvenCloserClouds.motion_offset.x -= even_closer_speed * speed_factor * delta
