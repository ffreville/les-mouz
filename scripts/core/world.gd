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
## Écart d'ordre d'affichage entre deux niveaux (tout un étage passe devant celui du dessous).
const LEVEL_Z := 10
## Voile sur les niveaux du dessous quand on regarde un étage (brief n° 7) : 45 % pour l'étage
## juste en dessous, 60 % deux étages plus bas.
const VEIL_COLOR := Color("#2B2440")
const VEIL_OPACITY := [0.0, 0.45, 0.6]

## Le terrain en cours de partie.
var lot: Lot
## Niveau regardé (0 : rez-de-chaussée). On construit et on achète à ce niveau.
var view_level := 0
## La piscine (rez-de-chaussée).
var pool_view := PoolView.new()
## Un calque par niveau : { "node", "floor", "walls", "objects", "characters" }.
var _layers: Array[Dictionary] = []
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
## Usure et réparation des objets.
var upkeep := Upkeep.new()
## Plantations qui poussent.
var garden := Garden.new()
## Coups durs : feu, inondation, cambriolage.
var mishaps := Mishaps.new()
## Saisons et météo.
var weather := Weather.new()
## Le temps dessiné : saison et neige au sol, pluie et neige qui tombent.
var weather_ground := WeatherGround.new()
var weather_sky := WeatherSky.new()

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
	_make_layers()
	# Les murs du haut du terrain montent de 64 px au-dessus de leur ligne.
	camera.set_bounds(Rect2(Vector2(0, -WALL_MARGIN), Vector2(lot.size * lot.cell_size) + Vector2(0, WALL_MARGIN)))
	add_child(weather)
	weather.setup(self)
	refresh_lot()
	day_night.setup(self)
	# Connecté avant la création des personnages : le monde se met à jour avant leurs files.
	EventBus.lot_changed.connect(refresh_lot)
	GameMode.mode_changed.connect(func(_mode: int) -> void: _apply_view())
	GameMode.wall_mode_changed.connect(func(_wall_mode: int) -> void: _apply_view())
	# La vue suit le Mouz contrôlé quand il est à un autre étage, ou qu'il en change.
	EventBus.character_selected.connect(func(character: Node) -> void: _follow(character))
	EventBus.character_level_changed.connect(_on_character_level_changed)
	_spawn_characters(profiles)
	if not played_before:
		_apply_family_links()
		# Pas de facture le jour même de l'emménagement.
		bills.last_bill_day = GameClock.get_day()
	if not characters.is_empty():
		# Différé pour que l'interface soit prête à recevoir le signal de sélection.
		selection.select.call_deferred(characters[0])
	add_child(upkeep)
	upkeep.setup(self)
	add_child(garden)
	garden.setup(self)
	add_child(visits)
	visits.setup(self, use_save and not played_before)
	add_child(mishaps)
	mishaps.setup(self, not played_before)
	weather_sky.z_index = LEVEL_Z * Levels.COUNT + 5
	add_child(weather_sky)
	weather_sky.setup(self)
	if played_before:
		WorldSerializer.apply_to_world(self, household)
	elif lot.walls.is_empty() and lot.objects.is_empty():
		# Sur un terrain encore vide, on commence par construire.
		GameMode.set_mode.call_deferred(GameMode.Mode.BUILD)


## Redessine le terrain, synchronise les objets et recalcule la navigation.
func refresh_lot() -> void:
	for level in Levels.COUNT:
		_layers[level]["floor"].render(lot, level)
		_layers[level]["walls"].render(lot, people, level)
	grid_overlay.render(lot)
	pool_view.render(lot)
	weather_ground.render(self)
	_sync_objects()
	_build_navigation()
	_apply_view()


# --- Niveaux ---------------------------------------------------------------------------

## Le calque du rez-de-chaussée reprend les nœuds de la scène ; ceux des étages sont créés ici,
## chacun dessiné tout entier au-dessus du précédent.
func _make_layers() -> void:
	for level in Levels.COUNT:
		var node := Node2D.new()
		node.name = "Niveau%d" % level
		node.y_sort_enabled = true
		node.z_index = level * LEVEL_Z
		add_child(node)
		move_child(node, floor_view.get_index())
		var roof := RoofView.new()
		roof.z_index = LEVEL_Z - 2
		node.add_child(roof)
		var veil := Polygon2D.new()
		var area := Rect2(Vector2.ZERO, Vector2(lot.size * lot.cell_size)).grow(FloorView.OUTSIDE_MARGIN)
		veil.polygon = PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end,
				Vector2(area.position.x, area.end.y)])
		veil.z_index = LEVEL_Z - 1
		node.add_child(veil)
		var layer := {"node": node, "veil": veil, "roof": roof}
		if level == 0:
			for part in [floor_view, wall_view, objects_root, characters_root]:
				part.reparent(node, false)
			node.add_child(pool_view)
			node.move_child(pool_view, floor_view.get_index() + 1)
			node.add_child(weather_ground)
			node.move_child(weather_ground, pool_view.get_index() + 1)
			layer.merge({"floor": floor_view, "walls": wall_view, "objects": objects_root, "characters": characters_root})
		else:
			var floor_part := FloorView.new()
			var walls_part := WallView.new()
			walls_part.y_sort_enabled = true
			var objects_part := Node2D.new()
			objects_part.y_sort_enabled = true
			var characters_part := Node2D.new()
			characters_part.y_sort_enabled = true
			for part in [floor_part, walls_part, objects_part, characters_part]:
				node.add_child(part)
			layer.merge({"floor": floor_part, "walls": walls_part, "objects": objects_part, "characters": characters_part})
		_layers.append(layer)


func layer(level: int) -> Dictionary:
	return _layers[clampi(level, 0, Levels.COUNT - 1)]


## Regarde un autre niveau : ceux du dessous restent visibles, voilés ; ceux du dessus disparaissent.
func set_view_level(level: int) -> void:
	level = clampi(level, 0, Levels.COUNT - 1)
	if level == view_level:
		return
	view_level = level
	_apply_view()
	EventBus.view_level_changed.emit(view_level)


func _on_character_level_changed(character: Node, _level: int) -> void:
	if character == selection.selected:
		_follow(character)


func _follow(character: Node) -> void:
	if GameMode.is_live() and character.level != view_level:
		set_view_level(character.level)


func _apply_view() -> void:
	var roofs := GameMode.shows_roofs() and lot.roof != null
	for level in _layers.size():
		var roof: RoofView = _layers[level]["roof"]
		roof.visible = roofs and level <= view_level
		if roof.visible:
			roof.render(lot, level, view_level)
		var node: Node2D = _layers[level]["node"]
		node.visible = level <= view_level
		var veil: Polygon2D = _layers[level]["veil"]
		veil.visible = level < view_level
		veil.color = Color(VEIL_COLOR, VEIL_OPACITY[mini(view_level - level, VEIL_OPACITY.size() - 1)]) \
				if level < view_level else Color.TRANSPARENT
	grid_overlay.show_level(view_level)
	# Grille et aperçus de l'éditeur passent au-dessus du niveau regardé.
	for overlay in [grid_overlay, build_controller, buy_controller]:
		overlay.z_index = view_level * LEVEL_Z + LEVEL_Z - 1


## Crée les nœuds des objets ajoutés au terrain et retire ceux qui n'y sont plus.
func _sync_objects() -> void:
	var placed_levels: Dictionary[PlacedObject, int] = {}
	for entry in lot.all_objects():
		placed_levels[entry[0]] = entry[1]
	var existing: Dictionary[PlacedObject, SmartObject] = {}
	for smart_object in smart_objects.duplicate():
		if placed_levels.has(smart_object.placed):
			existing[smart_object.placed] = smart_object
		else:
			smart_objects.erase(smart_object)
			smart_object.queue_free()
	for placed in placed_levels:
		var level: int = placed_levels[placed]
		if existing.has(placed):
			existing[placed].level = level
			existing[placed].setup(placed, lot.cell_size)
			continue
		var smart_object: SmartObject = smart_object_scene.instantiate()
		smart_object.level = level
		_layers[level]["objects"].add_child(smart_object)
		smart_object.setup(placed, lot.cell_size)
		smart_objects.append(smart_object)


## Les objets solides rendent leurs cases inaccessibles.
func _build_navigation() -> void:
	var blocked: Array[Vector2i] = []
	for entry in lot.all_objects():
		var placed: PlacedObject = entry[0]
		if not placed.definition.blocks_movement:
			continue
		var rect := placed.footprint()
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				blocked.append(Levels.nav(Vector2i(x, y), entry[1]))
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


## Le nœud d'un objet posé (null s'il n'est pas sur le terrain).
func smart_object_for(placed: PlacedObject) -> SmartObject:
	for smart_object in smart_objects:
		if smart_object.placed == placed:
			return smart_object
	return null


## Case de la rue par où l'on part et arrive : bas du terrain, sous la première case de départ.
func street_cell() -> Vector2i:
	var spawn: Vector2i = lot.spawn_cells[0] if not lot.spawn_cells.is_empty() else Vector2i.ZERO
	return navigation.nearest_walkable(Vector2i(spawn.x, lot.size.y - 1))


## Le personnage sous cette position (monde), ou null.
func get_character_at(world_position: Vector2) -> Character:
	for character in people:
		if character.level == view_level and character.contains_point(world_position):
			return character
	return null


## L'objet solide dont l'image est sous cette position (monde), ou null (les tapis sont ignorés).
## En vue trois quarts, un meuble dépasse au-dessus de son emprise : on prend celui de devant.
func get_object_at_point(world_position: Vector2) -> SmartObject:
	var best: SmartObject = null
	for smart_object in smart_objects:
		if smart_object.level != view_level or not smart_object.definition.blocks_movement \
				or not smart_object.contains_point(world_position):
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
