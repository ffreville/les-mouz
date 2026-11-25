class_name GridMover
extends Node
## Déplace son personnage case par case le long d'un chemin calculé par GridNavigation.
## La vitesse suit celle de l'horloge de jeu (arrêt complet en pause).
## Un escalier se prend marche par marche, en suivant la ligne des marches de son dessin
## (StairsArt) : le personnage reste du niveau du bas jusqu'à la dernière marche.

## Le personnage est arrivé à destination.
signal arrived

## Dernière direction de marche (le personnage garde son orientation à l'arrêt).
var facing: Vector2 = Vector2.UP

var _navigation: GridNavigation
var _body: Node2D
var _speed: float = 96.0
## Étapes : { "pos": position des pieds, "level": niveau une fois l'étape atteinte,
## "stairs": escalier (SmartObject) si l'étape est une marche, "step": n° de marche, "up": on monte }.
var _path: Array[Dictionary] = []
## Position des pieds (celle du personnage, sauf dans un escalier où son corps est décalé).
var _feet := Vector2.ZERO


func setup(navigation: GridNavigation, body: Node2D, speed: float) -> void:
	_navigation = navigation
	_body = body
	_speed = speed


## Lance le déplacement vers une case. Renvoie false si elle est inaccessible.
func move_to_cell(target: Vector2i) -> bool:
	var start: Vector2i = _body.get_cell() if _body.has_method("get_cell") else _navigation.world_to_cell(_body.position)
	var cells := _navigation.find_path(start, target)
	if cells.is_empty():
		return false
	if not is_on_stairs():
		_feet = _body.position
	_path.clear()
	for i in cells.size():
		if i > 0:
			_add_stairs(cells[i - 1], cells[i])
		_path.append({"pos": _navigation.cell_to_world(cells[i]), "level": Levels.level_of(cells[i])})
	return true


## Étapes d'un escalier entre deux paliers (rien si `a` → `b` n'est pas un escalier).
func _add_stairs(a: Vector2i, b: Vector2i) -> void:
	var link := _navigation.stairs_between(a, b)
	if link.is_empty() or not "world" in _body:
		return
	var stairs: SmartObject = _body.world.smart_object_for(link["placed"])
	var line := StairsArt.step_line(stairs) if stairs != null else {}
	if line.is_empty():
		return
	var lower := mini(Levels.level_of(a), Levels.level_of(b))
	var steps: Array = line["marches"]
	if link["up"]:
		_path.append({"pos": line["depart"], "level": lower, "stairs": stairs, "step": 0, "up": true})
		for k in steps.size():
			_path.append({"pos": steps[k], "level": lower, "stairs": stairs, "step": k + 1, "up": true})
	else:
		for k in range(steps.size() - 1, -1, -1):
			_path.append({"pos": steps[k], "level": lower, "stairs": stairs, "step": k + 1, "up": false})
		_path.append({"pos": line["depart"], "level": lower, "stairs": stairs, "step": 0, "up": false})


## Arrête le déplacement ; dans un escalier, il finit de le prendre.
func stop() -> void:
	if not is_on_stairs():
		_path.clear()
		return
	var keep := 0
	while keep < _path.size() and _path[keep].has("stairs"):
		keep += 1
	_path = _path.slice(0, keep + 1)


func is_moving() -> bool:
	return not _path.is_empty()


## Vrai pendant la montée ou la descente d'un escalier.
func is_on_stairs() -> bool:
	return not _path.is_empty() and _path[0].has("stairs")


## Dans un escalier : { "stairs", "step", "up" } (la marche visée), sinon {}.
func stairs_state() -> Dictionary:
	return _path[0] if is_on_stairs() else {}


func _process(delta: float) -> void:
	if _path.is_empty():
		return
	var step := _speed * delta * GameClock.time_scale
	while step > 0.0 and not _path.is_empty():
		var target: Vector2 = _path[0]["pos"]
		var distance := _feet.distance_to(target)
		if distance <= step:
			_feet = target
			step -= distance
			if _body.has_method("set_level"):
				_body.set_level(_path[0]["level"])
			_path.pop_front()
		else:
			facing = (target - _feet).normalized()
			_feet = _feet.move_toward(target, step)
			step = 0.0
		_place()
		if _path.is_empty():
			arrived.emit()


## Pose le personnage : dans un escalier, son corps suit les marches tandis que son point de tri
## reste au pied de l'escalier (il passe devant lui) ; ailleurs, il est à ses pieds.
func _place() -> void:
	var state := stairs_state()
	if not state.is_empty() and _body.has_method("place_on_stairs"):
		_body.place_on_stairs(state["stairs"], _feet, int(state["step"]))
	else:
		if _body.has_method("leave_stairs"):
			_body.leave_stairs()
		_body.position = _feet
