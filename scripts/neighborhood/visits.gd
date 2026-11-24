class_name Visits
extends Node
## Les visites des voisins (enfant du monde).
##  - On invite un voisin depuis son téléphone (clic sur son Mouz) : il arrive par la rue
##    au bout de ARRIVAL_MINUTES.
##  - Des voisins passent parfois d'eux-mêmes (DROP_IN_CHANCE par heure, en journée), et viennent
##    souhaiter la bienvenue à une famille qui vient d'emménager.
##  - Un visiteur vit sa vie chez vous (autonomie, sans dormir, se laver, cuisiner ni travailler),
##    discute avec la famille, puis rentre chez lui au bout de quelques heures, à VISIT_END_HOUR
##    au plus tard, ou quand on le raccompagne.
## Les relations avec les voisins sont gardées dans le quartier : { "a/m|b/m": valeur }, où
## « a/m » désigne le membre m de la famille de l'emplacement a.
## Les visiteurs ne sont pas sauvegardés : une partie rechargée repart sans eux.

const ARRIVAL_MINUTES := 30.0
const WELCOME_MINUTES := 60.0
const MIN_STAY_MINUTES := 150.0
const MAX_STAY_MINUTES := 300.0
const VISIT_START_HOUR := 8
const VISIT_END_HOUR := 22
## On n'invite plus après cette heure (il faut le temps de venir).
const LAST_INVITE_HOUR := 21
const MAX_VISITORS := 3
## Chance, chaque heure entre DROP_IN_HOURS, qu'un voisin passe sans prévenir (s'il n'y a personne).
const DROP_IN_CHANCE := 0.08
const DROP_IN_HOURS := Vector2i(10, 19)
## Au-delà, on considère qu'il est parti (minutes de jeu).
const MAX_WALK_MINUTES := 20.0
## Les visiteurs ne font pas ça chez les autres (besoins que ces actions remplissent).
const PRIVATE_NEEDS: Array[StringName] = [&"energie", &"hygiene"]

var world: World
## Arrivées prévues : { "ref": "emplacement/membre", "at": minutes de jeu }.
var _pending: Array[Dictionary] = []
## Par visiteur : { "ref", "leave_at", "leaving" (QueuedAction ou null), "leave_started" }.
var _stays: Dictionary[Character, Dictionary] = {}
var _rng := RandomNumberGenerator.new()
## Relations du quartier quand on joue sans sauvegarde (tests).
var _local_relations: Dictionary = {}


func setup(p_world: World, just_moved_in: bool) -> void:
	world = p_world
	_rng.randomize()
	GameClock.minute_changed.connect(_on_minute_changed)
	EventBus.action_finished.connect(_on_action_ended)
	EventBus.action_cancelled.connect(_on_action_ended)
	if just_moved_in:
		_welcome()


# --- Les voisins ------------------------------------------------------------------------

## Les membres des autres familles du quartier :
## [{ "ref", "plot", "member" (id), "first_name", "family" (nom affiché), "appearance", "entry" (personnage sauvegardé ou {}) }].
func neighbors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for plot in _neighborhood().get("plots", []):
		if plot["id"] == SaveManager.active_plot or not Neighborhood.has_household(plot):
			continue
		var family := Family.from_dict(plot["household"]["family"])
		var saved := {}
		for entry in plot["household"].get("characters", []):
			saved[entry.get("profile", "")] = entry
		for member in family.members:
			result.append({
				"ref": "%s/%s" % [plot["id"], member["id"]], "plot": plot["id"], "member": member["id"],
				"first_name": member["first_name"], "family": family.display_name(),
				"appearance": member["appearance"], "entry": saved.get(member["id"], {}),
			})
	return result


## Pourquoi on ne peut pas inviter ce voisin maintenant ("" si on peut).
func invite_problem(neighbor: Dictionary) -> String:
	if is_here_or_coming(neighbor["ref"]):
		return "déjà là" if _visitor(neighbor["ref"]) != null else "en route"
	var hour := GameClock.get_hour()
	if hour < VISIT_START_HOUR:
		return "trop tôt"
	if hour >= LAST_INVITE_HOUR:
		return "trop tard"
	if _stays.size() + _pending.size() >= MAX_VISITORS:
		return "maison pleine"
	return ""


func is_here_or_coming(ref: String) -> bool:
	return _visitor(ref) != null or _pending.any(func(p: Dictionary) -> bool: return p["ref"] == ref)


## Invite un voisin : il arrive dans ARRIVAL_MINUTES.
func invite(neighbor: Dictionary) -> void:
	if invite_problem(neighbor) != "":
		return
	_pending.append({"ref": neighbor["ref"], "at": GameClock.total_minutes + ARRIVAL_MINUTES})
	EventBus.notice.emit("%s %s arrive dans une demi-heure." % [neighbor["first_name"], _family_part(neighbor)])


## Relation entre un Mouz de la famille jouée (ou un visiteur) et le voisin `ref`.
func relation_with(character: Character, ref: String) -> float:
	return float(_relations().get(_key(ref_of(character), ref), 0.0))


## « emplacement/membre » d'un Mouz présent (famille jouée ou visiteur).
func ref_of(character: Character) -> String:
	if character.is_visitor():
		return String(character.profile.id)
	return "%s/%s" % [SaveManager.active_plot, character.profile.id]


# --- Arrivées et départs -----------------------------------------------------------------

func _on_minute_changed(_day: int, hour: int, minute: int) -> void:
	var now := GameClock.total_minutes
	for arrival in _pending.duplicate():
		if now >= arrival["at"]:
			_pending.erase(arrival)
			_arrive(arrival["ref"])
	for visitor in _stays.keys():
		var stay: Dictionary = _stays[visitor]
		if stay["leaving"] == null:
			if now >= stay["leave_at"] or hour >= VISIT_END_HOUR or hour < VISIT_START_HOUR:
				send_home(visitor)
		elif now - stay["leave_started"] > MAX_WALK_MINUTES:
			_remove(visitor)
	if minute == 0 and hour >= DROP_IN_HOURS.x and hour <= DROP_IN_HOURS.y and _stays.is_empty() \
			and _pending.is_empty() and _rng.randf() < DROP_IN_CHANCE:
		_drop_in()


## Un voisin (pas un enfant) passe sans prévenir.
func _drop_in() -> void:
	var candidates := neighbors().filter(func(n: Dictionary) -> bool: return n["appearance"].age != &"enfant")
	if candidates.is_empty():
		return
	var neighbor: Dictionary = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_arrive(neighbor["ref"])


## À l'emménagement, un ou deux voisins viennent dire bonjour.
func _welcome() -> void:
	var hour := GameClock.get_hour()
	if hour < VISIT_START_HOUR or hour >= LAST_INVITE_HOUR - 1:
		return
	var candidates := neighbors().filter(func(n: Dictionary) -> bool: return n["appearance"].age in [&"adulte", &"aine"])
	candidates.shuffle()
	for neighbor in candidates.slice(0, mini(2, candidates.size())):
		_pending.append({"ref": neighbor["ref"], "at": GameClock.total_minutes + WELCOME_MINUTES})
	if not candidates.is_empty():
		EventBus.notice.emit("Des voisins vont passer souhaiter la bienvenue.")


func _arrive(ref: String) -> void:
	if _visitor(ref) != null:
		return
	var neighbor: Dictionary = {}
	for candidate in neighbors():
		if candidate["ref"] == ref:
			neighbor = candidate
	if neighbor.is_empty():
		return
	var plot := Neighborhood.plot(_neighborhood(), neighbor["plot"])
	var family := Family.from_dict(plot["household"]["family"])
	var profile: CharacterProfile = null
	for candidate in family.make_profiles():
		if String(candidate.id) == neighbor["member"]:
			profile = candidate
	if profile == null:
		return
	profile.id = StringName(ref)
	var visitor: Character = world.character_scene.instantiate()
	visitor.home_plot = neighbor["plot"]
	visitor.family_name = family.family_name
	world.characters_root.add_child(visitor)
	visitor.setup(world, profile, world.street_cell())
	if not neighbor["entry"].is_empty():
		visitor.needs.restore(neighbor["entry"].get("needs", {}))
	world.visitors.append(visitor)
	world.people.append(visitor)
	# Relations gardées dans le quartier (ou dans sa famille), avec chaque Mouz présent.
	for other in world.people:
		if other != visitor:
			visitor.relationships.restore_with(other, _stored_relation(ref, ref_of(other)))
	var stay_minutes := _rng.randf_range(MIN_STAY_MINUTES, MAX_STAY_MINUTES)
	_stays[visitor] = {"ref": ref, "leave_at": GameClock.total_minutes + stay_minutes, "leaving": null, "leave_started": 0.0}
	visitor.brain.enabled = true
	visitor.queue.enqueue(QueuedAction.move_to(world.navigation.nearest_walkable(world.lot.spawn_cells[0])))
	Sfx.play(&"porte")
	EventBus.notice.emit("%s %s vient vous rendre visite." % [neighbor["first_name"], _family_part(neighbor)])
	EventBus.visitor_arrived.emit(visitor)


## Le visiteur rentre chez lui : il laisse tout et repart par la rue.
func send_home(visitor: Character) -> void:
	var stay: Dictionary = _stays.get(visitor, {})
	if stay.is_empty() or stay["leaving"] != null:
		return
	_cancel_with(visitor)
	visitor.brain.enabled = false
	var leaving := QueuedAction.move_to(world.street_cell())
	stay["leaving"] = leaving
	stay["leave_started"] = GameClock.total_minutes
	visitor.queue.enqueue(leaving)
	EventBus.notice.emit("%s rentre chez %s." % [visitor.get_display_name(), "elle" if visitor.profile.appearance.sex == &"femme" else "lui"])


func _on_action_ended(character: Node, action: RefCounted) -> void:
	var visitor := character as Character
	if visitor != null and _stays.has(visitor) and _stays[visitor]["leaving"] == action:
		_remove(visitor)


func _remove(visitor: Character) -> void:
	store_relations()
	_cancel_with(visitor)
	for other in world.people:
		if other != visitor:
			other.relationships.forget(visitor)
	_stays.erase(visitor)
	world.visitors.erase(visitor)
	world.people.erase(visitor)
	EventBus.visitor_left.emit(visitor)
	visitor.queue_free()


## Arrête ce que le visiteur fait, et ce que les autres faisaient avec lui.
func _cancel_with(visitor: Character) -> void:
	for action in visitor.queue.items.duplicate():
		visitor.queue.cancel(action)
	for other in world.people:
		if other == visitor:
			continue
		for action in other.queue.items.duplicate():
			if action.target_character == visitor:
				other.queue.cancel(action)


# --- Relations du quartier ----------------------------------------------------------------

## Range dans le quartier les relations entre visiteurs et Mouz présents (avant d'enregistrer).
func store_relations() -> void:
	var relations := _relations()
	for visitor in world.visitors:
		for other in world.people:
			if other != visitor:
				if not _same_family(ref_of(visitor), ref_of(other)):
					relations[_key(ref_of(visitor), ref_of(other))] = snappedf(visitor.relationships.get_value(other), 0.01)


## Relation enregistrée entre deux Mouz du quartier. Deux membres d'une même famille (venus
## ensemble) gardent celle de leur famille : sa sauvegarde, ou le lien choisi à la création.
func _stored_relation(a: String, b: String) -> float:
	if not _same_family(a, b):
		return float(_relations().get(_key(a, b), 0.0))
	var plot := Neighborhood.plot(_neighborhood(), a.get_slice("/", 0))
	var household: Dictionary = plot.get("household", {})
	for entry in household.get("characters", []):
		if entry.get("profile", "") == a.get_slice("/", 1):
			return float(entry.get("relationships", {}).get(b.get_slice("/", 1), 0.0))
	var family := Family.from_dict(household.get("family", {}))
	return Family.LINK_START.get(family.link_between(a.get_slice("/", 1), b.get_slice("/", 1)), 0.0)


static func _same_family(a: String, b: String) -> bool:
	return a.get_slice("/", 0) == b.get_slice("/", 0)


func _relations() -> Dictionary:
	var hood := _neighborhood()
	if hood.is_empty():
		return _local_relations
	if not hood.has("relationships"):
		hood["relationships"] = {}
	return hood["relationships"]


func _neighborhood() -> Dictionary:
	return SaveManager.neighborhood if world.use_save else {}


func _visitor(ref: String) -> Character:
	for visitor in _stays:
		if _stays[visitor]["ref"] == ref:
			return visitor
	return null


static func _key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]


static func _family_part(neighbor: Dictionary) -> String:
	return "(%s)" % neighbor["family"]
