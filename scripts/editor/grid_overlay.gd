class_name GridOverlay
extends Node2D
## Grille du terrain affichée en mode Construire : traits fins et bord du terrain en tirets.

const LINE_COLOR := Color(0.169, 0.141, 0.251, 0.10)
const BORDER_COLOR := Color(0.239, 0.2, 0.341, 0.5)

## À l'étage, sur le vide : où l'on peut poser un plancher, et où l'on ne peut pas (brief n° 7).
const CAN_BUILD := preload("res://assets/floors/vide_constructible.svg")
const CANNOT_BUILD := preload("res://assets/floors/vide_interdit.svg")

var _lot: Lot
var _level := 0


func _ready() -> void:
	GameMode.mode_changed.connect(func(mode: int) -> void: visible = mode == GameMode.Mode.BUILD)
	visible = GameMode.mode == GameMode.Mode.BUILD


func render(lot: Lot) -> void:
	_lot = lot
	queue_redraw()


func show_level(level: int) -> void:
	_level = level
	queue_redraw()


func _draw() -> void:
	if _lot == null:
		return
	var cs := float(_lot.cell_size)
	var end := Vector2(_lot.size) * cs
	if _level > 0:
		_draw_upper_hints(cs)
	for x in range(1, _lot.size.x):
		draw_line(Vector2(x * cs, 0), Vector2(x * cs, end.y), LINE_COLOR, 1.0)
	for y in range(1, _lot.size.y):
		draw_line(Vector2(0, y * cs), Vector2(end.x, y * cs), LINE_COLOR, 1.0)
	var corners := [Vector2.ZERO, Vector2(end.x, 0), end, Vector2(0, end.y), Vector2.ZERO]
	for i in 4:
		draw_dashed_line(corners[i], corners[i + 1], BORDER_COLOR, 2.0, 8.0)


func _draw_upper_hints(cs: float) -> void:
	var below := _lot.interior_cells(_level - 1)
	for y in _lot.size.y:
		for x in _lot.size.x:
			var cell := Vector2i(x, y)
			if _lot.floor_at(cell, _level) != null:
				continue
			var can := below.has(cell) and not _lot.is_stairwell(cell, _level)
			draw_texture(CAN_BUILD if can else CANNOT_BUILD, Vector2(cell) * cs)
