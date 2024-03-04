extends Control

@export var text : RichTextLabel
@export var container : VBoxContainer
var credits : Dictionary = {
	"Caio": {
		"icon": null,
		"title": "Programmer, & concept artist",
		"name": "Caio Vianna Vieira"
	},
	"Nath": {
		"icon": null,
		"title": "Designer & UI artist",
		"name": "Nathália Joana de Barros Barbosa"
	}
}


# Called when the node enters the scene tree for the first time.
func _ready():
	for names in credits:
		container.call_deferred("add_child", )
