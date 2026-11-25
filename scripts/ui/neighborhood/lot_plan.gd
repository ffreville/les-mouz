class_name LotPlan
extends Control
## Plan d'un terrain vu de dessus, en petit (carte du quartier) : sols, murs, portes et objets.
## Le terrain est mis à l'échelle pour tenir dans le contrôle, centré.

const DOOR := Color("#C9A27E")
const WINDOW := Color("#BFE3F2")

var lot: Lot:
	set(value):
		lot = value
		queue_redraw()


func _init(p_lot: Lot = null, min_size := Vector2.ZERO) -> void:
	lot = p_lot
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if lot == null:
		return
	var cell := minf(size.x / lot.size.x, size.y / lot.size.y)
	var origin := (size - Vector2(lot.size) * cell) / 2.0
	draw_rect(Rect2(origin, Vector2(lot.size) * cell), Palette.JARDIN)
	for position in lot.floors:
		var floor_piece: PlacedFloor = lot.floors[position]
		var rect := Rect2(origin + Vector2(position) * cell, Vector2(cell, cell))
		if floor_piece.definition.texture != null:
			draw_texture_rect(floor_piece.definition.texture, rect, false)
		else:
			draw_rect(rect, Palette.PISTE)
	for placed in lot.objects:
		_draw_object(placed, origin, cell)
	var width := maxf(cell * 0.35, 1.5)
	for edge in lot.walls:
		var segment := _segment(edge, origin, cell)
		draw_line(segment[0], segment[1], lot.walls[edge].style.color, width)
	for edge in lot.fences:
		var segment := _segment(edge, origin, cell)
		draw_line(segment[0], segment[1], lot.fences[edge].definition.post_color, maxf(width * 0.6, 1.0))
	for opening in lot.openings:
		var color := DOOR if opening.definition.is_passable() else WINDOW
		for edge in opening.edges():
			var segment := _segment(edge, origin, cell)
			var inset := (segment[1] - segment[0]) * 0.15
			draw_line(segment[0] + inset, segment[1] - inset, color, width)


## L'image vue de dessus de l'objet, tournée selon sa rotation, dans son emprise.
func _draw_object(placed: PlacedObject, origin: Vector2, cell: float) -> void:
	var rect := Rect2(origin + Vector2(placed.cell) * cell, Vector2(placed.size()) * cell)
	var texture := placed.definition.get_sprite(placed.get_collection())
	if texture == null:
		draw_rect(rect, placed.definition.color)
		return
	var unrotated := Vector2(placed.definition.size) * cell
	draw_set_transform(rect.get_center(), placed.rotation * PI / 2.0)
	draw_texture_rect(texture, Rect2(-unrotated / 2.0, unrotated), false)
	draw_set_transform(Vector2.ZERO)


func _segment(edge: Vector3i, origin: Vector2, cell: float) -> Array[Vector2]:
	var start := origin + Vector2(edge.x, edge.y) * cell
	var along := Vector2(cell, 0) if edge.z == Edges.HORIZONTAL else Vector2(0, cell)
	return [start, start + along]
