class_name FloorView
extends Node2D
## Dessine le sol : herbe sombre et haie autour du terrain, puis le revêtement de chaque case.
## Calque du dessous : les objets et les murs sont dessinés par-dessus.

## Marge d'herbe dessinée autour du terrain, en pixels.
const OUTSIDE_MARGIN := 1200.0
const HEDGE_WIDTH := 10.0

## Pièces du bord d'un plancher d'étage (brief n° 7), posées dans les cases vides voisines.
const EDGE_PATH := "res://assets/murs/%s.svg"

var _lot: Lot
var _level := 0


func render(lot: Lot, level := 0) -> void:
	_lot = lot
	_level = level
	queue_redraw()


func _draw() -> void:
	if _lot == null:
		return
	if _level > 0:
		_draw_upper()
		return
	var cs := float(_lot.cell_size)
	var area := Rect2(Vector2.ZERO, Vector2(_lot.size) * cs)
	draw_rect(area.grow(OUTSIDE_MARGIN), Palette.HORS_TERRAIN)
	draw_style_box(HudTheme.box(Palette.HAIE, int(HEDGE_WIDTH)), area.grow(HEDGE_WIDTH))
	for y in _lot.size.y:
		for x in _lot.size.x:
			var cell := Vector2i(x, y)
			var floor_definition := _lot.floor_at(cell)
			var rect := Rect2(Vector2(cell) * cs, Vector2(cs, cs))
			if floor_definition != null and floor_definition.texture != null:
				draw_texture_rect(floor_definition.texture, rect, false)
			else:
				draw_rect(rect, Palette.JARDIN)


## Étage : l'ombre des planchers sur le niveau du dessous, les cases qui ont un sol, puis la tranche
## des planchers là où ils s'arrêtent (bords, angles sortants et rentrants).
func _draw_upper() -> void:
	var cs := float(_lot.cell_size)
	var cells: Array[Vector2i] = []
	for y in _lot.size.y:
		for x in _lot.size.x:
			if _has_floor(Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	for cell in cells:
		var origin := Vector2(cell) * cs
		if not _has_floor(cell + Vector2i.DOWN):
			_piece("dalle_ombre_s", origin + Vector2(3, 40))
		if not _has_floor(cell + Vector2i.RIGHT):
			_piece("dalle_ombre_e", origin + Vector2(40, 3))
	for cell in cells:
		var rect := Rect2(Vector2(cell) * cs, Vector2(cs, cs))
		var floor_definition := _lot.floor_at(cell, _level)
		if floor_definition.texture != null:
			draw_texture_rect(floor_definition.texture, rect, false)
		else:
			draw_rect(rect, Palette.PISTE)
	for cell in cells:
		var origin := Vector2(cell) * cs
		var south := not _has_floor(cell + Vector2i.DOWN)
		var west := not _has_floor(cell + Vector2i.LEFT)
		var east := not _has_floor(cell + Vector2i.RIGHT)
		if south:
			_piece("dalle_bord_s", origin + Vector2(0, 32))
		if not _has_floor(cell + Vector2i.UP):
			_piece("dalle_bord_n", origin + Vector2(0, -1))
		if west:
			_piece("dalle_bord_o", origin + Vector2(-8, 0))
		if east:
			_piece("dalle_bord_e", origin + Vector2(32, 0))
		if south and west and not _has_floor(cell + Vector2i(-1, 1)):
			_piece("dalle_angle_sortant_so", origin + Vector2(-8, 32))
		if south and east and not _has_floor(cell + Vector2i(1, 1)):
			_piece("dalle_angle_sortant_se", origin + Vector2(32, 32))
	for y in _lot.size.y:
		for x in _lot.size.x:
			var cell := Vector2i(x, y)
			if _has_floor(cell) or not _has_floor(cell + Vector2i.UP):
				continue
			var origin := Vector2(cell) * cs
			if _has_floor(cell + Vector2i.LEFT):
				_piece("dalle_angle_rentrant_no", origin)
			if _has_floor(cell + Vector2i.RIGHT):
				_piece("dalle_angle_rentrant_ne", origin + Vector2(24, 0))


func _has_floor(cell: Vector2i) -> bool:
	return _lot.contains(cell) and _lot.floor_at(cell, _level) != null


func _piece(file: String, top_left: Vector2) -> void:
	var texture := WallView._texture(EDGE_PATH % file)
	if texture != null:
		draw_texture(texture, top_left)
