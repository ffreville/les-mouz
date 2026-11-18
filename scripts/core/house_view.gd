class_name HouseView
extends Node2D
## Dessine la maison (sols, murs, portes, noms des pièces) à partir d'un HouseLayout.
## Graphismes provisoires : uniquement des rectangles de couleur.

const ROOM_LABEL_COLOR := Color(0, 0, 0, 0.35)
const ROOM_LABEL_SIZE := 18

var _layout: HouseLayout


func render(layout: HouseLayout) -> void:
	_layout = layout
	queue_redraw()


func _draw() -> void:
	if _layout == null:
		return
	var cs := float(_layout.cell_size)
	var font := ThemeDB.fallback_font

	# Sols et noms des pièces.
	for room in _layout.rooms:
		var area := Rect2(Vector2(room.rect.position) * cs, Vector2(room.rect.size) * cs)
		draw_rect(area, room.floor_color)
		var text_pos := area.position + Vector2(8, ROOM_LABEL_SIZE + 4)
		draw_string(font, text_pos, room.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1,
				ROOM_LABEL_SIZE, ROOM_LABEL_COLOR)

	# Murs et portes, case par case.
	for y in _layout.grid_size.y:
		for x in _layout.grid_size.x:
			var cell := Vector2i(x, y)
			var area := Rect2(Vector2(cell) * cs, Vector2(cs, cs))
			if _layout.is_wall(cell):
				draw_rect(area, _layout.wall_color)
			elif cell in _layout.doors:
				draw_rect(area, _layout.door_color)
