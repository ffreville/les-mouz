class_name CameraController
extends Camera2D
## Caméra qui défile (flèches, ZQSD/WASD, bouton du milieu) et zoome (molette).
## Au doigt : glisser à un doigt la fait défiler en mode Vivre, glisser à deux doigts la fait
## défiler partout, et pincer zoome. Elle reste au-dessus du terrain.
## Un doigt qui a glissé (ou un geste à deux doigts) n'est pas un toucher : `touch_moved()` le dit
## aux scripts qui réagissent au toucher relâché (ordres, placement).

## Un geste à deux doigts commence : ce qu'un doigt avait commencé (tracer un mur…) s'annule.
signal gesture_started

## Au-delà de ce déplacement (pixels d'écran), un doigt glisse au lieu de toucher.
const TAP_SLOP := 14.0

@export var pan_speed: float = 600.0
@export var min_zoom: float = 0.6
@export var max_zoom: float = 1.6
@export var zoom_step: float = 0.1
## Marge autorisée autour du terrain, en pixels.
@export var margin: float = 240.0

var _lot_rect := Rect2()
var _dragging := false
## Doigts posés : index → position à l'écran.
var _touches: Dictionary[int, Vector2] = {}
var _touch_start := Vector2.ZERO
var _moved := false
var _pinch_distance := 0.0


## Limite le défilement au terrain (appelé par le monde).
func set_bounds(lot_rect: Rect2) -> void:
	_lot_rect = lot_rect
	_clamp()


func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		direction.y += 1
	if direction != Vector2.ZERO and get_viewport().gui_get_focus_owner() == null:
		position += direction.normalized() * pan_speed * delta / zoom.x
		_clamp()


## Vrai si le doigt posé (ou levé à l'instant) a glissé ou fait un geste à deux doigts.
func touch_moved() -> bool:
	return _moved


func _input(event: InputEvent) -> void:
	# Les doigts sont suivis avant l'interface, pour savoir combien il y en a.
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			if _touches.is_empty():
				_touch_start = touch.position
				_moved = false
			_touches[touch.index] = touch.position
			if _touches.size() == 2:
				_moved = true
				_pinch_distance = _spread()
				gesture_started.emit()
		else:
			_touches.erase(touch.index)
		return
	var drag := event as InputEventScreenDrag
	if drag == null or not _touches.has(drag.index):
		return
	if _touches.size() >= 2:
		var before := _center()
		_touches[drag.index] = drag.position
		position -= (_center() - before) / zoom.x
		var spread := _spread()
		if _pinch_distance > 0.0 and spread > 0.0:
			_zoom_to(zoom.x * spread / _pinch_distance)
		_pinch_distance = spread
		_clamp()
		return
	_touches[drag.index] = drag.position
	if not _moved and drag.position.distance_to(_touch_start) > TAP_SLOP:
		_moved = true
	# À un doigt, on fait défiler en mode Vivre (en Construire et Acheter, le doigt trace).
	if _moved and GameMode.is_live() and not _over_interface(drag.position):
		position -= drag.relative / zoom.x
		_clamp()


func _center() -> Vector2:
	var sum := Vector2.ZERO
	for point in _touches.values():
		sum += point
	return sum / maxf(_touches.size(), 1)


func _spread() -> float:
	var points := _touches.values()
	return points[0].distance_to(points[1]) if points.size() >= 2 else 0.0


## Le doigt a commencé sur un panneau de l'interface (il le fait défiler, pas la caméra).
func _over_interface(_at: Vector2) -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null and hovered.mouse_filter == Control.MOUSE_FILTER_STOP


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		match button.button_index:
			MOUSE_BUTTON_MIDDLE:
				_dragging = button.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if button.pressed:
					_zoom_by(zoom_step)
			MOUSE_BUTTON_WHEEL_DOWN:
				if button.pressed:
					_zoom_by(-zoom_step)
		return
	# Pavé tactile : pincer zoome, glisser à deux doigts fait défiler.
	var magnify := event as InputEventMagnifyGesture
	if magnify != null:
		_zoom_to(zoom.x * magnify.factor)
		return
	var pan := event as InputEventPanGesture
	if pan != null:
		position += pan.delta * 8.0 / zoom.x
		_clamp()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		position -= motion.relative / zoom.x
		_clamp()


func _zoom_by(amount: float) -> void:
	_zoom_to(zoom.x + amount)


func _zoom_to(value: float) -> void:
	value = clampf(value, min_zoom, max_zoom)
	zoom = Vector2(value, value)
	_clamp()


func _clamp() -> void:
	if _lot_rect.size == Vector2.ZERO:
		return
	var area := _lot_rect.grow(margin)
	position = position.clamp(area.position, area.end)
