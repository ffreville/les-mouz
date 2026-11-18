class_name FloorView
extends Node2D
## Dessine le jardin autour de la maison et le sol de chaque pièce, avec son motif.
## Calque du dessous : les objets et les murs sont dessinés par-dessus.

## Marge de jardin dessinée autour de la maison, en pixels.
const GARDEN_MARGIN := 640.0
const GARDEN_DOT_SPACING := 24.0
const GARDEN_DOT_RADIUS := 2.0
const PATTERN_STEP := 16.0

var _layout: HouseLayout


func render(layout: HouseLayout) -> void:
	_layout = layout
	queue_redraw()


func _draw() -> void:
	if _layout == null:
		return
	_draw_garden()
	var cs := float(_layout.cell_size)
	for room in _layout.rooms:
		var area := Rect2(Vector2(room.rect.position) * cs, Vector2(room.rect.size) * cs)
		draw_rect(area, room.floor_color)
		_draw_pattern(area, room.pattern, room.pattern_color)


func _draw_garden() -> void:
	var house := Vector2(_layout.grid_size * _layout.cell_size)
	var area := Rect2(-Vector2.ONE * GARDEN_MARGIN, house + Vector2.ONE * GARDEN_MARGIN * 2)
	draw_rect(area, Palette.JARDIN)
	var y := area.position.y
	while y < area.end.y:
		var x := area.position.x
		while x < area.end.x:
			draw_circle(Vector2(x, y), GARDEN_DOT_RADIUS, Palette.JARDIN_POINT)
			x += GARDEN_DOT_SPACING
		y += GARDEN_DOT_SPACING


func _draw_pattern(area: Rect2, pattern: RoomDefinition.FloorPattern, color: Color) -> void:
	match pattern:
		RoomDefinition.FloorPattern.PLANKS:
			for y in _steps(area.position.y, area.end.y, PATTERN_STEP):
				draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), color, 1.0)
		RoomDefinition.FloorPattern.GRID:
			for y in _steps(area.position.y, area.end.y, PATTERN_STEP):
				draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), color, 1.0)
			for x in _steps(area.position.x, area.end.x, PATTERN_STEP):
				draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), color, 1.0)
		RoomDefinition.FloorPattern.DOTS:
			for y in _steps(area.position.y, area.end.y, PATTERN_STEP):
				for x in _steps(area.position.x, area.end.x, PATTERN_STEP):
					draw_circle(Vector2(x, y) + Vector2.ONE * PATTERN_STEP / 2, 1.5, color)
		RoomDefinition.FloorPattern.CHECKER:
			var cs := float(_layout.cell_size)
			for y in _steps(area.position.y, area.end.y, cs):
				for x in _steps(area.position.x, area.end.x, cs):
					if (int(x / cs) + int(y / cs)) % 2 == 1:
						draw_rect(Rect2(x, y, cs, cs), color)


## Valeurs de `from` (exclu) à `to` (exclu), tous les `step`.
func _steps(from: float, to: float, step: float) -> Array[float]:
	var result: Array[float] = []
	var value := from + step
	while value < to:
		result.append(value)
		value += step
	return result
