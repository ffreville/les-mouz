class_name FloorView
extends Node2D
## Dessine le sol : herbe sombre et haie autour du terrain, puis le revêtement de chaque case.
## Calque du dessous : les objets et les murs sont dessinés par-dessus.

## Marge d'herbe dessinée autour du terrain, en pixels.
const OUTSIDE_MARGIN := 1200.0
const HEDGE_WIDTH := 10.0

var _lot: Lot


func render(lot: Lot) -> void:
	_lot = lot
	queue_redraw()


func _draw() -> void:
	if _lot == null:
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
