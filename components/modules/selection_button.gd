class_name SelectionButton extends TextureButton

signal selected(item_id)

@onready var item_id
@onready var title : String
@onready var icon
@onready var description : String
@onready var rarity : int

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
