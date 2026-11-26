class_name WeatherSky
extends Node2D
## Ce qui tombe du ciel, par-dessus tout le monde (et sous l'interface) : pluie en traits obliques,
## orage plus dense avec des éclairs, flocons qui dérivent. Les gouttes sont placées dans la partie
## visible du monde, quel que soit le zoom. Caché en Construire et Acheter.

const RAIN := Color("#D6E6F2", 0.7)
const RAIN_DROPS := 160
const STORM_DROPS := 260
const RAIN_SPEED := 1.6
const SNOW_FLAKES := 140
const SNOW_SPEED := 0.12
const FLAKE := Color("#FFFFFF", 0.95)
const FLASH := Color("#F4F1FF")
const FLASH_TIME := 0.45
## Entre deux éclairs pendant un orage (secondes réelles), en plus de ceux de la foudre.
const FLASH_EVERY := Vector2(6.0, 16.0)

var _world: World
## Gouttes et flocons, en coordonnées de 0 à 1 dans la partie visible : x, y, et une phase.
var _drops: Array[Vector3] = []
var _flash := 0.0
var _next_flash := 8.0
var _rng := RandomNumberGenerator.new()


func setup(world: World) -> void:
	_world = world
	_rng.randomize()
	for i in STORM_DROPS:
		_drops.append(Vector3(_rng.randf(), _rng.randf(), _rng.randf()))
	world.weather.lightning.connect(func() -> void: _flash = FLASH_TIME)


func _process(delta: float) -> void:
	if _world == null:
		return
	var kind := _world.weather.current()
	visible = GameMode.is_live() and (Weather.is_wet(kind) or _flash > 0.0)
	if not visible:
		return
	var speed := 1.0 if GameClock.is_paused() else 1.0 + 0.3 * GameClock.speed_index
	var fall := (SNOW_SPEED if kind == &"neige" else RAIN_SPEED) * delta * speed
	for i in _drops.size():
		var drop := _drops[i]
		drop.y += fall * (0.8 + 0.4 * drop.z)
		if kind != &"neige":
			drop.x -= fall * 0.25
		if drop.y > 1.0:
			drop.y -= 1.0
			drop.x = _rng.randf()
		drop.x = fposmod(drop.x, 1.0)
		_drops[i] = drop
	if kind == &"orage":
		_next_flash -= delta
		if _next_flash <= 0.0:
			_next_flash = _rng.randf_range(FLASH_EVERY.x, FLASH_EVERY.y)
			_flash = FLASH_TIME
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if _world == null:
		return
	var kind := _world.weather.current()
	var view := get_canvas_transform().affine_inverse() * get_viewport_rect()
	var zoom := get_canvas_transform().get_scale().x
	if kind == &"neige":
		for i in SNOW_FLAKES:
			var drop := _drops[i]
			var sway := sin(drop.y * 18.0 + drop.z * 6.0) * 6.0 / zoom
			var at := view.position + Vector2(drop.x * view.size.x + sway, drop.y * view.size.y)
			draw_circle(at, (1.2 + drop.z * 1.4) / zoom, FLAKE)
	elif kind in [&"pluie", &"orage"]:
		var count := STORM_DROPS if kind == &"orage" else RAIN_DROPS
		var length := 14.0 / zoom
		for i in count:
			var drop := _drops[i]
			var at := view.position + Vector2(drop.x * view.size.x, drop.y * view.size.y)
			draw_line(at, at + Vector2(-length * 0.3, length), RAIN, 1.2 / zoom)
	if _flash > 0.0:
		draw_rect(view, Color(FLASH, 0.55 * _flash / FLASH_TIME))
