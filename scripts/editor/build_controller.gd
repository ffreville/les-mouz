class_name BuildController
extends Node2D
## Mode Construire : traduit la souris en opérations de l'éditeur selon l'outil choisi,
## et dessine l'aperçu. Échap ou clic droit annule le geste en cours.
##  - mur / démolir : glisser le long de la grille ;
##  - porte / fenêtre : cliquer sur un mur (R inverse la charnière d'une porte) ;
##  - sol / gomme : glisser pour couvrir un rectangle de cases.

const HANDLE_RADIUS := 7.0
const PREVIEW_ALPHA := 0.45
const LINE_TOOLS: Array[StringName] = [&"wall", &"demolish"]
const AREA_TOOLS: Array[StringName] = [&"floor", &"eraser"]
const OPENING_TOOLS: Array[StringName] = [&"door", &"window"]

var editor: LotEditor
var tool: StringName = &"wall"
## Option de l'outil : couleur de mur, sol, porte ou fenêtre.
var option: Resource

var _hover_point := Vector2i.ZERO
var _hover_cell := Vector2i.ZERO
var _hover_edge := Vector3i.ZERO
var _swing_positive := true
var _hinge_flipped := false
var _drag_start := Vector2i.ZERO
var _dragging := false


## Vrai pendant un tracé (Échap sert alors à l'annuler, pas à ouvrir le menu).
func is_busy() -> bool:
	return _dragging


func setup(p_editor: LotEditor) -> void:
	editor = p_editor


func _ready() -> void:
	EventBus.build_tool_selected.connect(_on_tool_selected)
	GameMode.mode_changed.connect(func(_mode: int) -> void: _cancel())


func _on_tool_selected(p_tool: StringName, p_option: Resource) -> void:
	tool = p_tool
	option = p_option
	_cancel()


func _active() -> bool:
	return GameMode.mode == GameMode.Mode.BUILD and editor != null


func _unhandled_input(event: InputEvent) -> void:
	if not _active():
		return
	if event is InputEventMouseMotion:
		_track_mouse()
		_update_preview()
		return
	if event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_R and tool == &"door":
		_hinge_flipped = not _hinge_flipped
		_update_preview()
		get_viewport().set_input_as_handled()
		return
	var click := event as InputEventMouseButton
	if click == null:
		return
	if click.button_index == MOUSE_BUTTON_RIGHT and click.pressed:
		_cancel()
	elif click.button_index == MOUSE_BUTTON_LEFT:
		_on_left_button(click.pressed)
	else:
		return
	get_viewport().set_input_as_handled()


func _on_left_button(pressed: bool) -> void:
	if tool in OPENING_TOOLS:
		if pressed and option is OpeningDefinition:
			editor.place_opening(_hover_edge, option, _swing_positive, _hinge_flipped)
	elif tool in LINE_TOOLS or tool in AREA_TOOLS:
		if pressed:
			_drag_start = _hover_point if tool in LINE_TOOLS else _hover_cell
			_dragging = true
		elif _dragging:
			_apply_drag()
			_dragging = false
	_update_preview()


## Position de la souris ramenée sur la grille (point, case et arête les plus proches).
func _track_mouse() -> void:
	var cs := float(editor.lot.cell_size)
	var mouse := get_global_mouse_position()
	_hover_point = Edges.nearest_point(mouse, cs)
	_hover_cell = Vector2i((mouse / cs).floor())
	_hover_edge = Edges.nearest(mouse, cs)
	# Le battant s'ouvre du côté du pointeur.
	var line := Vector2(_hover_edge.x, _hover_edge.y) * cs
	_swing_positive = mouse.y > line.y if _hover_edge.z == Edges.HORIZONTAL else mouse.x > line.x


func _drag_rect() -> Rect2i:
	var top_left := Vector2i(mini(_drag_start.x, _hover_cell.x), mini(_drag_start.y, _hover_cell.y))
	var bottom_right := Vector2i(maxi(_drag_start.x, _hover_cell.x), maxi(_drag_start.y, _hover_cell.y))
	return Rect2i(top_left, bottom_right - top_left + Vector2i.ONE)


func _apply_drag() -> void:
	match tool:
		&"wall":
			if option is WallStyleDefinition:
				editor.build_walls(Edges.line(_drag_start, _hover_point), option)
		&"demolish":
			editor.demolish_walls(Edges.line(_drag_start, _hover_point))
		&"floor":
			if option is FloorDefinition:
				editor.paint_floor(_drag_rect(), option)
		&"eraser":
			editor.erase_floor(_drag_rect())


func _cancel() -> void:
	_dragging = false
	EventBus.cost_preview_changed.emit("", 0)
	queue_redraw()


## Met à jour le dessin et l'étiquette de coût.
func _update_preview() -> void:
	queue_redraw()
	var text := ""
	var cost := 0
	if tool in OPENING_TOOLS and option is OpeningDefinition:
		text = option.display_name
		cost = option.price
	elif _dragging:
		match tool:
			&"wall":
				if option is WallStyleDefinition:
					var quote := editor.quote_walls(Edges.line(_drag_start, _hover_point), option)
					text = _count(quote["edges"].size(), "mur")
					cost = quote["cost"]
			&"demolish":
				var quote := editor.quote_demolish(Edges.line(_drag_start, _hover_point))
				text = "Démolir " + _count(quote["edges"].size(), "mur")
				cost = -quote["refund"]
			&"floor":
				if option is FloorDefinition:
					var quote := editor.quote_floor(_drag_rect(), option)
					text = _count(quote["cells"].size(), "case")
					cost = quote["cost"]
			&"eraser":
				var quote := editor.quote_erase(_drag_rect())
				text = "Gommer " + _count(quote["cells"].size(), "case")
				cost = -quote["refund"]
	EventBus.cost_preview_changed.emit(text, cost)


func _count(amount: int, word: String) -> String:
	return "%d %s%s" % [amount, word, "s" if amount > 1 else ""]


# --- Aperçu ----------------------------------------------------------------------

func _draw() -> void:
	if not _active():
		return
	var cs := float(editor.lot.cell_size)
	if tool in LINE_TOOLS:
		_draw_line_preview(cs)
	elif tool in AREA_TOOLS:
		_draw_area_preview(cs)
	elif tool in OPENING_TOOLS and option is OpeningDefinition:
		_draw_opening_preview(cs)


func _draw_line_preview(cs: float) -> void:
	if not _dragging:
		_draw_handle(Vector2(_hover_point) * cs)
		return
	for edge in Edges.line(_drag_start, _hover_point):
		var rect := Edges.to_rect(edge, cs, Palette.EPAISSEUR_MUR, Palette.EPAISSEUR_MUR / 2)
		if tool == &"demolish":
			if editor.lot.has_wall(edge):
				draw_rect(rect, Color(Palette.CRITIQUE, PREVIEW_ALPHA))
			continue
		var allowed := editor.can_hold_wall(edge)
		var color: Color = option.color if option is WallStyleDefinition else Palette.MUR
		draw_rect(rect, Color(color if allowed else Palette.CRITIQUE, PREVIEW_ALPHA))
		_draw_dashed_rect(rect.grow(1), Palette.ACCENT if allowed else Palette.CRITIQUE)
	_draw_handle(Vector2(_drag_start) * cs)
	_draw_handle(Vector2(Edges.snap_line_end(_drag_start, _hover_point)) * cs)


func _draw_area_preview(cs: float) -> void:
	var rect := _drag_rect() if _dragging else Rect2i(_hover_cell, Vector2i.ONE)
	rect = rect.intersection(Rect2i(Vector2i.ZERO, editor.lot.size))
	if rect.size == Vector2i.ZERO:
		return
	var area := Rect2(Vector2(rect.position) * cs, Vector2(rect.size) * cs)
	if tool == &"floor" and option is FloorDefinition and option.texture != null:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				draw_texture_rect(option.texture, Rect2(Vector2(x, y) * cs, Vector2(cs, cs)), false,
						Color(1, 1, 1, 0.75))
		_draw_dashed_rect(area, Palette.ACCENT)
	else:
		draw_rect(area, Color(Palette.CRITIQUE, 0.18))
		_draw_dashed_rect(area, Palette.CRITIQUE)


func _draw_opening_preview(cs: float) -> void:
	var ghost := PlacedOpening.new()
	ghost.definition = option
	ghost.edge = _hover_edge
	ghost.swing_positive = _swing_positive
	ghost.hinge_flipped = _hinge_flipped
	var valid: bool = editor.quote_opening(_hover_edge, option)["valid"]
	for edge in ghost.edges():
		var rect := Edges.to_rect(edge, cs, Palette.EPAISSEUR_MUR + 4)
		draw_rect(rect, Color(Palette.ACCENT if valid else Palette.CRITIQUE, 0.18))
		_draw_dashed_rect(rect, Palette.ACCENT if valid else Palette.CRITIQUE)
	WallView.draw_opening(self, ghost, cs, Color(1, 1, 1, 0.6))


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var points := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position]
	for i in 4:
		draw_dashed_line(points[i], points[i + 1], color, 2.0, 4.0)


func _draw_handle(at: Vector2) -> void:
	draw_circle(at, HANDLE_RADIUS, Color.WHITE)
	draw_circle(at, HANDLE_RADIUS, Palette.ACCENT, false, 3.0, true)
