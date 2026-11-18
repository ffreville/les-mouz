class_name BuildController
extends Node2D
## Mode Construire : traduit la souris en opérations de l'éditeur selon l'outil choisi,
## et dessine l'aperçu (murs en cours de tracé, poignées). Échap annule le tracé.

const HANDLE_RADIUS := 7.0
const PREVIEW_ALPHA := 0.45

var editor: LotEditor
var tool: StringName = &"wall"
## Option de l'outil : couleur de mur, sol, porte ou fenêtre.
var option: Resource

var _hover_point := Vector2i.ZERO
var _drag_start := Vector2i.ZERO
var _dragging := false


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
	var cs := float(editor.lot.cell_size)
	if event is InputEventMouseMotion:
		_hover_point = Edges.nearest_point(get_global_mouse_position(), cs)
		_update_preview()
		return
	if event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
		return
	var click := event as InputEventMouseButton
	if click == null:
		return
	if click.button_index == MOUSE_BUTTON_RIGHT and click.pressed:
		_cancel()
	elif click.button_index == MOUSE_BUTTON_LEFT and tool in [&"wall", &"demolish"]:
		if click.pressed:
			_drag_start = _hover_point
			_dragging = true
		elif _dragging:
			_apply_line()
			_dragging = false
		_update_preview()
	else:
		return
	get_viewport().set_input_as_handled()


func _apply_line() -> void:
	var edges := Edges.line(_drag_start, _hover_point)
	if tool == &"wall" and option is WallStyleDefinition:
		editor.build_walls(edges, option)
	elif tool == &"demolish":
		editor.demolish_walls(edges)


func _cancel() -> void:
	_dragging = false
	EventBus.cost_preview_changed.emit("", 0)
	queue_redraw()


## Met à jour le dessin et l'étiquette de coût.
func _update_preview() -> void:
	queue_redraw()
	if not _dragging:
		EventBus.cost_preview_changed.emit("", 0)
		return
	var edges := Edges.line(_drag_start, _hover_point)
	if tool == &"wall" and option is WallStyleDefinition:
		var quote := editor.quote_walls(edges, option)
		var count: int = quote["edges"].size()
		EventBus.cost_preview_changed.emit("%d mur%s" % [count, "s" if count > 1 else ""], quote["cost"])
	elif tool == &"demolish":
		var quote := editor.quote_demolish(edges)
		var count: int = quote["edges"].size()
		EventBus.cost_preview_changed.emit("Démolir %d mur%s" % [count, "s" if count > 1 else ""], -quote["refund"])


func _draw() -> void:
	if not _active() or not tool in [&"wall", &"demolish"]:
		return
	var cs := float(editor.lot.cell_size)
	if _dragging:
		var end := Edges.snap_line_end(_drag_start, _hover_point)
		for edge in Edges.line(_drag_start, _hover_point):
			_draw_edge_preview(edge, cs)
		_draw_handle(Vector2(_drag_start) * cs)
		_draw_handle(Vector2(end) * cs)
	else:
		_draw_handle(Vector2(_hover_point) * cs)


func _draw_edge_preview(edge: Vector3i, cs: float) -> void:
	var rect := Edges.to_rect(edge, cs, Palette.EPAISSEUR_MUR, Palette.EPAISSEUR_MUR / 2)
	var allowed := editor.can_hold_wall(edge)
	if tool == &"demolish":
		if editor.lot.has_wall(edge):
			draw_rect(rect, Color(Palette.CRITIQUE, PREVIEW_ALPHA))
		return
	var color: Color = option.color if option is WallStyleDefinition else Palette.MUR
	draw_rect(rect, Color(color if allowed else Palette.CRITIQUE, PREVIEW_ALPHA))
	_draw_dashed_rect(rect.grow(1), Palette.ACCENT if allowed else Palette.CRITIQUE)


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var points := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position]
	for i in 4:
		draw_dashed_line(points[i], points[i + 1], color, 2.0, 4.0)


func _draw_handle(at: Vector2) -> void:
	draw_circle(at, HANDLE_RADIUS, Color.WHITE)
	draw_circle(at, HANDLE_RADIUS, Palette.ACCENT, false, 3.0, true)
