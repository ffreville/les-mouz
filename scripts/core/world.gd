class_name World
extends Node2D
## Assemble le monde au démarrage : maison, navigation, objets et personnages.
## Sert aussi d'annuaire (liste des objets et des personnages) pour les autres scripts.

@export var layout: HouseLayout
## Un personnage est créé par fiche, sur les points d'apparition du plan.
@export var character_profiles: Array[CharacterProfile] = []
@export var character_scene: PackedScene

var characters: Array[Character] = []

@onready var house_view: HouseView = $HouseView
@onready var navigation: GridNavigation = $Navigation
@onready var selection: SelectionManager = $Selection
@onready var characters_root: Node2D = $Characters


func _ready() -> void:
	house_view.render(layout)
	_build_navigation()
	_spawn_characters()
	if not characters.is_empty():
		# Différé pour que l'interface soit prête à recevoir le signal de sélection.
		selection.select.call_deferred(characters[0])


func _build_navigation() -> void:
	navigation.setup(layout.grid_size, layout.cell_size)
	for y in layout.grid_size.y:
		for x in layout.grid_size.x:
			var cell := Vector2i(x, y)
			if layout.is_wall(cell):
				navigation.set_blocked(cell, true)


func _spawn_characters() -> void:
	for i in character_profiles.size():
		var character: Character = character_scene.instantiate()
		characters_root.add_child(character)
		var spawn := layout.character_spawns[i % layout.character_spawns.size()]
		character.setup(self, character_profiles[i], spawn)
		characters.append(character)


## Le personnage sous cette position (monde), ou null.
func get_character_at(world_position: Vector2) -> Character:
	for character in characters:
		if character.contains_point(world_position):
			return character
	return null
