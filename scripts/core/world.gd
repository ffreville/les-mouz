class_name World
extends Node2D
## Assemble le monde au démarrage : maison, navigation, objets et personnages.
## Sert aussi d'annuaire (liste des objets et des personnages) pour les autres scripts.

@export var layout: HouseLayout

@onready var house_view: HouseView = $HouseView


func _ready() -> void:
	house_view.render(layout)
