extends "res://scenes/scripts/main/strata_scene.gd"

## Practice Stage function
# Modified version of Tutorial stage, useful for debugging and testing new features
# Also useful for players who want to test previously discovered enemies/items
# Has a wide variety of sliders and buttons divided by tabs

func _ready():
	assert(player!=null)
	
	Options.options_changed.connect(load_options)
	load_options()
	
	player.player_killed.connect(gameoverscreen.game_over_prompt)
	
	start_stage_sequence()
	stage_timer.set_paused(true)
	
	await Signal(stage_manager, "scene_loaded")
