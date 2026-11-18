class_name World
extends Node2D
## Assemble le monde au démarrage : maison, navigation, objets et personnages.
## Sert aussi d'annuaire (liste des objets et des personnages) pour les autres scripts.

@export var layout: HouseLayout
## Un personnage est créé par fiche, sur les points d'apparition du plan.
@export var character_profiles: Array[CharacterProfile] = []
@export var character_scene: PackedScene
@export var smart_object_scene: PackedScene
## Actions possibles entre deux personnages (ex. « Discuter »).
@export var social_actions: Array[ActionDefinition] = []

var characters: Array[Character] = []
var smart_objects: Array[SmartObject] = []

@onready var floor_view: FloorView = $FloorView
@onready var wall_view: WallView = $WallView
@onready var navigation: GridNavigation = $Navigation
@onready var selection: SelectionManager = $Selection
@onready var characters_root: Node2D = $Characters
@onready var objects_root: Node2D = $Objects


func _ready() -> void:
	floor_view.render(layout)
	wall_view.render(layout)
	_spawn_objects()
	_build_navigation()
	_spawn_characters()
	if not characters.is_empty():
		# Différé pour que l'interface soit prête à recevoir le signal de sélection.
		selection.select.call_deferred(characters[0])


## Les meubles qui bloquent le passage rendent leurs cases inaccessibles.
func _build_navigation() -> void:
	var blocked: Array[Vector2i] = []
	for smart_object in smart_objects:
		if not smart_object.definition.blocks_movement:
			continue
		for y in range(smart_object.footprint.position.y, smart_object.footprint.end.y):
			for x in range(smart_object.footprint.position.x, smart_object.footprint.end.x):
				blocked.append(Vector2i(x, y))
	navigation.setup(layout, blocked)


func _spawn_objects() -> void:
	for placement in layout.objects:
		var smart_object: SmartObject = smart_object_scene.instantiate()
		objects_root.add_child(smart_object)
		smart_object.setup(placement.definition, placement.cell, layout.cell_size)
		smart_objects.append(smart_object)


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


## L'objet solide qui occupe cette case, ou null (les tapis sont ignorés).
func get_object_at_cell(cell: Vector2i) -> SmartObject:
	for smart_object in smart_objects:
		if smart_object.definition.blocks_movement and smart_object.occupies(cell):
			return smart_object
	return null
