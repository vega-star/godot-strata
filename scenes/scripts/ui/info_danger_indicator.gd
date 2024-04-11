extends Control

signal danger_displayed

const target_frame : int = 40
const lerp_strength : float = 0.95

@onready var left_label = $DangerOnRight/DangerLabel
@onready var left_danger = $DangerOnLeft
@onready var right_label = $DangerOnLeft/DangerLabel
@onready var right_danger = $DangerOnRight
@onready var top_danger = $DangerOnTop
@onready var top_label = $DangerOnTop/DangerLabel
@onready var bottom_danger = $DangerOnBottom
@onready var bottom_label = $DangerOnBottom/DangerLabel

var can_emit : bool = true
var side
var side_label
var frames_passed : int
var activated : bool = false

## Not sure why I did that, sleep deprivation probably. There's no need for it
#func _physics_process(delta):
#	if activated:
#		frames_passed += 1
#		if frames_passed == target_frame:
#			frames_passed = 0
#			if side_label.visible:
#				$DangerOnRight/DangerLabel.visible = false
#				$DangerOnLeft/DangerLabel.visible = false
#			else: 
#				$DangerOnRight/DangerLabel.visible = true
#				$DangerOnLeft/DangerLabel.visible = true
	
func display_danger(
		direction : bool,
		horizontal : bool = true,
		timeout : float = 4, 
		modulate_color : Color = Color.WHITE
	):
	
	if !can_emit: return
	
	if horizontal: ## Left and right
		if direction: # Left
			side = left_danger
			side_label = left_label
		else: # Right
			side = right_danger
			side_label = right_label
	else: ## Top and bottom
		if direction: # Top
			side = top_danger
			side_label = top_label
		else: # Bottom
			side = bottom_danger
			side_label = bottom_label
	
	side.modulate = modulate_color
	side.visible = true
	self.visible = true
	
	if !Options.photosens_mode: activated = true # Don't flicker if photosens is active
	
	await get_tree().create_timer(timeout, false).timeout
	side.visible = false
	self.visible = false
	activated = false
	
	danger_displayed.emit()
