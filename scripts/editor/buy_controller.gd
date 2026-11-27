class_name BuyController
extends Node2D
## Placement des objets : en mode Acheter, et en mode Construire avec l'outil « Déplacer ».
##  - un objet choisi dans le catalogue suit la souris ; R le tourne ; clic pour l'acheter ;
##  - un clic sur un objet posé ouvre Déplacer / Revendre ;
##  - pendant un déplacement : clic pour reposer, Suppr pour revendre, Échap pour annuler.
## Au doigt : l'objet en main suit le doigt (dessiné un peu au-dessus, pour rester visible), et la
## barre de placement (PlacementBar) le tourne, le pose ou le lâche. Toucher un objet posé ouvre son
## menu ; le faire glisser le déplace : il se repose en levant le doigt si la place est bonne,
## sinon il reste en main.

## On prend un objet en main (`holding`) ou on le lâche.
signal holding_changed(holding: bool)

const GHOST_ALPHA := 0.6
const BADGE_RADIUS := 11.0
const DELETE_ICON := preload("res://assets/icons/white/fermer.svg")
const MOVE_ICON := preload("res://assets/icons/ink/deplacer.svg")
const SELL_ICON := preload("res://assets/icons/ink/vendre.svg")

var editor: LotEditor
## Objet en cours de placement (nouveau ou déplacé), null sinon.
var _definition: SmartObjectDefinition
var _collection: StringName = &""
var _moving: PlacedObject
var _rotation := 0
var _cell := Vector2i.ZERO
var _build_tool: StringName = &"wall"
## Dernière position du pointeur (souris ou doigt), dans le monde, tirée des événements reçus.
var _pointer := Vector2.ZERO
## Au doigt : l'objet posé sous le doigt quand il s'est posé, et vrai pendant qu'on le fait glisser.
var _pressed_object: PlacedObject
var _dragging_object := false
## Au doigt, l'objet en main est dessiné à cette distance au-dessus du doigt (pixels d'écran).
const FINGER_OFFSET := 56.0


## Vrai quand un objet est en main (Échap sert alors à le lâcher, pas à ouvrir le menu).
func is_busy() -> bool:
	return _definition != null


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


func _on_catalog_item_selected(definition: Resource, collection: StringName) -> void:
	# Changer de style pendant qu'on tient déjà cet objet ne remet pas la rotation à zéro.
	var same := definition == _definition and _moving == null
	_moving = null
	_definition = definition
	_collection = collection
	if same:
		queue_redraw()
		return
	_rotation = 0
	_follow_start()
	holding_changed.emit(true)


## Sur mobile, l'objet pris dans le catalogue apparaît au milieu de l'écran (le doigt est sur le
## catalogue) ; à la souris, il suit le pointeur.
func _follow_start() -> void:
	if Device.mobile and editor != null:
		_track_point(editor.world.camera.get_screen_center_position())
	else:
		_track_mouse()
	_update_preview()


## Barre de placement au doigt : tourner, poser, lâcher, revendre (objet déplacé).
func turn() -> void:
	if _definition != null:
		_rotation = (_rotation + 1) % 4
		_update_preview()


func place() -> void:
	if _definition != null:
		_place()


func drop() -> void:
	_stop()


func sell_moving() -> void:
	if _moving != null:
		editor.sell_object(_moving)
		_stop()


func is_moving() -> bool:
	return _moving != null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_pointer = make_input_local(event).position
	if not _active():
		return
	if event is InputEventMouseMotion:
		if Touch.is_touch(event):
			_on_touch_motion()
		else:
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
	if click != null and Touch.is_touch(click):
		_on_touch(click)
		get_viewport().set_input_as_handled()
		return
	if click == null or not click.pressed:
		return
	if click.button_index == MOUSE_BUTTON_RIGHT:
		_stop()
	elif click.button_index == MOUSE_BUTTON_LEFT:
		_on_click(click.position)
	else:
		return
	get_viewport().set_input_as_handled()


## Au doigt : l'objet en main se pose là où on touche (il suit le doigt qui glisse) ; sans objet en
## main, toucher un objet posé ouvre son menu.
func _on_touch(click: InputEventMouseButton) -> void:
	if click.pressed:
		_pressed_object = _placed_under(_pointer) if _definition == null else null
		if _definition != null:
			_track_finger()
			_update_preview()
		return
	_pressed_object = null
	if _dragging_object:
		# Fin du glisser : l'objet se repose s'il le peut, sinon il reste en main avec la barre.
		_dragging_object = false
		_track_finger()
		if editor.move_object(_moving, _cell, _rotation):
			Sfx.play(&"poser")
			_stop()
		else:
			Sfx.play(&"erreur")
			_update_preview()
		return
	if _definition != null:
		_track_finger()
		_update_preview()
	elif not editor.world.camera.touch_moved():
		_on_click(click.position)


## Le doigt glisse : il emporte l'objet posé sous lui, ou fait suivre l'objet en main.
func _on_touch_motion() -> void:
	if _definition == null and _pressed_object != null and editor.world.camera.touch_moved():
		_start_moving(_pressed_object)
		_dragging_object = true
	if _definition != null:
		_track_finger()
		_update_preview()


## L'objet suit le doigt, un peu au-dessus de lui.
func _track_finger() -> void:
	var zoom := get_canvas_transform().get_scale().x
	_track_point(_pointer - Vector2(0, FINGER_OFFSET / maxf(zoom, 0.01)))


## L'objet posé sous ce point du monde (son image d'abord, puis sa case), ou null.
func _placed_under(point: Vector2) -> PlacedObject:
	var cs := float(editor.lot.cell_size)
	var under := editor.world.get_object_at_point(point)
	return under.placed if under != null else editor.object_at(Vector2i((point / cs).floor()))


func _on_click(screen_position: Vector2) -> void:
	if _definition == null:
		# L'image d'un meuble (qui dépasse au-dessus de sa case) passe avant la case visée.
		var placed := _placed_under(_pointer)
		if placed != null:
			_open_object_menu(placed, screen_position)
		return
	_place()


func _place() -> void:
	if _moving != null:
		if editor.move_object(_moving, _cell, _rotation):
			Sfx.play(&"poser")
			_stop()
		else:
			Sfx.play(&"erreur")
	elif editor.buy_object(_definition, _cell, _rotation, _collection):
		# On garde l'objet en main pour en poser un autre, s'il reste de quoi payer.
		if not Wallet.can_afford(_definition.price):
			_stop()
	else:
		Sfx.play(&"erreur")
	_update_preview()


## Bulle Déplacer / Revendre au clic sur un objet posé.
func _open_object_menu(placed: PlacedObject, screen_position: Vector2) -> void:
	var refund := Wallet.resale_value(placed)
	var full := refund == placed.price
	var options: Array = [
		{"label": "Déplacer", "icon": MOVE_ICON, "callback": _start_moving.bind(placed)},
	]
	options.append_array(_style_options(placed))
	options.append_array([
		{"label": "Revendre +%s" % Palette.format_mz(refund), "icon": SELL_ICON,
			"callback": func() -> void: editor.sell_object(placed)},
		{"label": "Remboursé en entier aujourd'hui" if full else "75 % du prix d'achat", "disabled": true},
	])
	EventBus.context_menu_requested.emit(placed.definition.display_name, options, screen_position)


## Une ligne par autre collection : « Style Rétro · gratuit » ou « Style Rétro · 200 Mz ».
func _style_options(placed: PlacedObject) -> Array:
	var options: Array = []
	var cost := editor.restyle_cost(placed)
	for collection in Catalog.collections():
		if collection.id == placed.get_collection() or not placed.definition.sprites.has(collection.id):
			continue
		var price := "gratuit" if cost == 0 else Palette.format_mz(cost)
		options.append({
			"label": "Style %s · %s" % [collection.display_name, price],
			"icon": collection.icon, "icon_modulate": collection.color,
			"disabled": not Wallet.can_afford(cost),
			"callback": func() -> void: editor.restyle_object(placed, collection.id),
		})
	return options


func _start_moving(placed: PlacedObject) -> void:
	_moving = placed
	_definition = placed.definition
	_collection = placed.get_collection()
	_rotation = placed.rotation
	_track_mouse()
	_update_preview()
	holding_changed.emit(true)


func _stop() -> void:
	var was_placing := _definition != null
	_dragging_object = false
	_definition = null
	_moving = null
	EventBus.cost_preview_changed.emit("", 0)
	queue_redraw()
	if was_placing:
		EventBus.placement_ended.emit()
		holding_changed.emit(false)


## L'emprise est centrée sur le pointeur.
func _track_mouse() -> void:
	_track_point(_pointer)


func _track_point(point: Vector2) -> void:
	if _definition == null or editor == null:
		return
	var cs := float(editor.lot.cell_size)
	var size := _definition.size
	if _rotation % 2 == 1:
		size = Vector2i(size.y, size.x)
	var corner := point / cs - Vector2(size) / 2.0
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
	SmartObject.draw_definition(self, _definition, _rotation, origin, cs, Color(1, 1, 1, GHOST_ALPHA), _collection)
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
