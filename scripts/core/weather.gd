class_name Weather
extends Node
## Les saisons et la météo (enfant du monde).
##  - L'année a 4 saisons de SEASON_DAYS jours : printemps, été, automne, hiver (le jour 1 est le
##    premier jour du printemps).
##  - Le temps change toutes les SLOT_HOURS heures : soleil, nuageux, pluie, orage, neige (l'hiver)
##    ou canicule (l'été), selon les chances de la saison (ODDS). Chaque journée a sa tendance,
##    que la plupart des tranches suivent. Le tirage dépend du quartier (`weather_seed`) : tout le
##    quartier a le même temps, et les prévisions sont fiables.
##  - Effets : la pluie arrose le jardin, la canicule l'assèche, l'hiver le met au repos ; dehors,
##    la pluie et la neige empêchent les activités et font baisser Hygiène, Plaisir ou Énergie de
##    ceux qui y restent ; le soleil fait plaisir. L'hiver interdit la piscine, le transat veut du
##    soleil. Le chauffage alourdit les factures en automne et en hiver (voir Bills).
##  - La neige tient au sol (`snow`, de 0 à 1) et fond quand elle s'arrête. Sur une bonne couche,
##    on fait un bonhomme de neige (téléphone du Mouz), qui fond avec elle.
##  - Pendant un orage, la foudre peut tomber sur un arbre et y mettre le feu (voir Mishaps).

## Le temps a changé, ou la saison.
signal changed
## Un éclair (pour l'éclat dans le ciel).
signal lightning

const SEASONS: Array[StringName] = [&"printemps", &"ete", &"automne", &"hiver"]
const SEASON_NAMES := {&"printemps": "Printemps", &"ete": "Été", &"automne": "Automne", &"hiver": "Hiver"}
const SEASON_DAYS := 7
const SLOT_HOURS := 6
const KIND_NAMES := {&"soleil": "Soleil", &"nuageux": "Nuageux", &"pluie": "Pluie", &"orage": "Orage",
		&"neige": "Neige", &"canicule": "Canicule"}
## Chances de chaque temps selon la saison (poids).
const ODDS := {
	&"printemps": {&"soleil": 40, &"nuageux": 30, &"pluie": 25, &"orage": 5},
	&"ete": {&"soleil": 50, &"canicule": 20, &"nuageux": 15, &"pluie": 5, &"orage": 10},
	&"automne": {&"soleil": 20, &"nuageux": 35, &"pluie": 35, &"orage": 10},
	&"hiver": {&"soleil": 20, &"nuageux": 35, &"neige": 35, &"pluie": 10},
}
## Part des tranches qui suivent la tendance du jour.
const DAY_TREND := 0.65
## Température : base de la saison, écart selon le temps, et la nuit plus fraîche.
const SEASON_TEMPERATURE := {&"printemps": 14, &"ete": 25, &"automne": 11, &"hiver": 1}
const KIND_TEMPERATURE := {&"soleil": 3, &"nuageux": 0, &"pluie": -2, &"orage": -1, &"neige": -4, &"canicule": 9}
const NIGHT_TEMPERATURE := -5
## Teinte du ciel (multipliée à celle de l'heure, voir DayNight).
const SKY_TINT := {&"soleil": Color(1, 1, 1), &"nuageux": Color(0.92, 0.93, 0.96), &"pluie": Color(0.8, 0.84, 0.92),
		&"orage": Color(0.66, 0.68, 0.8), &"neige": Color(0.94, 0.96, 1.0), &"canicule": Color(1.0, 0.97, 0.9)}
## Jardin : vitesse de pousse selon la saison (dehors).
const GROWTH := {&"printemps": 1.3, &"ete": 1.0, &"automne": 0.7, &"hiver": 0.0}
## Effets sur les besoins de ceux qui restent dehors, par heure.
const OUTDOOR_NEEDS := {
	&"soleil": {&"plaisir": 2.0},
	&"pluie": {&"hygiene": -6.0, &"plaisir": -4.0},
	&"orage": {&"hygiene": -8.0, &"plaisir": -6.0},
	&"neige": {&"energie": -4.0, &"plaisir": -2.0},
	&"canicule": {&"energie": -6.0},
}
## Neige au sol : ce qui tombe et ce qui fond par heure ; il en faut SNOWMAN_SNOW pour un bonhomme.
const SNOW_FALL := 0.25
const SNOW_MELT := 0.08
const SNOWMAN_SNOW := 0.3
## Chance par heure d'orage que la foudre tombe sur un arbre.
const LIGHTNING_FIRE := 0.04
## Actions qu'on fait dehors même sous la pluie.
const ALL_WEATHER: Array[StringName] = [&"faire_bonhomme_neige", &"eteindre_feu", &"eponger", &"reparer"]
const SWIM_ACTIONS: Array[StringName] = [&"nager", &"plonger"]
const SNOWMAN := preload("res://data/catalog/objects/bonhomme_neige.tres")
const BUILD_SNOWMAN := preload("res://data/actions/faire_bonhomme_neige.tres")

## Graine du tirage (celle du quartier, voir `setup`).
static var weather_seed := 1
## Temps imposé (tests, essais) ; vide : le temps tiré au sort.
static var forced_kind := &""

var world: World
## Couche de neige au sol, de 0 à 1.
var snow := 0.0
var _kind := &""
var _season := &""
## Cases intérieures par niveau (recalculées quand le terrain change).
var _interior: Dictionary[int, Dictionary] = {}
var _rng := RandomNumberGenerator.new()


func setup(p_world: World) -> void:
	world = p_world
	_rng.randomize()
	weather_seed = _neighborhood_seed()
	_kind = kind()
	_season = season()
	_warm_season()
	# Image du bonhomme chargée avant d'être dessinée (sinon blanche à la première image).
	SNOWMAN.get_view(SNOWMAN.default_collection(), 2)
	GameClock.ticked.connect(_on_ticked)
	EventBus.lot_changed.connect(func() -> void: _interior.clear())
	EventBus.action_finished.connect(_on_action_ended)
	EventBus.action_cancelled.connect(_on_action_ended)


func _neighborhood_seed() -> int:
	if not world.use_save or SaveManager.neighborhood.is_empty():
		return 1
	if not SaveManager.neighborhood.has("weather_seed"):
		SaveManager.neighborhood["weather_seed"] = randi() % 1000000
	return int(SaveManager.neighborhood["weather_seed"])


# --- Calendrier et prévisions ---------------------------------------------------------------

static func season_of(day: int) -> StringName:
	return SEASONS[posmod((day - 1) / SEASON_DAYS, SEASONS.size())]


static func season() -> StringName:
	return season_of(GameClock.get_day())


## Jour dans la saison (1 à SEASON_DAYS).
static func day_in_season(day: int) -> int:
	return posmod(day - 1, SEASON_DAYS) + 1


static func slot_of(minutes: float) -> int:
	return int(minutes / (SLOT_HOURS * 60.0))


## Le temps qu'il fait pendant cette tranche de SLOT_HOURS heures.
static func kind_at(slot: int) -> StringName:
	var day := slot * SLOT_HOURS / 24 + 1
	var odds: Dictionary = ODDS[season_of(day)]
	var trend := _pick(odds, hash([weather_seed, "jour", day]))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([weather_seed, "tranche", slot])
	return trend if rng.randf() < DAY_TREND else _pick(odds, rng.randi())


static func _pick(odds: Dictionary, roll_seed: int) -> StringName:
	var rng := RandomNumberGenerator.new()
	rng.seed = roll_seed
	var total := 0
	for weight in odds.values():
		total += int(weight)
	var roll := rng.randi_range(1, total)
	for kind_id in odds:
		roll -= int(odds[kind_id])
		if roll <= 0:
			return kind_id
	return odds.keys()[0]


## Le temps qu'il fait maintenant.
static func kind() -> StringName:
	return forced_kind if forced_kind != &"" else kind_at(slot_of(GameClock.total_minutes))


## Température (°C) à cette minute de jeu.
static func temperature_at(minutes: float) -> int:
	var day := int(minutes / GameClock.MINUTES_PER_DAY) + 1
	var hour := fmod(minutes, GameClock.MINUTES_PER_DAY) / 60.0
	var value: int = SEASON_TEMPERATURE[season_of(day)] + KIND_TEMPERATURE[kind_at(slot_of(minutes))]
	if hour < 7.0 or hour >= 21.0:
		value += NIGHT_TEMPERATURE
	return value


static func is_wet(kind_id: StringName) -> bool:
	return kind_id in [&"pluie", &"orage", &"neige"]


## « Printemps, jour 3 » : la saison et le jour dans la saison.
static func season_text() -> String:
	return "%s, jour %d" % [SEASON_NAMES[season()], day_in_season(GameClock.get_day())]


## Les prochaines tranches : [{ "label": « cet après-midi », « demain matin »…, "kind" }].
const TODAY_PARTS := ["cette nuit", "ce matin", "cet après-midi", "ce soir"]
const TOMORROW_PARTS := ["la nuit prochaine", "demain matin", "demain après-midi", "demain soir"]


static func forecast(count := 4) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var slot := slot_of(GameClock.total_minutes)
	var today := GameClock.get_day()
	for i in range(1, count + 1):
		var next := slot + i
		var day := next * SLOT_HOURS / 24 + 1
		var part := posmod(next * SLOT_HOURS / 6, 4)
		var when: String = TODAY_PARTS[part] if day == today else TOMORROW_PARTS[part] if day == today + 1 \
				else "jour %d" % day
		result.append({"label": when, "kind": kind_at(next)})
	return result


# --- Effets ---------------------------------------------------------------------------------

## Multiplie la teinte du ciel (voir DayNight).
func sky_tint() -> Color:
	return SKY_TINT.get(_kind, Color.WHITE)


func current() -> StringName:
	return _kind


func is_raining() -> bool:
	return _kind in [&"pluie", &"orage"]


## Vrai si la case (de ce niveau) est dehors : hors de toute pièce fermée.
func is_outdoor_cell(cell: Vector2i, level := 0) -> bool:
	if not _interior.has(level):
		_interior[level] = world.lot.interior_cells(level)
	return not _interior[level].has(cell)


func is_outdoor(smart_object: SmartObject) -> bool:
	return is_outdoor_cell(smart_object.footprint.position, smart_object.level)


## Vitesse de pousse d'une plantation (la saison ne compte que dehors).
func growth_factor(outdoor: bool) -> float:
	return GROWTH[season()] if outdoor else 1.0


## Vitesse à laquelle une plantation perd son eau (négative : la pluie l'arrose).
func water_factor(outdoor: bool) -> float:
	if not outdoor:
		return 1.0
	if is_raining():
		return -24.0
	match _kind:
		&"canicule":
			return 2.0
		&"neige":
			return 0.0
	return 0.5 if season() == &"hiver" else 1.0


## Pourquoi le temps empêche cette action sur cet objet ("" s'il ne l'empêche pas).
func problem_for(smart_object: SmartObject, action: ActionDefinition) -> String:
	if action.id in ALL_WEATHER:
		return ""
	if action.id == &"observer_etoiles" and (is_wet(_kind) or _kind == &"nuageux"):
		return "ciel couvert"
	if not is_outdoor(smart_object):
		return ""
	if action.id in SWIM_ACTIONS and season() == &"hiver":
		return "trop froid"
	if action.id == &"bronzer" and (season() == &"hiver" or not _kind in [&"soleil", &"canicule"]):
		return "pas de soleil"
	match _kind:
		&"pluie":
			return "il pleut"
		&"orage":
			return "orage"
		&"neige":
			return "il neige"
	return ""


# --- Bonhomme de neige ----------------------------------------------------------------------

## Pourquoi ce Mouz ne peut pas faire de bonhomme de neige ("" s'il peut).
func snowman_problem(character: Character) -> String:
	if snow < SNOWMAN_SNOW:
		return "pas assez de neige"
	if _snowman_cell(character) == GridNavigation.NO_CELL:
		return "pas de place dehors"
	return ""


## Pose un bonhomme de neige à commencer dehors, près du Mouz, et l'y envoie.
func build_snowman(character: Character) -> bool:
	var cell := _snowman_cell(character)
	if snowman_problem(character) != "" or cell == GridNavigation.NO_CELL:
		return false
	var placed := PlacedObject.new()
	placed.definition = SNOWMAN
	placed.cell = cell
	placed.rotation = 2
	placed.collection = SNOWMAN.default_collection()
	placed.growth = 0.0
	Wallet.stamp(placed, 0)
	world.lot.objects.append(placed)
	EventBus.lot_changed.emit()
	var smart_object := world.smart_object_for(placed)
	if smart_object == null:
		return false
	character.queue.enqueue(QueuedAction.use_object(BUILD_SNOWMAN, smart_object))
	return true


## Case libre du jardin (rez-de-chaussée, sans sol posé ni eau) la plus proche du Mouz, avec de la
## place autour pour s'y mettre.
func _snowman_cell(character: Character) -> Vector2i:
	var navigation := world.navigation
	var here := Levels.flat(character.get_cell())
	var best := GridNavigation.NO_CELL
	var best_distance := INF
	var lot := world.lot
	for y in range(1, lot.size.y - 1):
		for x in range(1, lot.size.x - 1):
			var cell := Vector2i(x, y)
			if not is_outdoor_cell(cell) or lot.pool.has(cell) or lot.floors.has(cell) \
					or not navigation.is_walkable(cell) or lot.blocking_object_at(cell, 0) != null:
				continue
			var distance := Vector2(cell - here).length() + (0.0 if character.level == 0 else 1000.0)
			if distance < best_distance and distance >= 1.0 and _has_room_around(cell):
				best_distance = distance
				best = cell
	return best


func _has_room_around(cell: Vector2i) -> bool:
	for step in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		if world.navigation.is_walkable(cell + step) and not world.lot.pool.has(cell + step):
			return true
	return false


func snowmen() -> Array[SmartObject]:
	var result: Array[SmartObject] = []
	for smart_object in world.smart_objects:
		if smart_object.definition == SNOWMAN:
			result.append(smart_object)
	return result


func _on_action_ended(_character: Node, action: RefCounted) -> void:
	var queued := action as QueuedAction
	if queued.definition == BUILD_SNOWMAN and queued.target_object != null and is_instance_valid(queued.target_object):
		var placed := queued.target_object.placed
		placed.growth = maxf(placed.growth, 100.0 * queued.get_progress())
		queued.target_object.queue_redraw()
		if placed.growth >= 100.0:
			EventBus.notice.emit("Le bonhomme de neige est fini !")


## Images de saison des objets (l'arbre) chargées avant d'être dessinées, et objets redessinés.
func _warm_season() -> void:
	for smart_object in world.smart_objects:
		if smart_object.definition.id in SmartObject.SEASONAL:
			for view_name in [&"haut", &"bas", &"gauche"]:
				MouzLayers.texture(SmartObjectDefinition.VIEW_PATH % [smart_object.definition.id,
						smart_object.placed.get_collection(), view_name, "_" + String(season())])
			smart_object.queue_redraw()


# --- Horloge --------------------------------------------------------------------------------

func _on_ticked(minutes: float) -> void:
	var now_kind := kind()
	var now_season := season()
	if now_season != _season:
		_season = now_season
		_announce_season()
		changed.emit()
	if now_kind != _kind:
		_kind = now_kind
		_announce_kind()
		changed.emit()
	_update_snow(minutes)
	_affect_people(minutes)
	_grow_snowmen()
	if _kind == &"orage" and _rng.randf() < LIGHTNING_FIRE * minutes / 60.0:
		_strike()


func _announce_season() -> void:
	_warm_season()
	match _season:
		&"printemps":
			EventBus.notice.emit("C'est le printemps : le jardin pousse plus vite.")
		&"ete":
			EventBus.notice.emit("C'est l'été : la piscine et le transat vous attendent.")
		&"automne":
			EventBus.notice.emit("C'est l'automne : le chauffage reprend sur les factures.")
		&"hiver":
			EventBus.notice.emit("C'est l'hiver : le jardin se repose et le chauffage coûte plus cher.")


func _announce_kind() -> void:
	match _kind:
		&"pluie":
			EventBus.notice.emit("Il se met à pleuvoir : le jardin est arrosé.")
		&"orage":
			EventBus.notice.emit("Un orage éclate : mieux vaut rester à l'abri.")
		&"neige":
			EventBus.notice.emit("Il neige !")
		&"canicule":
			EventBus.notice.emit("Canicule : il fait très chaud dehors, le jardin a soif.")
		&"soleil":
			EventBus.notice.emit("Le soleil revient.")


func _update_snow(minutes: float) -> void:
	var before := snow
	if _kind == &"neige":
		snow = minf(snow + SNOW_FALL * minutes / 60.0, 1.0)
	elif temperature_at(GameClock.total_minutes) > 0 or is_raining():
		snow = maxf(snow - SNOW_MELT * minutes / 60.0 * (3.0 if is_raining() else 1.0), 0.0)
	if before > 0.0 and snow <= 0.0:
		for snowman in snowmen():
			_remove(snowman.placed)
		changed.emit()
	elif absf(snow - before) > 0.0 and int(snow * 50.0) != int(before * 50.0):
		changed.emit()


func _affect_people(minutes: float) -> void:
	var effects: Dictionary = OUTDOOR_NEEDS.get(_kind, {})
	if effects.is_empty() or (_kind == &"soleil" and season() == &"hiver"):
		return
	for character in world.people:
		if character.is_away() or character.swimmer.active:
			continue
		if not is_outdoor_cell(Levels.flat(character.get_cell()), character.level):
			continue
		for need_id in effects:
			if character.needs.has_need(need_id):
				character.needs.change(need_id, effects[need_id] * minutes / 60.0, false)


## Pendant qu'un Mouz fait un bonhomme de neige, il monte petit à petit.
func _grow_snowmen() -> void:
	for character in world.people:
		var action := character.queue.current()
		if action != null and action.definition == BUILD_SNOWMAN and action.state == QueuedAction.State.RUNNING \
				and action.target_object != null:
			var placed := action.target_object.placed
			var growth := 100.0 * action.get_progress()
			if int(growth / 5.0) != int(placed.growth / 5.0):
				placed.growth = maxf(placed.growth, growth)
				action.target_object.queue_redraw()


## La foudre tombe sur un arbre du jardin, qui prend feu.
func _strike() -> void:
	var trees: Array[SmartObject] = []
	for smart_object in world.smart_objects:
		if smart_object.definition.id == &"arbre" and is_outdoor(smart_object) and not smart_object.placed.is_burning():
			trees.append(smart_object)
	lightning.emit()
	if trees.is_empty():
		return
	world.mishaps.start_fire(trees[_rng.randi_range(0, trees.size() - 1)], null, "La foudre est tombée sur un arbre du jardin !")


func _remove(placed: PlacedObject) -> void:
	if placed in world.lot.objects:
		EventBus.object_displaced.emit(placed)
		world.lot.objects.erase(placed)
		EventBus.lot_changed.emit()
		EventBus.notice.emit("Le bonhomme de neige a fondu.")


func to_dict() -> Dictionary:
	return {"snow": snappedf(snow, 0.001)}


func restore(data: Dictionary) -> void:
	snow = float(data.get("snow", 0.0))
	changed.emit()
