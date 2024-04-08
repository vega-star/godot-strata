extends CanvasLayer

@onready var effect_rect = $EffectRect

const effects : Dictionary = {
	"NO EFFECT": null,
	"FIXED RESSURECT64": "res://assets/shaders/ohdude_palette.gdshader",
	"LIGHT CRT": "res://assets/shaders/retro_effect.gdshader",
	"OLD-SCHOOL CRT": "res://assets/shaders/hvukman_crt.gdshader",
	"VHS EFFECT": "res://assets/shaders/hvukman_vhs.gdshader"
}

func change_effect(effect_name):
	var effect = effects[effect_name]
	if effect is String:
		if !visible: visible = true
		effect_rect.material.set_shader(load(effect))
	else:
		visible = false
	
