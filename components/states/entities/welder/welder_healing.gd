extends State

## Healing
# Waits for gun to finish healing and listen to changes in the enemy itself

@onready var healing_gun = $"../../HealingGun"
@onready var update = $"../Update"

const max_healing : int = 3
const check_cooldown : int = 5
var frame_count : int = 0
var check_available : bool = true
var healing_left : int = max_healing

func _ready():
	healing_gun.focus_changed.connect(_on_healing_focus_changed)

func enter():
	healing_gun.shoot_lock = false

func _on_healing_focus_changed():
	healing_gun.shoot_lock = true
	transitioned.emit(self, "charge")

func exit(): 
	healing_left -= 1
	update.updates_left -= 1
