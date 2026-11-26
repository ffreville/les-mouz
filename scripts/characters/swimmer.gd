class_name Swimmer
extends Node
## La nage d'un Mouz (échelle ou plongeoir de la piscine) : pendant l'action, il fait des longueurs
## d'une case d'eau à l'autre, le bas du corps sous l'eau ; à la fin, il ressort là où il était.

const SPEED := 40.0

var active := false
var facing := Vector2.DOWN
var _character: Character
var _cells: Array[Vector2i] = []
var _target := Vector2.ZERO
var _home := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func setup(character: Character) -> void:
	_character = character
	_rng.randomize()


## Entre dans l'eau près de `near` (l'échelle ou le plongeoir). Rien s'il n'y a pas de piscine à côté.
func start(near: SmartObject) -> void:
	_cells = near.pool_cells()
	if _cells.is_empty():
		return
	active = true
	_home = _character.position
	var navigation := _character.world.navigation
	var entry := _cells[0]
	var best := INF
	for cell in _cells:
		var distance := navigation.cell_to_world(cell).distance_to(_home)
		if distance < best:
			best = distance
			entry = cell
	_character.position = navigation.cell_to_world(entry)
	_character.body.in_water = true
	_next()


func stop() -> void:
	if not active:
		return
	active = false
	_character.position = _home
	_character.body.in_water = false


func _next() -> void:
	_target = _character.world.navigation.cell_to_world(_cells[_rng.randi_range(0, _cells.size() - 1)])


func _process(delta: float) -> void:
	if not active:
		return
	var step := SPEED * delta * GameClock.time_scale
	var to := _target - _character.position
	if to.length() <= step:
		_character.position = _target
		_next()
	else:
		facing = to.normalized()
		_character.position += facing * step
