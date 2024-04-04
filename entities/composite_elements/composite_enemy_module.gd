extends HitboxComponent

signal main_loaded
signal cm_weapon_update(self_node)
signal cm_update(self_node, is_active)
signal weapon_toggled

@export var module_sprite : Sprite2D
@export var weapon : Area2D

@export var set_health : int
@export var has_respawn_limit : bool
@export var weapon_respawn_limit = 100
var weapon_respawn_count : int
@export var weapon_respawn_timeout = 10
var weapon_deactivated : bool = false

func _ready():
	if !health_component: health_component = $HealthComponent
	if !combat_component: combat_component = $CombatComponent
	if !module_sprite: module_sprite = $ModuleSprite
	if set_health: health_component.set_max_health = set_health
	
	if override_max_health > 0:
		if !health_component: push_error('%s has override_max_health but no HealthComponent node connected. This is a node misconfiguration.' % owner.name)
		health_component.set_max_health = override_max_health
	
	if weapon:
		weapon.weapon_destroyed.connect(_on_weapon_destroyed)

func _on_weapon_destroyed(affected_weapon): # Respawn gun if the module is still alive
	if has_respawn_limit: weapon_respawn_count += 1
	
	if weapon_respawn_count == weapon_respawn_limit:
		weapon_deactivated = true
		affected_weapon.destroy()
	else:
		affected_weapon.deactivate()
		cm_weapon_update.emit(self, false)
		
		await get_tree().create_timer(weapon_respawn_timeout, false).timeout
		if weapon_deactivated: await weapon_toggled
		
		cm_weapon_update.emit(self, true)
		affected_weapon.reactivate()

func toggle_weaponry(value):
	weapon_deactivated = value
	if value:
		weapon_toggled.emit()

func die(_source):
	cm_update.emit(self, 0)
