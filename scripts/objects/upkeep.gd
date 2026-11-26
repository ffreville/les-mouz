class_name Upkeep
extends Node
## L'usure des objets (enfant du monde).
##  - Un objet qui a un `wear_per_hour` s'use pendant qu'on s'en sert. À 100, il tombe en panne :
##    ses actions ne sont plus possibles, sauf « Réparer », et un signe le montre.
##  - Réparer soi-même : 1 h, compétence Bricolage ; réussi à REPAIR_BASE_CHANCE + REPAIR_LEVEL_CHANCE
##    par niveau (sinon il faut recommencer). Ça fait progresser le Bricolage.
##  - Appeler un réparateur : REPAIRMAN_BASE + REPAIRMAN_RATE du prix de l'objet, il passe dans
##    REPAIRMAN_DELAY minutes et remet l'objet à neuf.

const REPAIR_ACTION := preload("res://data/actions/reparer.tres")
const REPAIR_BASE_CHANCE := 0.45
const REPAIR_LEVEL_CHANCE := 0.055
const REPAIRMAN_BASE := 50
const REPAIRMAN_RATE := 0.15
const REPAIRMAN_DELAY := 60.0
## Au-delà, l'objet est dit « usé » (menu de l'objet).
const WORN := 50.0

var world: World
var _rng := RandomNumberGenerator.new()


func setup(p_world: World) -> void:
	world = p_world
	_rng.randomize()
	GameClock.minute_changed.connect(_on_minute_changed)
	EventBus.action_finished.connect(_on_action_finished)


## Usure pendant `minutes` d'utilisation (appelé par la file d'actions).
func wear(smart_object: SmartObject, minutes: float) -> void:
	var rate := smart_object.definition.wear_per_hour
	if rate <= 0.0 or smart_object.placed.is_broken():
		return
	smart_object.placed.wear += rate * minutes / 60.0 * _rng.randf_range(0.5, 1.5)
	if smart_object.placed.is_broken():
		smart_object.placed.wear = 100.0
		_break(smart_object)


## Met l'objet en panne tout de suite (brûlé, fuite) ; `announce` : message « en panne ».
func break_object(smart_object: SmartObject, announce := true) -> void:
	if smart_object.placed.is_broken():
		smart_object.queue_redraw()
		return
	smart_object.placed.wear = 100.0
	_break(smart_object, announce)


func _break(smart_object: SmartObject, announce := true) -> void:
	# Ceux qui s'en servaient s'arrêtent (la file s'en charge à la prochaine vérification).
	for character in world.people:
		for action in character.queue.items.duplicate():
			if action.target_object == smart_object and action.definition != REPAIR_ACTION:
				character.queue.cancel(action)
	smart_object.queue_redraw()
	EventBus.object_broke.emit(smart_object)
	if not announce:
		return
	Sfx.play(&"alerte")
	var verb := "sont" if ARTICLES.get(smart_object.definition.id, "") == "Les " else "est"
	EventBus.notice.emit("%s %s en panne !" % [the(smart_object), verb])


## Prix du réparateur pour cet objet.
func repairman_fee(smart_object: SmartObject) -> int:
	return int(round((REPAIRMAN_BASE + smart_object.placed.price * REPAIRMAN_RATE) / 5.0)) * 5


## Appelle le réparateur (payé tout de suite). Renvoie false si l'argent manque.
func call_repairman(smart_object: SmartObject) -> bool:
	if not smart_object.placed.is_broken() or smart_object.placed.repair_at > 0.0:
		return false
	if not Wallet.pay(repairman_fee(smart_object)):
		EventBus.notice.emit("Pas assez d'argent pour le réparateur.")
		return false
	smart_object.placed.repair_at = GameClock.total_minutes + REPAIRMAN_DELAY
	EventBus.notice.emit("Le réparateur passe dans une heure pour %s." % the_lower(smart_object))
	return true


## Chance de réussir une réparation à ce niveau de Bricolage.
static func repair_chance(level: int) -> float:
	return minf(REPAIR_BASE_CHANCE + REPAIR_LEVEL_CHANCE * level, 1.0)


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	for smart_object in world.smart_objects:
		var placed := smart_object.placed
		if placed.repair_at > 0.0 and GameClock.total_minutes >= placed.repair_at:
			placed.repair_at = 0.0
			_fix(smart_object)
			EventBus.notice.emit("Le réparateur a remis %s en état." % the_lower(smart_object))


func _on_action_finished(character: Node, action: RefCounted) -> void:
	if action.definition != REPAIR_ACTION or action.target_object == null:
		return
	var smart_object: SmartObject = action.target_object
	if not smart_object.placed.is_broken():
		return
	if _rng.randf() < repair_chance(character.skills.level(&"bricolage")):
		_fix(smart_object)
		EventBus.notice.emit("%s a réparé %s." % [character.get_display_name(), the_lower(smart_object)])
	else:
		EventBus.notice.emit("%s n'arrive pas à réparer %s : il faudra réessayer." % [
				character.get_display_name(), the_lower(smart_object)])


func _fix(smart_object: SmartObject) -> void:
	smart_object.placed.wear = 0.0
	smart_object.queue_redraw()
	Sfx.play(&"poser")
	EventBus.object_repaired.emit(smart_object)


## Article de chaque objet (« Le frigo », « Les toilettes »).
const ARTICLES := {&"alarme": "L'", &"aquarium": "L'", &"arbre": "L'", &"armoire": "L'", &"baignoire": "La ",
		&"balancoire": "La ", &"barbecue": "Le ", &"bibliotheque": "La ", &"bureau": "Le ", &"canape": "Le ",
		&"chaine_hifi": "La ", &"chaise": "La ", &"cheminee": "La ", &"chevalet": "Le ", &"coiffeuse": "La ",
		&"commode": "La ", &"console_jeux": "La ", &"cuisiniere": "La ", &"detecteur_fumee": "Le ",
		&"douche": "La ", &"echelle_piscine": "L'", &"escalier": "L'", &"evier": "L'", &"extincteur": "L'",
		&"fauteuil": "Le ", &"flaque": "La ", &"frigo": "Le ", &"hamac": "Le ", &"horloge": "L'",
		&"lampe_chevet": "La ", &"lampe_pied": "La ", &"lavabo": "Le ", &"lave_vaisselle": "Le ", &"lit": "Le ",
		&"lit_simple": "Le ", &"machine_cafe": "La ", &"machine_laver": "La ", &"massif_fleurs": "Le ",
		&"micro_ondes": "Le ", &"miroir_mural": "Le ", &"ordinateur": "L'", &"panier_linge": "Le ",
		&"piano": "Le ", &"plan_travail": "Le ", &"plante": "La ", &"plongeoir": "Le ", &"potager": "Le ",
		&"poubelle": "La ", &"salon_jardin": "Le ", &"table": "La ", &"table_basse": "La ", &"table_jeux": "La ",
		&"table_nuit": "La ", &"tapis": "Le ", &"tapis_yoga": "Le ", &"tele": "Le ", &"telescope": "Le ",
		&"toilettes": "Les ", &"transat": "Le "}


## « Le frigo », « Les toilettes », « L'ordinateur ».
static func the(smart_object: SmartObject) -> String:
	var name := smart_object.get_display_name()
	if ARTICLES.has(smart_object.definition.id):
		name = name[0].to_lower() + name.substr(1)
	return ARTICLES.get(smart_object.definition.id, "") + name


## Même chose en milieu de phrase (« le frigo »).
static func the_lower(smart_object: SmartObject) -> String:
	var text := the(smart_object)
	return text[0].to_lower() + text.substr(1)
