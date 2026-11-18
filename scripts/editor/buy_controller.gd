class_name BuyController
extends Node2D
## Placement des objets : en mode Acheter, et en mode Construire avec l'outil « Déplacer ».
##  - un objet choisi dans le catalogue suit la souris ; R le tourne ; clic pour l'acheter ;
##  - un clic sur un objet posé ouvre Déplacer / Revendre ;
##  - pendant un déplacement : clic pour reposer, Suppr pour revendre, Échap pour annuler.

const GHOST_ALPHA := 0.6
const BADGE_RADIUS := 11.0
const DELETE_ICON := preload("res://assets/icons/white/fermer.svg")
const MOVE_ICON := preload("res://assets/icons/ink/deplacer.svg")
const SELL_ICON := preload("res://assets/icons/ink/vendre.svg")

var editor: LotEditor
## Objet en cours de placement (nouveau ou déplacé), null sinon.
var _definition: SmartObjectDefinition
var _moving: PlacedObject
var _rotation := 0
var _cell := Vector2i.ZERO
var _build_tool: StringName = &"wall"


func setup(p_editor: LotEditor) -> void:
	editor = p_editor


func _ready() -> void:
	EventBus.catalog_item_selected.connect(_on_catalog_item_selected)
	EventBus.build_tool_selected.connect(_on_build_tool_selected)
	GameMode.mode_changed.connect(func(_mode: int) -> void: _stop())


func _active() -> bool:
	if editor == null:
		return false
	return GameMode.mode == GameMode.Mode.BUY \
			or (GameMode.mode == GameMode.Mode.BUILD and _build_tool == &"move")


func _on_build_tool_selected(tool: StringName, _option: Resource) -> void:
	_build_tool = tool
	_stop()


func _on_catalog_item_selected(definition: Resource) -> void:
	_moving = null
	_definition = definition
	_rotation = 0
	_track_mouse()
	_update_preview()


func _unhandled_input(event: InputEvent) -> void:
	if not _active():
		return
	if event is InputEventMouseMotion:
		_track_mouse()
		_update_preview()
		return
	if event.is_action_pressed("ui_cancel") and _definition != null:
		_stop()
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and _definition != null:
		if key.keycode == KEY_R:
			_rotation = (_rotation + 1) % 4
			_track_mouse()
			_update_preview()
		elif key.keycode == KEY_DELETE and _moving != null:
			editor.sell_object(_moving)
			_stop()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	if click.button_index == MOUSE_BUTTON_RIGHT:
		_stop()
	elif click.button_index == MOUSE_BUTTON_LEFT:
		_on_click(click.position)
	else:
		return
	get_viewport().set_input_as_handled()


func _on_click(screen_position: Vector2) -> void:
	if _definition == null:
		var cs := float(editor.lot.cell_size)
		var placed := editor.object_at(Vector2i((get_global_mouse_position() / cs).floor()))
		if placed != null:
			_open_object_menu(placed, screen_position)
		return
	if _moving != null:
		if editor.move_object(_moving, _cell, _rotation):
			_stop()
	elif editor.buy_object(_definition, _cell, _rotation):
		# On garde l'objet en main pour en poser un autre, s'il reste de quoi payer.
		if not Wallet.can_afford(_definition.price):
			_stop()
	_update_preview()


## Bulle Déplacer / Revendre au clic sur un objet posé.
func _open_object_menu(placed: PlacedObject, screen_position: Vector2) -> void:
	var refund := Wallet.resale_value(placed)
	var full := refund == placed.price
	var options: Array = [
		{"label": "Déplacer", "icon": MOVE_ICON, "callback": _start_moving.bind(placed)},
		{"label": "Revendre +%s" % Palette.format_mz(refund), "icon": SELL_ICON,
			"callback": func() -> void: editor.sell_object(placed)},
		{"label": "Remboursé en entier aujourd'hui" if full else "75 % du prix d'achat", "disabled": true},
	]
	EventBus.context_menu_requested.emit(placed.definition.display_name, options, screen_position)


func _start_moving(placed: PlacedObject) -> void:
	_moving = placed
	_definition = placed.definition
	_rotation = placed.rotation
	_track_mouse()
	_update_preview()


func _stop() -> void:
	var was_placing := _definition != null
	_definition = null
	_moving = null
	EventBus.cost_preview_changed.emit("", 0)
	queue_redraw()
	if was_placing:
		EventBus.placement_ended.emit()


## L'emprise est centrée sur le pointeur.
func _track_mouse() -> void:
	if _definition == null or editor == null:
		return
	var cs := float(editor.lot.cell_size)
	var size := _definition.size
	if _rotation % 2 == 1:
		size = Vector2i(size.y, size.x)
	var corner := get_global_mouse_position() / cs - Vector2(size) / 2.0
	_cell = Vector2i(corner.round())


func _update_preview() -> void:
	queue_redraw()
	if _definition == null:
		EventBus.cost_preview_changed.emit("", 0)
		return
	var quote := editor.quote_object(_definition, _cell, _rotation, _moving)
	var text := "Déplacer : %s" % _definition.display_name if _moving != null else _definition.display_name
	if not quote["valid"]:
		text += " · " + quote["reason"]
	EventBus.cost_preview_changed.emit(text, quote["cost"])


func _draw() -> void:
	if not _active() or _definition == null:
		return
	var cs := float(editor.lot.cell_size)
	var valid: bool = editor.quote_object(_definition, _cell, _rotation, _moving)["valid"]
	var origin := Vector2(_cell) * cs
	SmartObject.draw_definition(self, _definition, _rotation, origin, cs, Color(1, 1, 1, GHOST_ALPHA))
	var size := Vector2(_definition.size)
	if _rotation % 2 == 1:
		size = Vector2(size.y, size.x)
	var frame := Rect2(origin, size * cs).grow(2)
	var color := Palette.ACCENT if valid else Palette.CRITIQUE
	draw_style_box(HudTheme.box(Color(color, 0.16 if valid else 0.18), 6), frame)
	if valid:
		draw_style_box(HudTheme.box(Color.TRANSPARENT, 6, color, 2), frame)
		return
	var corners := [frame.position, Vector2(frame.end.x, frame.position.y), frame.end, Vector2(frame.position.x, frame.end.y), frame.position]
	for i in 4:
		draw_dashed_line(corners[i], corners[i + 1], color, 2.0, 5.0)
	# Pastille ✕ en haut à droite.
	var badge := Vector2(frame.end.x, frame.position.y)
	draw_circle(badge, BADGE_RADIUS, Palette.CRITIQUE)
	draw_texture_rect(DELETE_ICON, Rect2(badge - Vector2(7, 7), Vector2(14, 14)), false)
