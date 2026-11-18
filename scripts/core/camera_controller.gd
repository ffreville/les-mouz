class_name CameraController
extends Camera2D
## Caméra qui défile (flèches, ZQSD/WASD, bouton du milieu) et zoome (molette).
## Elle reste au-dessus du terrain.

@export var pan_speed: float = 600.0
@export var min_zoom: float = 0.6
@export var max_zoom: float = 1.6
@export var zoom_step: float = 0.1
## Marge autorisée autour du terrain, en pixels.
@export var margin: float = 240.0

var _lot_rect := Rect2()
var _dragging := false


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
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		position -= motion.relative / zoom.x
		_clamp()


func _zoom_by(amount: float) -> void:
	var value := clampf(zoom.x + amount, min_zoom, max_zoom)
	zoom = Vector2(value, value)
	_clamp()


func _clamp() -> void:
	if _lot_rect.size == Vector2.ZERO:
		return
	var area := _lot_rect.grow(margin)
	position = position.clamp(area.position, area.end)
