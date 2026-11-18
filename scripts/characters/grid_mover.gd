class_name GridMover
extends Node
## Déplace son personnage case par case le long d'un chemin calculé par GridNavigation.
## La vitesse suit celle de l'horloge de jeu (arrêt complet en pause).

## Le personnage est arrivé à destination.
signal arrived

var _navigation: GridNavigation
var _body: Node2D
var _speed: float = 96.0
var _path: Array[Vector2] = []


func setup(navigation: GridNavigation, body: Node2D, speed: float) -> void:
	_navigation = navigation
	_body = body
	_speed = speed


## Lance le déplacement vers une case. Renvoie false si elle est inaccessible.
func move_to_cell(target: Vector2i) -> bool:
	var start := _navigation.world_to_cell(_body.position)
	var cells := _navigation.find_path(start, target)
	if cells.is_empty():
		return false
	_path.clear()
	for cell in cells:
		_path.append(_navigation.cell_to_world(cell))
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
		var target := _path[0]
		var distance := _body.position.distance_to(target)
		if distance <= step:
			_body.position = target
			step -= distance
			_path.pop_front()
			if _path.is_empty():
				arrived.emit()
		else:
			_body.position = _body.position.move_toward(target, step)
			step = 0.0
