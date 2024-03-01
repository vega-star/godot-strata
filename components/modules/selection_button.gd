class_name SelectionButton extends TextureButton

signal selected(item_id)
signal movement_completed

@onready var item_id
@onready var title : String
@onready var icon
@onready var description : String
@onready var rarity : int

var movement : int = 20
var movement_active : bool = false

func set_button_properties(new_item_id, new_title, new_icon, new_description, new_rarity, update : bool = true):
	item_id = new_item_id
	title = new_title
	icon = new_icon
	description = new_description
	rarity = new_rarity
	
	if update:
		$SelectionTitle.set_text(new_title)
		if new_icon != "":
			$SelectionIcon.set_texture(new_icon)
		else:
			$SelectionIcon.set_texture(load("res://assets/textures/prototypes/player_test_sprite.png"))
		$SelectionDescription.set_text(new_description)
		rarity = new_rarity

func _on_pressed():
	selected.emit(item_id)

func _on_mouse_entered():
	arise(true)

func _on_mouse_exited():
	arise(false)

func arise(mode : bool = true):
	if movement_active:
		await movement_completed
	movement_active = true
	
	var movement_tween = get_tree().create_tween()
	movement_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if mode:
		movement_tween.tween_property(self, "position", Vector2(position.x, position.y - movement), 0.2).set_trans(Tween.TRANS_EXPO)
	else:
		movement_tween.tween_property(self, "position", Vector2(position.x, position.y + movement), 0.2).set_trans(Tween.TRANS_EXPO)
		
	await movement_tween.finished
	movement_active = false
	movement_completed.emit()
