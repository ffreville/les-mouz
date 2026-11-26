class_name PoolView
extends Node2D
## La piscine (rez-de-chaussée) : l'eau, qui ondule, la paroi qu'on voit sous le bord nord et la
## margelle tout autour. Dessin provisoire en aplats, en attendant le brief n° 8.

const WATER := Color("#7CC6E0")
const WATER_DEEP := Color("#5FB0CF")
const RIPPLE := Color("#BFE6F2")
const WALL := Color("#4A9CBF")
const COPING := Color("#E8DFD0")
const COPING_EDGE := Color("#C9BCA6")
## Profondeur visible de la paroi nord, et largeur de la margelle.
const WALL_DEPTH := 12.0
const COPING_WIDTH := 5.0
## Rythme des reflets (secondes réelles par image).
const FRAME_TIME := 0.35

var _lot: Lot
var _frame := 0
var _time := 0.0


func render(lot: Lot) -> void:
	_lot = lot
	queue_redraw()


func _process(delta: float) -> void:
	if _lot == null or _lot.pool.is_empty():
		return
	_time += delta
	if _time >= FRAME_TIME:
		_time = 0.0
		_frame = (_frame + 1) % 3
		queue_redraw()


func _draw() -> void:
	if _lot == null or _lot.pool.is_empty():
		return
	var cs := float(_lot.cell_size)
	for cell in _lot.pool:
		var rect := Rect2(Vector2(cell) * cs, Vector2(cs, cs))
		draw_rect(rect, WATER)
		# Reflets : de petits traits qui se décalent d'une image à l'autre.
		for k in 2:
			var x := rect.position.x + fposmod(7.0 + k * 15.0 + _frame * 4.0 + cell.y * 5.0, cs - 8.0)
			var y := rect.position.y + 9.0 + k * 13.0
			draw_line(Vector2(x, y), Vector2(x + 7, y), RIPPLE, 2.0)
		if not _lot.pool.has(cell + Vector2i.UP):
			draw_rect(Rect2(rect.position, Vector2(cs, WALL_DEPTH)), WALL)
			draw_rect(Rect2(rect.position + Vector2(0, WALL_DEPTH), Vector2(cs, 3)), WATER_DEEP)
	# Margelle : une bordure de pierre sur la case voisine, tout autour du bassin.
	for cell in _lot.pool:
		var origin := Vector2(cell) * cs
		if not _lot.pool.has(cell + Vector2i.UP):
			_coping(Rect2(origin + Vector2(-COPING_WIDTH, -COPING_WIDTH), Vector2(cs + 2 * COPING_WIDTH, COPING_WIDTH)))
		if not _lot.pool.has(cell + Vector2i.DOWN):
			_coping(Rect2(origin + Vector2(-COPING_WIDTH, cs), Vector2(cs + 2 * COPING_WIDTH, COPING_WIDTH)))
		if not _lot.pool.has(cell + Vector2i.LEFT):
			_coping(Rect2(origin + Vector2(-COPING_WIDTH, 0), Vector2(COPING_WIDTH, cs)))
		if not _lot.pool.has(cell + Vector2i.RIGHT):
			_coping(Rect2(origin + Vector2(cs, 0), Vector2(COPING_WIDTH, cs)))


func _coping(rect: Rect2) -> void:
	draw_rect(rect, COPING)
	draw_rect(rect, COPING_EDGE, false, 1.0)
