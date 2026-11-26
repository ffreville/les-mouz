class_name Mishaps
extends Node
## Les coups durs (enfant du monde).
##  - Le feu : cuisiner (cuisinière, barbecue) peut mettre le feu, d'autant plus qu'on cuisine mal
##    (compétence Cuisine) et que l'appareil est usé. Le feu gagne les objets voisins. Un détecteur
##    de fumée prévient tout de suite les pompiers ; sans lui, ce sont les voisins, au bout de
##    NEIGHBORS_CALL_MINUTES. Les pompiers arrivent FIREMEN_DELAY minutes après l'appel, éteignent
##    tout et envoient leur facture (FIREMEN_FEE). Un Mouz peut éteindre le feu lui-même : à coup
##    sûr avec un extincteur à son étage, sinon une fois sur deux. Ce qui a brûlé tombe en panne.
##  - L'inondation : une machine à laver ou un lave-vaisselle usé peut fuir à la fin d'un lavage.
##    Il tombe en panne et laisse des flaques autour de lui. On les éponge ; celles qui restent
##    PUDDLE_DAMAGE_HOURS heures abîment le sol (facture « Dégâts des eaux »).
##  - Le cambriolage : certaines nuits, un cambrioleur arrive par la rue et emporte l'objet le plus
##    cher qu'il peut porter. Une alarme le fait fuir, et la police verse une prime.
## Les objets de sécurité (détecteur, extincteur, alarme) sont dans la catégorie « Sécurité ».

const EXTINGUISH := preload("res://data/actions/eteindre_feu.tres")
const MOP := preload("res://data/actions/eponger.tres")

# --- Feu ---
## Objets où l'on cuisine, qui peuvent prendre feu.
const FIRE_OBJECTS: Array[StringName] = [&"cuisiniere", &"barbecue"]
## Chance de feu par repas : base, moins par niveau de Cuisine, plus si l'appareil est usé.
const FIRE_BASE_CHANCE := 0.08
const FIRE_LEVEL_CHANCE := 0.007
const FIRE_WORN_CHANCE := 0.05
## Toutes les SPREAD_MINUTES, chaque feu a SPREAD_CHANCE de gagner un objet voisin.
const SPREAD_MINUTES := 20.0
const SPREAD_CHANCE := 0.4
const NEIGHBORS_CALL_MINUTES := 60.0
const FIREMEN_DELAY := 20.0
const FIREMEN_FEE := 400
## Sans extincteur, chance d'éteindre le feu soi-même.
const EXTINGUISH_CHANCE := 0.5
## Plaisir perdu par chaque Mouz de la famille quand le feu prend.
const FIRE_FRIGHT := -15.0

# --- Inondation ---
const FLOOD_OBJECTS: Array[StringName] = [&"machine_laver", &"lave_vaisselle"]
## Au-delà de l'usure Upkeep.WORN, chance de fuite = (usure - WORN) × FLOOD_RATE.
const FLOOD_RATE := 0.01
const PUDDLES := Vector2i(3, 5)
const PUDDLE_DAMAGE_HOURS := 12.0
const PUDDLE_DAMAGE := 40

# --- Cambriolage ---
## Heures de la nuit où il peut venir ; une seule tentative par nuit.
const BURGLARY_HOURS := Vector2i(1, 4)
## Chance par nuit, plus un supplément selon la valeur de la maison (jusqu'à BURGLARY_VALUE_CHANCE).
const BURGLARY_CHANCE := 0.1
const BURGLARY_VALUE_CHANCE := 0.1
const BURGLARY_VALUE_REF := 60000.0
## Jours sans cambriolage après le précédent (et après l'emménagement).
const BURGLARY_REST_DAYS := 4
const STEAL_MINUTES := 15.0
## Ce qu'un cambrioleur peut emporter (il prend le plus cher).
const STEALABLE: Array[StringName] = [&"tele", &"ordinateur", &"console_jeux", &"chaine_hifi", &"micro_ondes",
		&"machine_cafe", &"telescope", &"chevalet", &"horloge", &"lampe_pied", &"lampe_chevet", &"plante",
		&"fauteuil", &"table_jeux", &"table_nuit"]
const POLICE_REWARD := 100
const BURGLAR_OUTFIT := Color("#3D3357")
const BURGLAR_PANTS := Color("#2B2440")
## Au-delà, il est reparti (minutes de jeu).
const BURGLAR_MAX_MINUTES := 120.0

enum Burglary { NONE, COMING, STEALING, LEAVING }

var world: World
## Minute de jeu où les pompiers arrivent (0 : pas appelés), où les voisins les appellent (0 : non).
var firemen_at := 0.0
var neighbors_call_at := 0.0
var last_burglary_day := 0
## Dernière nuit où l'on a tiré au sort un cambriolage.
var checked_night := 0
var _burglar: Character
var _burglar_target: SmartObject
var _burglary := Burglary.NONE
var _burglary_started := 0.0
var _steal_until := 0.0
var _burglar_move: QueuedAction
## Repas qui vont mal tourner : action → minute de l'action où le feu prend.
var _fire_plans: Dictionary[QueuedAction, float] = {}
var _spread_time := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_world: World, just_moved_in: bool) -> void:
	world = p_world
	_rng.randomize()
	if just_moved_in:
		last_burglary_day = GameClock.get_day()
	GameClock.ticked.connect(_on_ticked)
	GameClock.minute_changed.connect(_on_minute_changed)
	EventBus.action_started.connect(_on_action_started)
	EventBus.action_finished.connect(_on_action_finished)
	EventBus.action_cancelled.connect(_on_action_cancelled)


# --- Feu -----------------------------------------------------------------------------------

## Chance qu'un repas fait par ce Mouz sur cet objet mette le feu.
static func fire_chance(cooking_level: int, smart_object: SmartObject) -> float:
	var chance := FIRE_BASE_CHANCE - FIRE_LEVEL_CHANCE * cooking_level
	if smart_object.placed.wear >= Upkeep.WORN:
		chance += FIRE_WORN_CHANCE
	return maxf(chance, 0.0)


func burning() -> Array[SmartObject]:
	var result: Array[SmartObject] = []
	for smart_object in world.smart_objects:
		if smart_object.placed.is_burning():
			result.append(smart_object)
	return result


## Met le feu à un objet. `character` : le Mouz qui cuisinait (null si le feu s'est propagé) ;
## `cause` : le message à afficher à la place (la foudre…).
func start_fire(smart_object: SmartObject, character: Character = null, cause := "") -> void:
	if smart_object.placed.is_burning():
		return
	var first := burning().is_empty()
	smart_object.placed.fire = 0.01
	# Images des flammes chargées avant d'être dessinées (sinon blanches à la première image).
	for frame in 3:
		MouzLayers.texture(SmartObject.FIRE_FRAMES % (frame + 1))
	_stop_users(smart_object)
	smart_object.queue_redraw()
	Sfx.play(&"alerte")
	if cause != "":
		EventBus.notice.emit(cause)
	elif character != null:
		EventBus.notice.emit("%s a mis le feu à %s !" % [character.get_display_name(), Upkeep.the_lower(smart_object)])
	else:
		EventBus.notice.emit("Le feu gagne %s !" % Upkeep.the_lower(smart_object))
	if not first:
		return
	for mouz in world.characters:
		if not mouz.is_away():
			mouz.needs.change(&"plaisir", FIRE_FRIGHT)
	if firemen_at > 0.0:
		return
	if has_object(&"detecteur_fumee"):
		call_firemen(false)
		EventBus.notice.emit("Le détecteur de fumée a prévenu les pompiers : ils arrivent dans %d minutes." % int(FIREMEN_DELAY))
	elif neighbors_call_at <= 0.0:
		neighbors_call_at = GameClock.total_minutes + NEIGHBORS_CALL_MINUTES


## Appelle les pompiers (bouton du menu de l'objet, détecteur ou voisins).
func call_firemen(announce := true) -> void:
	if firemen_at > 0.0:
		return
	firemen_at = GameClock.total_minutes + FIREMEN_DELAY
	neighbors_call_at = 0.0
	if announce:
		EventBus.notice.emit("Les pompiers arrivent dans %d minutes." % int(FIREMEN_DELAY))


## Éteint un objet : ce qui a brûlé tombe en panne.
func extinguish(smart_object: SmartObject) -> void:
	if not smart_object.placed.is_burning():
		return
	smart_object.placed.fire = 0.0
	world.upkeep.break_object(smart_object, false)
	if burning().is_empty():
		neighbors_call_at = 0.0


func _firemen_arrive() -> void:
	firemen_at = 0.0
	var fires := burning()
	if fires.is_empty():
		EventBus.notice.emit("Les pompiers sont passés : le feu était déjà éteint, ils repartent.")
		return
	for smart_object in fires:
		extinguish(smart_object)
	world.bills.add_bill(FIREMEN_FEE, "Pompiers")
	Sfx.play(&"eau")
	EventBus.notice.emit("Les pompiers ont éteint le feu. Leur facture : %s." % Palette.format_mz(FIREMEN_FEE))


func _spread() -> void:
	for smart_object in burning():
		if _rng.randf() >= SPREAD_CHANCE:
			continue
		var candidates: Array[SmartObject] = []
		var zone := smart_object.footprint.grow(1)
		for other in world.smart_objects:
			if other.level == smart_object.level and not other.placed.is_burning() and _flammable(other) \
					and zone.intersects(other.footprint):
				candidates.append(other)
		if not candidates.is_empty():
			start_fire(candidates[_rng.randi_range(0, candidates.size() - 1)])


static func _flammable(smart_object: SmartObject) -> bool:
	var definition := smart_object.definition
	return definition.category != &"incident" and not definition.is_stairs and not definition.over_water \
			and definition.id != &"extincteur"


# --- Inondation ----------------------------------------------------------------------------

## Chance qu'un lavage sur cet appareil fasse une fuite.
static func flood_chance(smart_object: SmartObject) -> float:
	return clampf((smart_object.placed.wear - Upkeep.WORN) * FLOOD_RATE, 0.0, 0.5)


## L'appareil fuit : il tombe en panne et l'eau se répand sur les cases libres autour de lui.
func flood(smart_object: SmartObject) -> void:
	var cells: Array[Vector2i] = []
	for nav_cell in world.navigation.cells_around(smart_object.nav_footprint()):
		var cell := Levels.flat(nav_cell)
		if world.navigation.is_walkable(nav_cell) and _free_floor(cell, smart_object.level):
			cells.append(cell)
	cells.shuffle()
	var count := mini(_rng.randi_range(PUDDLES.x, PUDDLES.y), cells.size())
	var definition := Catalog.find(Catalog.OBJECTS, &"flaque") as SmartObjectDefinition
	for cell in cells.slice(0, count):
		var puddle := PlacedObject.new()
		puddle.definition = definition
		puddle.cell = cell
		puddle.collection = definition.default_collection()
		puddle.since = GameClock.total_minutes
		Wallet.stamp(puddle, 0)
		world.lot.level(smart_object.level).objects.append(puddle)
	Sfx.play(&"eau")
	EventBus.notice.emit("%s fuit : il y a de l'eau partout ! Épongez avant que le sol ne s'abîme." % Upkeep.the(smart_object))
	world.upkeep.break_object(smart_object, false)
	EventBus.lot_changed.emit()


## La flaque sur cette case de navigation, ou null.
func puddle_at(nav_cell: Vector2i) -> SmartObject:
	for smart_object in world.smart_objects:
		if smart_object.definition.category == &"incident" and smart_object.occupies(nav_cell):
			return smart_object
	return null


func puddles() -> Array[SmartObject]:
	var result: Array[SmartObject] = []
	for smart_object in world.smart_objects:
		if smart_object.definition.category == &"incident":
			result.append(smart_object)
	return result


func _free_floor(cell: Vector2i, level: int) -> bool:
	for placed in world.lot.level(level).objects:
		if placed.footprint().has_point(cell):
			return false
	return true


func _check_puddles() -> void:
	var damaged := 0
	for puddle in puddles():
		if GameClock.total_minutes - puddle.placed.since >= PUDDLE_DAMAGE_HOURS * 60.0:
			damaged += 1
			_remove(puddle.placed, false)
	if damaged > 0:
		EventBus.lot_changed.emit()
		var amount := damaged * PUDDLE_DAMAGE
		world.bills.add_bill(amount, "Dégâts des eaux")
		EventBus.notice.emit("L'eau a abîmé le sol : %s de réparations." % Palette.format_mz(amount))


# --- Cambriolage ---------------------------------------------------------------------------

## Vrai si la maison a au moins un objet de cette sorte (tous étages).
func has_object(id: StringName, level := -1) -> bool:
	for smart_object in world.smart_objects:
		if smart_object.definition.id == id and (level < 0 or smart_object.level == level):
			return true
	return false


## Chance qu'un cambrioleur vienne cette nuit.
func burglary_chance() -> float:
	return BURGLARY_CHANCE + BURGLARY_VALUE_CHANCE * clampf(world.bills.house_value() / BURGLARY_VALUE_REF, 0.0, 1.0)


## L'objet que le cambrioleur emporterait : le plus cher qu'il peut porter, ou null.
func loot() -> SmartObject:
	var best: SmartObject = null
	for smart_object in world.smart_objects:
		if not smart_object.definition.id in STEALABLE or smart_object.placed.is_burning():
			continue
		if best == null or smart_object.placed.price > best.placed.price:
			best = smart_object
	return best


## Un cambrioleur arrive par la rue (aussi appelé par les tests).
func start_burglary() -> bool:
	if _burglary != Burglary.NONE:
		return false
	var target := loot()
	if target == null:
		return false
	var profile := CharacterProfile.new()
	profile.id = &"cambrioleur"
	profile.display_name = "Cambrioleur"
	profile.autonomy_enabled = false
	profile.walk_speed = 110.0
	if not world.characters.is_empty():
		profile.needs = world.characters[0].profile.needs
	var look := MouzAppearance.new()
	look.randomize_look(_rng)
	look.age = &"adulte"
	look.outfit = &"pull"
	look.outfit_color = BURGLAR_OUTFIT
	look.pants_color = BURGLAR_PANTS
	look.accessory = &"cambrioleur"
	profile.appearance = look
	_burglar = world.character_scene.instantiate()
	world.characters_root.add_child(_burglar)
	_burglar.setup(world, profile, world.street_cell())
	_burglar_target = target
	_burglary_started = GameClock.total_minutes
	last_burglary_day = GameClock.get_day()
	var destination := world.navigation.closest_reachable(target.get_spots(world.navigation), _burglar.get_cell())
	if destination == GridNavigation.NO_CELL:
		_end_burglary()
		return false
	_burglary = Burglary.COMING
	_burglar_move = QueuedAction.move_to(destination)
	_burglar.queue.enqueue(_burglar_move)
	return true


func is_burglar_here() -> bool:
	return _burglary != Burglary.NONE


func _burglar_arrived() -> void:
	if has_object(&"alarme"):
		Sfx.play(&"alerte")
		Wallet.receive(POLICE_REWARD)
		EventBus.notice.emit("L'alarme sonne : le cambrioleur s'enfuit les mains vides ! La police l'arrête et vous verse %s." \
				% Palette.format_mz(POLICE_REWARD))
		_leave()
		return
	_burglary = Burglary.STEALING
	_steal_until = GameClock.total_minutes + STEAL_MINUTES


func _steal() -> void:
	var target := _burglar_target
	if is_instance_valid(target) and target in world.smart_objects:
		var value := target.placed.price
		var name := Upkeep.the_lower(target)
		_remove(target.placed)
		Sfx.play(&"alerte")
		EventBus.notice.emit("Un cambrioleur a volé %s (%s) !" % [name, Palette.format_mz(value)])
	_leave()


func _leave() -> void:
	_burglary = Burglary.LEAVING
	_burglar_move = QueuedAction.move_to(world.street_cell())
	_burglar.queue.enqueue(_burglar_move)


func _end_burglary() -> void:
	_burglary = Burglary.NONE
	_burglar_move = null
	_burglar_target = null
	if is_instance_valid(_burglar):
		for action in _burglar.queue.items.duplicate():
			_burglar.queue.cancel(action)
		_burglar.queue_free()
	_burglar = null


# --- Horloge et actions --------------------------------------------------------------------

func _on_ticked(game_minutes: float) -> void:
	for action in _fire_plans.keys():
		if action.state == QueuedAction.State.RUNNING and action.elapsed_minutes >= _fire_plans[action]:
			var cook: Character = _cook_of(action)
			_fire_plans.erase(action)
			if action.target_object != null and is_instance_valid(action.target_object):
				start_fire(action.target_object, cook)
	var fires := burning()
	if fires.is_empty():
		_spread_time = 0.0
		return
	for smart_object in fires:
		smart_object.placed.fire += game_minutes
	_spread_time += game_minutes
	if _spread_time >= SPREAD_MINUTES:
		_spread_time = 0.0
		_spread()


func _on_minute_changed(day: int, hour: int, _minute: int) -> void:
	var now := GameClock.total_minutes
	if neighbors_call_at > 0.0 and now >= neighbors_call_at:
		neighbors_call_at = 0.0
		if not burning().is_empty():
			call_firemen(false)
			EventBus.notice.emit("Les voisins ont vu la fumée et appelé les pompiers.")
	if firemen_at > 0.0 and now >= firemen_at:
		_firemen_arrive()
	_check_puddles()
	match _burglary:
		Burglary.STEALING:
			if now >= _steal_until:
				_steal()
	if _burglary != Burglary.NONE and now - _burglary_started > BURGLAR_MAX_MINUTES:
		_end_burglary()
	if _burglary == Burglary.NONE and hour >= BURGLARY_HOURS.x and hour < BURGLARY_HOURS.y and checked_night != day:
		checked_night = day
		if day - last_burglary_day >= BURGLARY_REST_DAYS and _rng.randf() < burglary_chance():
			start_burglary()


func _on_action_started(character: Node, action: RefCounted) -> void:
	var queued := action as QueuedAction
	if queued.target_object == null or not queued.target_object.definition.id in FIRE_OBJECTS:
		return
	var chance := fire_chance(character.skills.level(&"cuisine"), queued.target_object)
	if _rng.randf() < chance:
		var duration := queued.definition.duration_minutes
		_fire_plans[queued] = _rng.randf_range(duration * 0.2, duration * 0.8)


func _on_action_finished(character: Node, action: RefCounted) -> void:
	var queued := action as QueuedAction
	_fire_plans.erase(queued)
	if character == _burglar and queued == _burglar_move:
		match _burglary:
			Burglary.COMING:
				_burglar_arrived()
			Burglary.LEAVING:
				_end_burglary()
		return
	var target := queued.target_object
	if target == null or not is_instance_valid(target):
		return
	if queued.definition == EXTINGUISH:
		if not target.placed.is_burning():
			return
		if has_object(&"extincteur", target.level) or _rng.randf() < EXTINGUISH_CHANCE:
			extinguish(target)
			EventBus.notice.emit("%s a éteint le feu." % character.get_display_name())
		else:
			EventBus.notice.emit("%s n'arrive pas à éteindre le feu : il faut recommencer (un extincteur aiderait)." \
					% character.get_display_name())
	elif queued.definition == MOP:
		_remove(target.placed)
	elif target.definition.id in FLOOD_OBJECTS and not target.placed.is_broken() \
			and _rng.randf() < flood_chance(target):
		flood(target)


func _on_action_cancelled(character: Node, action: RefCounted) -> void:
	_fire_plans.erase(action)
	# Le cambrioleur n'a pas pu passer : il s'en va.
	if character == _burglar and action == _burglar_move and _burglary == Burglary.COMING:
		_leave()


func _cook_of(action: QueuedAction) -> Character:
	for character in world.people:
		if action in character.queue.items:
			return character
	return null


# --- Outils --------------------------------------------------------------------------------

## Ceux qui se servaient de l'objet s'arrêtent (sauf pour l'éteindre).
func _stop_users(smart_object: SmartObject) -> void:
	for character in world.people:
		for action in character.queue.items.duplicate():
			if action.target_object == smart_object and action.definition != EXTINGUISH:
				character.queue.cancel(action)


## Retire un objet du terrain (volé, flaque épongée).
func _remove(placed: PlacedObject, refresh := true) -> void:
	for level in world.lot.levels:
		if placed in level.objects:
			EventBus.object_displaced.emit(placed)
			level.objects.erase(placed)
	if refresh:
		EventBus.lot_changed.emit()


func to_dict() -> Dictionary:
	return {"firemen_at": firemen_at, "neighbors_call_at": neighbors_call_at,
			"last_burglary_day": last_burglary_day, "checked_night": checked_night}


func restore(data: Dictionary) -> void:
	firemen_at = float(data.get("firemen_at", 0.0))
	neighbors_call_at = float(data.get("neighbors_call_at", 0.0))
	last_burglary_day = int(data.get("last_burglary_day", last_burglary_day))
	checked_night = int(data.get("checked_night", 0))
	# Un feu sans personne pour l'avoir signalé : les voisins s'en chargent.
	if not burning().is_empty() and firemen_at <= 0.0 and neighbors_call_at <= 0.0:
		neighbors_call_at = GameClock.total_minutes + NEIGHBORS_CALL_MINUTES
