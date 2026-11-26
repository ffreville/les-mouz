class_name PoolView
extends Node2D
## La piscine (rez-de-chaussée), dessinée par Claude Design (brief n° 8) : l'eau en tuiles de 32 × 32
## sur 3 images qui bouclent, la rangée sous la margelle nord où l'on voit la paroi descendre, et la
## margelle de pierre posée dans les cases autour de l'eau (bords, coins sortants, angles rentrants).

## Couleurs gardées pour les aperçus (plan du quartier, outil Piscine).
const WATER := Color("#7CC6E0")
const RIPPLE := Color("#BFE6F2")
## Rythme des reflets (secondes réelles par image).
const FRAME_TIME := 0.32
const FLOORS := "res://assets/floors/%s.svg"
const MURS := "res://assets/murs/%s.svg"

var _lot: Lot
var _frame := 0
var _time := 0.0
var _water: Array[Texture2D] = []
var _edge: Array[Texture2D] = []


func _ready() -> void:
	for i in range(1, 4):
		_water.append(load(FLOORS % "piscine_eau_%d" % i))
		_edge.append(load(FLOORS % "piscine_eau_bord_%d" % i))
	for piece in ["n", "s", "o", "e", "coin_no", "coin_ne", "coin_so", "coin_se", "rentrant"]:
		MouzLayers.texture(MURS % ("margelle_" + piece))


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
	if _lot == null or _lot.pool.is_empty() or _water.is_empty():
		return
	var cs := float(_lot.cell_size)
	for cell in _lot.pool:
		var texture := _water[_frame] if _lot.pool.has(cell + Vector2i.UP) else _edge[_frame]
		draw_texture_rect(texture, Rect2(Vector2(cell) * cs, Vector2(cs, cs)), false)
	# Margelle : côtés d'abord, puis les coins par-dessus.
	for cell in _lot.pool:
		var at := Vector2(cell) * cs
		var north := not _wet(cell + Vector2i.UP)
		var south := not _wet(cell + Vector2i.DOWN)
		var west := not _wet(cell + Vector2i.LEFT)
		var east := not _wet(cell + Vector2i.RIGHT)
		if north:
			_piece("margelle_n", at + Vector2(0, -8))
		if south:
			_piece("margelle_s", at + Vector2(0, 30))
		if west:
			_piece("margelle_o", at + Vector2(-8, -2))
		if east:
			_piece("margelle_e", at + Vector2(32, -2))
	for cell in _lot.pool:
		var at := Vector2(cell) * cs
		if not _wet(cell + Vector2i.UP) and not _wet(cell + Vector2i.LEFT):
			_piece("margelle_coin_no", at + Vector2(-8, -8))
		if not _wet(cell + Vector2i.UP) and not _wet(cell + Vector2i.RIGHT):
			_piece("margelle_coin_ne", at + Vector2(32, -8))
		if not _wet(cell + Vector2i.DOWN) and not _wet(cell + Vector2i.LEFT):
			_piece("margelle_coin_so", at + Vector2(-8, 30))
		if not _wet(cell + Vector2i.DOWN) and not _wet(cell + Vector2i.RIGHT):
			_piece("margelle_coin_se", at + Vector2(32, 30))
	# Angles rentrants : une case de terre qui a de l'eau sur deux côtés qui se touchent.
	var land := {}
	for cell in _lot.pool:
		for step in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			if not _wet(cell + step):
				land[cell + step] = true
	for cell in land:
		for dx in [-1, 1]:
			for dy in [-1, 1]:
				if _wet(cell + Vector2i(dx, 0)) and _wet(cell + Vector2i(0, dy)):
					var corner := Vector2(24.0 if dx > 0 else 0.0, 24.0 if dy > 0 else 0.0)
					_piece("margelle_rentrant", Vector2(cell) * cs + corner)


func _wet(cell: Vector2i) -> bool:
	return _lot.pool.has(cell)


func _piece(name: String, at: Vector2) -> void:
	var texture := MouzLayers.texture(MURS % name)
	if texture != null:
		draw_texture(texture, at)
