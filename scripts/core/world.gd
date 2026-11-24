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

## Marge au-dessus du terrain pour la caméra (hauteur des murs).
const WALL_MARGIN := 80.0

## Le terrain en cours de partie.
var lot: Lot
## La famille jouée.
var characters: Array[Character] = []
## Les voisins en visite (voir Visits).
var visitors: Array[Character] = []
## Tous les Mouz présents : la famille et ses visiteurs (portes, clics, autonomie, relations).
var people: Array[Character] = []
## La famille qui vit ici (prénoms, apparences, liens).
var family: Family
var smart_objects: Array[SmartObject] = []
## Teinte selon l'heure et lumière des objets allumés.
var day_night := DayNight.new()
## Factures et coupure d'électricité.
var bills := Bills.new()
## Visites des voisins.
var visits := Visits.new()

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
	Music.enter_game()
	add_child(day_night)
	add_child(bills)
	bills.setup(self)
	# La famille jouée et son terrain viennent du quartier (SaveManager) ; sans sauvegarde
	# (tests), on prend le terrain et les fiches de la scène.
	var plot := SaveManager.active_plot_data() if use_save else {}
	var household: Dictionary = plot.get("household", {})
	var played_before := household.has("characters")
	var profiles := character_profiles
	if not plot.is_empty():
		lot = LotSerializer.from_data(plot["lot"])
		Wallet.set_funds(int(household.get("funds", Wallet.settings.start_funds)))
		family = Family.from_dict(household.get("family", {}))
		profiles = family.make_profiles()
	else:
		lot = starting_lot.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)
		family = Family.from_profiles(character_profiles)
	editor.setup(self)
	if use_save:
		auto_saver.setup(self)
	build_controller.setup(editor)
	buy_controller.setup(editor)
	# Les murs du haut du terrain montent de 64 px au-dessus de leur ligne.
	camera.set_bounds(Rect2(Vector2(0, -WALL_MARGIN), Vector2(lot.size * lot.cell_size) + Vector2(0, WALL_MARGIN)))
	refresh_lot()
	day_night.setup(self)
	# Connecté avant la création des personnages : le monde se met à jour avant leurs files.
	EventBus.lot_changed.connect(refresh_lot)
	_spawn_characters(profiles)
	if not played_before:
		_apply_family_links()
		# Pas de facture le jour même de l'emménagement.
		bills.last_bill_day = GameClock.get_day()
	if not characters.is_empty():
		# Différé pour que l'interface soit prête à recevoir le signal de sélection.
		selection.select.call_deferred(characters[0])
	add_child(visits)
	visits.setup(self, use_save and not played_before)
	if played_before:
		WorldSerializer.apply_to_world(self, household)
	elif lot.walls.is_empty() and lot.objects.is_empty():
		# Sur un terrain encore vide, on commence par construire.
		GameMode.set_mode.call_deferred(GameMode.Mode.BUILD)


## Redessine le terrain, synchronise les objets et recalcule la navigation.
func refresh_lot() -> void:
	floor_view.render(lot)
	wall_view.render(lot, people)
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


func _spawn_characters(profiles: Array[CharacterProfile]) -> void:
	var used := {}
	for i in profiles.size():
		var character: Character = character_scene.instantiate()
		characters_root.add_child(character)
		# Un meuble a pu être posé sur la case de départ : on prend la plus proche qui est libre,
		# sans mettre deux Mouz sur la même case.
		var spawn := _free_cell_near(lot.spawn_cells[i % lot.spawn_cells.size()], used)
		used[spawn] = true
		character.setup(self, profiles[i], spawn)
		characters.append(character)
		people.append(character)


func _free_cell_near(start: Vector2i, used: Dictionary) -> Vector2i:
	var origin := navigation.nearest_walkable(start)
	for radius in range(0, 6):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var cell := origin + Vector2i(x, y)
				if maxi(absi(x), absi(y)) == radius and not used.has(cell) and navigation.is_walkable(cell):
					return cell
	return origin


## Relations de départ d'une nouvelle famille, selon les liens choisis à la création.
func _apply_family_links() -> void:
	var by_id := {}
	for character in characters:
		by_id[String(character.profile.id)] = character
	for link in family.links:
		if by_id.has(link["a"]) and by_id.has(link["b"]):
			by_id[link["a"]].relationships.restore_with(by_id[link["b"]], Family.LINK_START.get(link["kind"], 0.0))


## Case de la rue par où l'on part et arrive : bas du terrain, sous la première case de départ.
func street_cell() -> Vector2i:
	var spawn: Vector2i = lot.spawn_cells[0] if not lot.spawn_cells.is_empty() else Vector2i.ZERO
	return navigation.nearest_walkable(Vector2i(spawn.x, lot.size.y - 1))


## Le personnage sous cette position (monde), ou null.
func get_character_at(world_position: Vector2) -> Character:
	for character in people:
		if character.contains_point(world_position):
			return character
	return null


## L'objet solide dont l'image est sous cette position (monde), ou null (les tapis sont ignorés).
## En vue trois quarts, un meuble dépasse au-dessus de son emprise : on prend celui de devant.
func get_object_at_point(world_position: Vector2) -> SmartObject:
	var best: SmartObject = null
	for smart_object in smart_objects:
		if not smart_object.definition.blocks_movement or not smart_object.contains_point(world_position):
			continue
		if best == null or smart_object.position.y > best.position.y:
			best = smart_object
	return best


## L'objet solide qui occupe cette case, ou null (les tapis sont ignorés).
func get_object_at_cell(cell: Vector2i) -> SmartObject:
	for smart_object in smart_objects:
		if smart_object.definition.blocks_movement and smart_object.occupies(cell):
			return smart_object
	return null
