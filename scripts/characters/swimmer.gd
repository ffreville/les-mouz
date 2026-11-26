class_name Swimmer
extends Node
## La nage d'un Mouz (échelle ou plongeoir de la piscine) : pendant l'action, il fait des longueurs
## d'une case d'eau à l'autre, la tête et les épaules hors de l'eau ; à la fin, il ressort là où il était.
## Depuis le plongeoir, il saute d'abord du bout de la planche en suivant un arc jusqu'à l'eau,
## puis l'éclaboussure (la gerbe, puis les ronds) le laisse remonter à la surface.

const SPEED := 40.0
## Durée du saut et de l'éclaboussure, en secondes (à vitesse x1).
const DIVE_TIME := 0.8
const SPLASH_TIME := 0.6
## Hauteur de la planche au bout, et de l'arc du saut au-dessus.
const BOARD_HEIGHT := 15.0
const ARC_HEIGHT := 22.0

enum Phase { NONE, DIVE, SPLASH, SWIM }

var active := false
var facing := Vector2.DOWN
var _phase := Phase.NONE
var _time := 0.0
var _character: Character
var _cells: Array[Vector2i] = []
var _target := Vector2.ZERO
var _home := Vector2.ZERO
var _dive_from := Vector2.ZERO
var _dive_to := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func setup(character: Character) -> void:
	_character = character
	_rng.randomize()


func is_diving() -> bool:
	return _phase == Phase.DIVE


## Entre dans l'eau près de `near` (l'échelle ou le plongeoir). Rien s'il n'y a pas de piscine à côté.
func start(near: SmartObject) -> void:
	_cells = near.pool_cells()
	if _cells.is_empty():
		return
	active = true
	_home = _character.position
	# Images de l'éclaboussure chargées avant d'en avoir besoin.
	for frame in [1, 2]:
		MouzLayers.texture(MouzBody.SPLASH % frame)
	var navigation := _character.world.navigation
	_character.body.in_water = true
	var board := near.definition.water_cells(near.footprint, near.placed.rotation)
	if not board.is_empty():
		# Du bout de la planche vers la case d'eau devant elle (ou sous elle, si le bassin s'arrête là).
		var ahead: Vector2i = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT][posmod(near.placed.rotation, 4)]
		var tip := board[0]
		var landing := tip + ahead if _cells.has(tip + ahead) else tip
		facing = Vector2(ahead)
		_dive_from = navigation.cell_to_world(tip)
		_dive_to = navigation.cell_to_world(landing)
		_character.position = _dive_from
		_set_phase(Phase.DIVE)
		_process(0.0)
		return
	var entry := _cells[0]
	var best := INF
	for cell in _cells:
		var distance := navigation.cell_to_world(cell).distance_to(_home)
		if distance < best:
			best = distance
			entry = cell
	_character.position = navigation.cell_to_world(entry)
	_set_phase(Phase.SWIM)
	_next()


func stop() -> void:
	if not active:
		return
	active = false
	_set_phase(Phase.NONE)
	_character.position = _home
	_character.body.position = Vector2.ZERO
	_character.body.in_water = false


func _set_phase(phase: Phase) -> void:
	_phase = phase
	_time = 0.0
	_character.body.splash = 1 if phase == Phase.SPLASH else 0
	# En l'air, le Mouz passe devant la planche du plongeoir.
	_character.z_index = 1 if phase == Phase.DIVE else 0


func _next() -> void:
	_target = _character.world.navigation.cell_to_world(_cells[_rng.randi_range(0, _cells.size() - 1)])


func _process(delta: float) -> void:
	if not active:
		return
	var scaled := delta * GameClock.time_scale
	_time += scaled
	match _phase:
		Phase.DIVE:
			var t := minf(_time / DIVE_TIME, 1.0)
			_character.position = _dive_from.lerp(_dive_to, t)
			_character.body.position = Vector2(0, -(lerpf(BOARD_HEIGHT, 0.0, t) + sin(t * PI) * ARC_HEIGHT))
			if t >= 1.0:
				_character.body.position = Vector2.ZERO
				_set_phase(Phase.SPLASH)
		Phase.SPLASH:
			_character.body.splash = 1 if _time < SPLASH_TIME / 2.0 else 2
			if _time >= SPLASH_TIME:
				_set_phase(Phase.SWIM)
				_next()
		Phase.SWIM:
			var step := SPEED * scaled
			var to := _target - _character.position
			if to.length() <= step:
				_character.position = _target
				_next()
			else:
				facing = to.normalized()
				_character.position += facing * step
