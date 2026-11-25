class_name GridMover
extends Node
## Déplace son personnage case par case le long d'un chemin calculé par GridNavigation.
## La vitesse suit celle de l'horloge de jeu (arrêt complet en pause).
## Un escalier se prend marche par marche ; le personnage change de niveau à mi-hauteur.

## Le personnage est arrivé à destination.
signal arrived

## Dernière direction de marche (le personnage garde son orientation à l'arrêt).
var facing: Vector2 = Vector2.UP

var _navigation: GridNavigation
var _body: Node2D
var _speed: float = 96.0
## Étapes : { "pos": position du monde, "level": niveau une fois l'étape atteinte }.
var _path: Array[Dictionary] = []


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
	_path.clear()
	for i in cells.size():
		if i > 0:
			var steps := _navigation.stairs_between(cells[i - 1], cells[i])
			for k in steps.size():
				var level := Levels.level_of(cells[i - 1]) if k < steps.size() / 2 else Levels.level_of(cells[i])
				_path.append({"pos": _navigation.cell_to_world(steps[k]), "level": level})
		_path.append({"pos": _navigation.cell_to_world(cells[i]), "level": Levels.level_of(cells[i])})
	return true


func stop() -> void:
	_path.clear()


func is_moving() -> bool:
	return not _path.is_empty()


func _process(delta: float) -> void:
	if _path.is_empty():
		return
	var step := _speed * delta * GameClock.time_scale
	while step > 0.0 and not _path.is_empty():
		var target: Vector2 = _path[0]["pos"]
		var distance := _body.position.distance_to(target)
		if distance <= step:
			_body.position = target
			step -= distance
			if _body.has_method("set_level"):
				_body.set_level(_path[0]["level"])
			_path.pop_front()
			if _path.is_empty():
				arrived.emit()
		else:
			facing = (target - _body.position).normalized()
			_body.position = _body.position.move_toward(target, step)
			step = 0.0
