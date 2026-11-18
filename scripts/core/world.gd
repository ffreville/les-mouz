class_name World
extends Node2D
## Assemble le monde : terrain, navigation, objets et personnages.
## Sert aussi d'annuaire (liste des objets et des personnages) pour les autres scripts.

## Terrain d'une nouvelle partie. Il est copié : la partie modifie la copie, pas le fichier.
@export var starting_lot: Lot
## Reprendre et sauvegarder la partie (désactivé par les tests, pour ne pas toucher à la vraie partie).
@export var use_save: bool = true
## Un personnage est créé par fiche, sur les cases de départ du terrain.
@export var character_profiles: Array[CharacterProfile] = []
@export var character_scene: PackedScene
@export var smart_object_scene: PackedScene
## Actions possibles entre deux personnages (ex. « Discuter »).
@export var social_actions: Array[ActionDefinition] = []

## Le terrain en cours de partie.
var lot: Lot
var characters: Array[Character] = []
var smart_objects: Array[SmartObject] = []

@onready var floor_view: FloorView = $FloorView
@onready var wall_view: WallView = $WallView
@onready var navigation: GridNavigation = $Navigation
@onready var selection: SelectionManager = $Selection
@onready var characters_root: Node2D = $Characters
@onready var objects_root: Node2D = $Objects
@onready var grid_overlay: GridOverlay = $GridOverlay
@onready var editor: LotEditor = $LotEditor
@onready var build_controller: BuildController = $BuildController
@onready var buy_controller: BuyController = $BuyController
@onready var camera: CameraController = %Camera
@onready var auto_saver: AutoSaver = $AutoSaver


func _ready() -> void:
	var saved := SaveSystem.load_game() if use_save else null
	if saved != null:
		lot = saved.lot
		Wallet.set_funds(saved.funds)
		GameClock.restore(saved.total_minutes)
	else:
		lot = starting_lot.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)
	editor.setup(self)
	if use_save:
		auto_saver.setup(self)
	build_controller.setup(editor)
	buy_controller.setup(editor)
	camera.set_bounds(Rect2(Vector2.ZERO, Vector2(lot.size * lot.cell_size)))
	refresh_lot()
	# Connecté avant la création des personnages : le monde se met à jour avant leurs files.
	EventBus.lot_changed.connect(refresh_lot)
	_spawn_characters()
	if not characters.is_empty():
		# Différé pour que l'interface soit prête à recevoir le signal de sélection.
		selection.select.call_deferred(characters[0])
	# Sur un terrain encore vide, on commence par construire.
	if lot.walls.is_empty() and lot.objects.is_empty():
		GameMode.set_mode.call_deferred(GameMode.Mode.BUILD)


## Redessine le terrain, synchronise les objets et recalcule la navigation.
func refresh_lot() -> void:
	floor_view.render(lot)
	wall_view.render(lot)
	grid_overlay.render(lot)
	_sync_objects()
	_build_navigation()


## Crée les nœuds des objets ajoutés au terrain et retire ceux qui n'y sont plus.
func _sync_objects() -> void:
	var existing: Dictionary[PlacedObject, SmartObject] = {}
	for smart_object in smart_objects.duplicate():
		if smart_object.placed in lot.objects:
			existing[smart_object.placed] = smart_object
		else:
			smart_objects.erase(smart_object)
			smart_object.queue_free()
	for placed in lot.objects:
		if existing.has(placed):
			existing[placed].setup(placed, lot.cell_size)
			continue
		var smart_object: SmartObject = smart_object_scene.instantiate()
		objects_root.add_child(smart_object)
		smart_object.setup(placed, lot.cell_size)
		smart_objects.append(smart_object)


## Les objets solides rendent leurs cases inaccessibles.
func _build_navigation() -> void:
	var blocked: Array[Vector2i] = []
	for placed in lot.objects:
		if not placed.definition.blocks_movement:
			continue
		var rect := placed.footprint()
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				blocked.append(Vector2i(x, y))
	navigation.setup(lot, blocked)


func _spawn_characters() -> void:
	for i in character_profiles.size():
		var character: Character = character_scene.instantiate()
		characters_root.add_child(character)
		# Un meuble a pu être posé sur la case de départ : on prend la plus proche qui est libre.
		var spawn := navigation.nearest_walkable(lot.spawn_cells[i % lot.spawn_cells.size()])
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
