class_name SelectionButton extends TextureButton

signal button_set
signal selected(item_id)

@onready var item_id
@onready var title : String
@onready var icon
@onready var description : String
@onready var rarity : int


const rarity_boxes : Array = [
	preload("res://assets/textures/items/frames/box_common.png"),
	preload("res://assets/textures/items/frames/box_uncommon.png"),
	preload("res://assets/textures/items/frames/box_rare.png"),
	preload("res://assets/textures/items/frames/box_superior.png"),
	preload("res://assets/textures/items/frames/box_legendary.png"),
	preload("res://assets/textures/items/frames/box_alien.png"),
	preload("res://assets/textures/items/frames/box_strange.png"),
	preload("res://assets/textures/items/frames/box_unknown.png")
]

## ITEM RARITY TIER CHANGES
const rarity_dict : Dictionary = {
	0: { #? Starter / Normal
		"box_color": Color("#61546a"),
		"box_texture": preload("res://assets/textures/items/frames/box_common.png")
	},
	1: { #? Uncommon
		"box_color": Color("#1c4b3c"),
		"box_texture": preload("res://assets/textures/items/frames/box_uncommon.png")
	},
	2: { #? Rare
		"box_color": Color("#245c5e"),
		"box_texture": preload("res://assets/textures/items/frames/box_rare.png")
	},
	3: { #? Superior
		"box_color": Color("#493369"),
		"box_texture": preload("res://assets/textures/items/frames/box_superior.png")
	},
	4: { #? Legendary
		"box_color": Color("#4c0d28"),
		"box_texture": preload("res://assets/textures/items/frames/box_legendary.png")
	},
	5: { #? Alien
		"box_color": Color("#863f18"),
		"box_texture": preload("res://assets/textures/items/frames/box_alien.png")
	},
	6: { #? Strange
		"box_color": Color("#490425"),
		"box_texture": preload("res://assets/textures/items/frames/box_strange.png")
	},
	7: { #? Unknown
		"box_color": Color("#340238"),
		"box_texture": preload("res://assets/textures/items/frames/box_unknown.png")
	},
}

var movement : int = 20
var movement_time : float = 0.2
var movement_active : bool = false
var initial_y : int
var target_y : int

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
	
	
	$ButtonColor.set_color(rarity_dict[rarity]["box_color"])
	$ButtonPatchRect.set_texture(rarity_dict[rarity]["box_texture"])
	
	button_set.emit()

func _ready():
	initial_y = position.y
	target_y = position.y - movement

func _on_pressed():
	selected.emit(item_id)

# Focus in
func _on_mouse_entered(): arise(true)
func _on_focus_entered(): arise(true)

# Focus out
func _on_mouse_exited(): arise(false)
func _on_focus_exited(): arise(false)

func arise(mode : bool = true):
	var movement_tween = get_tree().create_tween()
	movement_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if mode:
		movement_tween.tween_property(self, "position", Vector2(position.x, target_y), movement_time).set_trans(Tween.TRANS_EXPO)
	else:
		movement_tween.tween_property(self, "position", Vector2(position.x, initial_y), movement_time).set_trans(Tween.TRANS_EXPO)
	await movement_tween.finished



