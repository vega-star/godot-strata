extends Stage

@onready var cutscene_animation_player = $CutsceneManager/CutsceneAnimationPlayer

func start_stage_sequence(): # Starting animations, fade-in, etc.
	# hud_component.set_ammo = Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO")
	# var player_move_to_action = get_tree().create_tween()
	# player_move_to_action.tween_property(player, "position", player_spawn_pos.global_position, 0.99)	
	var parallax_tween = get_tree().create_tween()
	stage_parallax.speed_factor = 3
	parallax_tween.tween_property(stage_parallax, "speed_factor", 1, 3)
	player.controls_lock(true)
	await UI.fade('IN')
	await get_tree().create_timer(0.5, false).timeout
	UI.InfoHUD.display_title(stage_title, stage_description)
	cutscene_animation_player.play("open_delta")
	await get_tree().create_timer(2, false).timeout
	player.controls_lock(false)
	UI.set_stage(self, stage_timer) ## Start stage info on UI
	stage_started.emit()
	stage_timer.start()
	stage_start_time = Time.get_unix_time_from_system()
