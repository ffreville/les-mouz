class_name RoofView
extends Node2D
## Le toit d'un niveau, calculé tout seul : un toit à quatre pans (en croupe) sur chaque pièce fermée
## qui n'a pas de plancher au-dessus. Chaque case monte selon sa distance au bord de la pièce (PITCH :
## 16 px par case, pour que le pan nord, vu du dessus, reste visible), au-dessus des murs pleins. Dessiné en aplats (provisoire, brief n° 8) : pan sud
## en face, pan nord vu du dessus, pans ouest éclairé et est à l'ombre, rangs du matériau, arêtiers,
## faîtage et gouttière. Visible en mode Vivre avec le réglage « Toits » (touche V).

## Hauteur des murs pleins : le toit commence là.
const WALL_HEIGHT := 64.0
## Montée du toit par case vers l'intérieur, en fraction de case.
const PITCH := 0.5
const GUTTER := 4.0
const OUTLINE_WIDTH := 2.0
const HIP_WIDTH := 1.5
## En dessous de cette pente (hauteur par case), un triangle est un dessus plat.
const FLAT := 0.05

enum Facing { TOP, SOUTH, NORTH, EAST, WEST }

var _lot: Lot
var _level := 0
var _top_visible := 0
var _cells: Dictionary = {}
var _cell_height: Dictionary = {}
var _node_height: Dictionary = {}
## Orientation des 4 triangles de chaque case (nord, ouest, est, sud), pour tracer les faîtages.
var _facings: Dictionary = {}


func render(lot: Lot, level: int, top_visible: int) -> void:
	_lot = lot
	_level = level
	_top_visible = top_visible
	_compute()
	queue_redraw()


func _compute() -> void:
	_cells = _lot.roof_cells(_level, _top_visible) if _lot.roof != null else {}
	_cell_height.clear()
	_node_height.clear()
	if _cells.is_empty():
		return
	# Distance de chaque case au bord de sa pièce (1 pour les cases du bord), sur 8 voisins.
	var todo: Array[Vector2i] = []
	for cell in _cells:
		if _touches_outside(cell):
			_cell_height[cell] = 1
			todo.append(cell)
	var index := 0
	while index < todo.size():
		var cell := todo[index]
		index += 1
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var next := cell + Vector2i(dx, dy)
				if _cells.has(next) and not _cell_height.has(next):
					_cell_height[next] = _cell_height[cell] + 1
					todo.append(next)
	# Hauteur de chaque coin : 0 au bord de la pièce, puis un de plus par pas vers l'intérieur.
	var nodes: Array[Vector2i] = []
	var all_nodes := {}
	for cell in _cells:
		for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			all_nodes[cell + corner] = true
	for node in all_nodes:
		if not _node_inside(node):
			_node_height[node] = 0
			nodes.append(node)
	index = 0
	while index < nodes.size():
		var node := nodes[index]
		index += 1
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var next := node + Vector2i(dx, dy)
				if all_nodes.has(next) and not _node_height.has(next):
					_node_height[next] = _node_height[node] + 1
					nodes.append(next)


func _touches_outside(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if not _cells.has(cell + Vector2i(dx, dy)):
				return true
	return false


## Un coin est à l'intérieur du toit si les 4 cases autour sont couvertes.
func _node_inside(node: Vector2i) -> bool:
	for corner in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
		if not _cells.has(node + corner):
			return false
	return true


## Un point du toit (en cases, hauteur en cases) à l'écran.
func _screen(x: float, y: float, h: float) -> Vector2:
	var cs := float(_lot.cell_size)
	return Vector2(x * cs, y * cs - WALL_HEIGHT - h * cs * PITCH)


func _draw() -> void:
	if _lot == null or _lot.roof == null or _cells.is_empty():
		return
	var style: RoofDefinition = _lot.roof.definition
	var ordered: Array = _cells.keys()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or a.y == b.y and a.x < b.x)
	# Gouttières sous les bords sud, puis les pans, case par case, du fond vers l'avant.
	for cell in ordered:
		if not _cells.has(cell + Vector2i.DOWN):
			var a := _screen(cell.x, cell.y + 1, 0)
			draw_rect(Rect2(a, Vector2(_lot.cell_size, GUTTER)), style.dark_color)
			draw_line(a + Vector2(0, GUTTER), a + Vector2(_lot.cell_size, GUTTER), Palette.CONTOUR, OUTLINE_WIDTH)
	_facings.clear()
	for cell in ordered:
		_draw_cell(cell, style)
	for cell in ordered:
		_draw_ridges(cell, style)
		_draw_outline(cell)


## Une case : huit triangles en éventail autour de son centre, par ses coins et le milieu de ses côtés
## (le milieu d'un côté prend la moyenne des centres des deux cases, ce qui garde les faîtages droits).
## Ordre du tour : coin nord-ouest, milieu nord, coin nord-est, milieu est, coin sud-est, milieu sud,
## coin sud-ouest, milieu ouest.
func _draw_cell(cell: Vector2i, style: RoofDefinition) -> void:
	var center := Vector3(cell.x + 0.5, cell.y + 0.5, _center_height(cell))
	var ring := [
		_corner(cell), _middle(cell, Vector2i.UP), _corner(cell + Vector2i(1, 0)), _middle(cell, Vector2i.RIGHT),
		_corner(cell + Vector2i(1, 1)), _middle(cell, Vector2i.DOWN), _corner(cell + Vector2i(0, 1)), _middle(cell, Vector2i.LEFT),
	]
	var facings: Array[int] = []
	var polygons: Array = []
	for i in 8:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 8]
		facings.append(_facing(center, a, b))
		polygons.append(PackedVector2Array([_screen(center.x, center.y, center.z), _screen(a.x, a.y, a.z), _screen(b.x, b.y, b.z)]))
	_facings[cell] = facings
	# Du fond vers l'avant : les triangles du haut de la case d'abord.
	var order := [0, 1, 7, 2, 6, 3, 5, 4]
	for i in order:
		draw_colored_polygon(polygons[i], _color(style, facings[i]))
		if facings[i] == Facing.SOUTH:
			_draw_rows(polygons[i], style)
	# Arêtiers et faîtages à l'intérieur de la case : entre deux triangles qui ne regardent pas du même côté.
	for i in 8:
		if facings[i] != facings[(i + 7) % 8]:
			var p: Vector3 = ring[i]
			draw_line(_screen(center.x, center.y, center.z), _screen(p.x, p.y, p.z), style.line_color, HIP_WIDTH)


## Hauteur du centre d'une case : sa distance au bord de la pièce, moins une demi-case.
func _center_height(cell: Vector2i) -> float:
	return float(_cell_height[cell]) - 0.5


## Point du milieu d'un côté : au bord de la pièce, à 0 ; sinon la moyenne des deux centres.
func _middle(cell: Vector2i, side: Vector2i) -> Vector3:
	var point := Vector2(cell) + Vector2(0.5, 0.5) + Vector2(side) * 0.5
	var height := 0.0
	if _cells.has(cell + side):
		height = (_center_height(cell) + _center_height(cell + side)) / 2.0
	return Vector3(point.x, point.y, height)


func _corner(node: Vector2i) -> Vector3:
	return Vector3(node.x, node.y, float(_node_height.get(node, 0)))


## Côté vers lequel descend le triangle (centre, a, b).
func _facing(center: Vector3, a: Vector3, b: Vector3) -> int:
	var normal := (a - center).cross(b - center)
	if normal.z < 0:
		normal = -normal
	var slope := Vector2(normal.x, normal.y) / maxf(normal.z, 0.001)
	if slope.length() < FLAT:
		return Facing.TOP
	if absf(slope.y) >= absf(slope.x):
		return Facing.SOUTH if slope.y > 0 else Facing.NORTH
	return Facing.EAST if slope.x > 0 else Facing.WEST


func _color(style: RoofDefinition, facing: int) -> Color:
	match facing:
		Facing.SOUTH:
			return style.color
		Facing.NORTH, Facing.TOP:
			return style.top_color
		Facing.WEST:
			return style.light_color
	return style.dark_color


## Rangs du matériau sur un pan sud : des lignes horizontales coupées au triangle.
func _draw_rows(points: PackedVector2Array, style: RoofDefinition) -> void:
	var top := minf(points[0].y, minf(points[1].y, points[2].y))
	var bottom := maxf(points[0].y, maxf(points[1].y, points[2].y))
	var y := bottom - style.row_step
	while y > top + 1.0:
		var xs: Array[float] = []
		for i in 3:
			var p := points[i]
			var q := points[(i + 1) % 3]
			if (p.y - y) * (q.y - y) < 0.0:
				xs.append(lerpf(p.x, q.x, (y - p.y) / (q.y - p.y)))
		if xs.size() == 2:
			draw_line(Vector2(minf(xs[0], xs[1]), y), Vector2(maxf(xs[0], xs[1]), y), Color(style.line_color, 0.55), 1.0)
		y -= style.row_step


## Faîtages et noues qui tombent entre deux cases : les triangles de part et d'autre d'un côté
## ne regardent pas du même côté.
func _draw_ridges(cell: Vector2i, style: RoofDefinition) -> void:
	var mine: Array = _facings[cell]
	var below := cell + Vector2i.DOWN
	if _facings.has(below):
		var other: Array = _facings[below]
		_ridge_segment(mine[5] != other[0], _corner(cell + Vector2i(0, 1)), _middle(cell, Vector2i.DOWN), style)
		_ridge_segment(mine[4] != other[1], _middle(cell, Vector2i.DOWN), _corner(cell + Vector2i(1, 1)), style)
	var right := cell + Vector2i.RIGHT
	if _facings.has(right):
		var other: Array = _facings[right]
		_ridge_segment(mine[2] != other[7], _corner(cell + Vector2i(1, 0)), _middle(cell, Vector2i.RIGHT), style)
		_ridge_segment(mine[3] != other[6], _middle(cell, Vector2i.RIGHT), _corner(cell + Vector2i(1, 1)), style)


func _ridge_segment(differs: bool, a: Vector3, b: Vector3, style: RoofDefinition) -> void:
	if differs:
		draw_line(_screen(a.x, a.y, a.z), _screen(b.x, b.y, b.z), style.line_color, HIP_WIDTH)


## Le contour du toit : les côtés de case qui donnent sur l'extérieur.
func _draw_outline(cell: Vector2i) -> void:
	var sides := [[Vector2i.UP, Vector2i(0, 0), Vector2i(1, 0)], [Vector2i.DOWN, Vector2i(0, 1), Vector2i(1, 1)],
			[Vector2i.LEFT, Vector2i(0, 0), Vector2i(0, 1)], [Vector2i.RIGHT, Vector2i(1, 0), Vector2i(1, 1)]]
	for side in sides:
		if _cells.has(cell + side[0]):
			continue
		var a := _corner(cell + side[1])
		var b := _corner(cell + side[2])
		draw_line(_screen(a.x, a.y, a.z), _screen(b.x, b.y, b.z), Palette.CONTOUR, OUTLINE_WIDTH)
