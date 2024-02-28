extends CanvasLayer

@export var limit_hp_slots = 3
@export var limit_secondary_ammo = 5
@export var debug : bool = false

@onready var hud_elements_list : Dictionary = {
	"hp": {
		"cell_container": $HP/HP_Container, 
		"short_cell_container": $HP/HP_ShortContainer,
		"cell_bar": $HUD/HP_Bar,
		"short_cell_bar": $HUD/HP_ShortBar,
		"cell_size": 52,
		"short_cell_size": 26,
		"start_position": 8,
		"has_start_sprite": true, "start_sprite": $HP/HP_StartSprite,
		"has_end_sprite": true, "end_sprite": $HP/HP_EndSprite
		},
	"secondary_ammo": {
		"cell_container": $SecondaryAmmo/SecondaryAmmo_Container, 
		"short_cell_container": $SecondaryAmmo/SecondaryAmmo_ShortContainer,
		"cell_bar": $SecondaryAmmo/SecondaryAmmo_Bar,
		"short_cell_bar": $SecondaryAmmo/SecondaryAmmo_ShortBar,
		"cell_size": 22,
		"short_cell_size": 11,
		"start_position": 0,
		"has_end_sprite": false,
		"has_start_sprite": false
	}
}

@onready var stage_progress_bar = $ProgressBar/StageProgressBar

@onready var set_hp:
	set(hp_value):
		hud_constructor(hud_elements_list["hp"], hp_value, limit_hp_slots)

@onready var set_ammo:
	set(secondary_ammo):
		hud_constructor(hud_elements_list["secondary_ammo"], secondary_ammo, limit_secondary_ammo)

@onready var stage_progress = stage_progress_bar: # Recieves and updates stage progress on hud bar
	set(progress_value):
		stage_progress_bar.value = progress_value

func _ready():
	## Sets the progress bar max value equal to the stage total time
	stage_progress_bar.set_max($"../../StageManager".stage_length_in_minutes * 60)
	Profile.statistics_changed.connect(update_ui_elements)
	update_hud()

var hud_constructed : bool = false
func hud_constructor(hud_element, set_value, limit):
	if debug: print('{0} | VALUE: {1}'.format({0:hud_element,1:set_value}))
	
	## Building the containers
	# Containers are positioned over or behind bars and are just cosmetic. They aren't supposed to change much during a stage
	# However, they need to change if the player catches an empty HP container to raise its max HP, so an update_hud function to switch the boolean below works just fine.
	if !hud_constructed:
		if set_value <= limit: # If the value is lower than limit, construct bar without short containers.
			hud_element["cell_container"].position.x = hud_element["start_position"]
			hud_element["cell_container"].size.x = hud_element["cell_size"] * set_value
			hud_element["short_cell_container"].visible = false
			if hud_element["has_end_sprite"]: hud_element["end_sprite"].position.x = hud_element["start_position"] + (hud_element["cell_size"] * set_value)
		else: # Else, the overflow value will become short containers to shorten occupied screen area
			hud_element["cell_container"].size.x = hud_element["cell_size"] * limit
			hud_element["short_cell_container"].visible = true
			hud_element["short_cell_container"].size.x = hud_element["short_cell_size"] * (set_value - limit)
			hud_element["short_cell_container"].position.x = hud_element["cell_container"].position.x + hud_element["cell_size"] * limit
			if hud_element["has_end_sprite"]: hud_element["end_sprite"].position.x = hud_element["start_position"] + (hud_element["cell_size"] * limit) + hud_element["short_cell_size"] * (set_value - limit)
		hud_constructed = true
	
	## Resizing bars
	if set_value <= limit: # Set current value on active bar
		hud_element["cell_bar"].size.x = set_value * hud_element["cell_size"]
		hud_element["short_cell_bar"].visible = false
	else:
		hud_element["cell_bar"].size.x = hud_element["cell_size"] * limit
		hud_element["short_cell_bar"].visible = true
		hud_element["short_cell_bar"].size.x = hud_element["short_cell_size"] * (set_value - limit)
		hud_element["short_cell_bar"].position.x = hud_element["start_position"] + hud_element["cell_size"] * limit
	
	if debug: print('{0} | CONTAINER_SIZE\n{1} | SHORT_CONTAINER_SIZE'.format({0:hud_element["cell_container"].size.x,1:hud_element["short_cell_container"].size.x}))
	if debug: print('{0} | BAR_SIZE\n{1} | SHORT_BAR_SIZE'.format({0:hud_element["cell_bar"].size.x,1:hud_element["short_cell_bar"].size.x}))

func update_hud():
	set_hp = Profile.current_run_data.get_value("INVENTORY", "MAX_HEALTH")
	hud_constructed = false
	set_ammo = Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO")
	hud_constructed = false

func update_ui_elements():
	var score = Profile.current_run_data.get_value("STATISTICS", "SCORE")
	$ScoreBar.text = "SCORE: " + str(score)
