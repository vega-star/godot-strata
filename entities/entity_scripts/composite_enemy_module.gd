extends Node2D

signal main_loaded
signal cm_weapon_update(self_node)
signal cm_update(self_node, is_active)
signal weapon_toggled

@export var module_sprite : Sprite2D
@export var weapon : Area2D
@export var combat_component : CombatComponent
@export var hitbox_component : HitboxComponent
@export var health_component : HealthComponent

@export var set_health : int
@export var set_health_bar : bool = true
@export var vertical_inversion : bool
@export var has_respawn_limit : bool
@export var weapon_respawn_limit = 100
var weapon_respawn_count : int
@export var weapon_respawn_timeout = 10
var weapon_deactivated : bool = false

func _ready():
	if !health_component: health_component = $HealthComponent
	if !combat_component: combat_component = $CombatComponent
	if !hitbox_component: hitbox_component = $HitboxComponent
	if !module_sprite: module_sprite = $ModuleSprite
	if set_health: health_component.set_max_health = set_health
	
	if vertical_inversion:
		module_sprite.scale.y = -1
		$HitboxComponent/ModuleHitbox.scale.y = -1
		weapon.position.y = -weapon.position.y
	
	if weapon:
		weapon.weapon_destroyed.connect(_on_weapon_destroyed)

func _on_weapon_destroyed(affected_weapon): # Respawn gun if the module is still alive
	if has_respawn_limit: weapon_respawn_count += 1
	
	if weapon_respawn_count == weapon_respawn_limit:
		weapon_deactivated = true
	
	if weapon_respawn_count == weapon_respawn_limit:
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

func die():
	cm_update.emit(self, 0)
