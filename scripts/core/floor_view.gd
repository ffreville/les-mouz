class_name FloorView
extends Node2D
## Dessine le sol : herbe sombre et haie autour du terrain, puis le revêtement de chaque case.
## Calque du dessous : les objets et les murs sont dessinés par-dessus.

## Marge d'herbe dessinée autour du terrain, en pixels.
const OUTSIDE_MARGIN := 1200.0
const HEDGE_WIDTH := 10.0

## Couleur et épaisseur de la tranche d'un plancher d'étage au-dessus du vide (provisoire,
## en attendant les dessins du brief n° 7).
const SLAB := Color("#CDBFAA")
const SLAB_DEPTH := 8.0

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


## Étage : seulement les cases qui ont un sol, et la tranche du plancher là où il s'arrête.
func _draw_upper() -> void:
	var cs := float(_lot.cell_size)
	for y in _lot.size.y:
		for x in _lot.size.x:
			var cell := Vector2i(x, y)
			var floor_definition := _lot.floor_at(cell, _level)
			if floor_definition == null:
				continue
			var rect := Rect2(Vector2(cell) * cs, Vector2(cs, cs))
			if floor_definition.texture != null:
				draw_texture_rect(floor_definition.texture, rect, false)
			else:
				draw_rect(rect, Palette.PISTE)
			if _lot.floor_at(cell + Vector2i.DOWN, _level) == null:
				var slab := Rect2(rect.position.x, rect.end.y, cs, SLAB_DEPTH)
				draw_rect(slab, SLAB)
				draw_line(slab.position + Vector2(0, SLAB_DEPTH), slab.end, Palette.CONTOUR, 1.5)
			for side in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
				if _lot.floor_at(cell + side, _level) == null:
					var a := rect.position + (Vector2(cs, 0) if side == Vector2i.RIGHT else Vector2.ZERO)
					var b := a + (Vector2(cs, 0) if side == Vector2i.UP else Vector2(0, cs))
					draw_line(a, b, Palette.CONTOUR, 1.5)
