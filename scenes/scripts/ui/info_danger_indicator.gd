extends Control

signal danger_displayed

const target_frame : int = 40
const lerp_strength : float = 0.95

@onready var left_label = $DangerOnRight/DangerLabel
@onready var left_danger = $DangerOnLeft
@onready var right_label = $DangerOnLeft/DangerLabel
@onready var right_danger = $DangerOnRight

var side
var side_label
var frames_passed : int
var activated : bool = false

func _physics_process(delta):
	if activated:
		frames_passed += 1
		if frames_passed == target_frame:
			frames_passed = 0
			print('frame limit reached')
			if side_label.visible:
				$DangerOnRight/DangerLabel.visible = false
				$DangerOnLeft/DangerLabel.visible = false
			else: 
				$DangerOnRight/DangerLabel.visible = true
				$DangerOnLeft/DangerLabel.visible = true
	
func display_danger(
		left : bool = true, 
		timeout : float = 4, 
		modulate_color : Color = Color.WHITE
	):
	
	if left:
		side = left_danger
		side_label = left_label
	else:
		side = right_danger
		side_label = right_label
	
	side.modulate = modulate_color
	side.visible = true
	print(Options.photosens_mode)
	if !Options.photosens_mode: activated = true
	
	await get_tree().create_timer(timeout, false).timeout
	side.visible = false
	activated = false
	
	danger_displayed.emit()
