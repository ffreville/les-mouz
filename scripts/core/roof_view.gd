class_name RoofView
extends Node2D
## Le toit d'un niveau, calculé tout seul : un toit à quatre pans (en croupe) sur chaque pièce fermée
## qui n'a pas de plancher au-dessus. Chaque case monte selon sa distance au bord de la pièce (PITCH :
## 16 px par case, pour que le pan nord, vu du dessus, reste visible), au-dessus des murs pleins.
## Chaque pan est rempli du motif de son orientation (brief n° 8), plaqué avec les coordonnées au sol :
## la projection l'étire toute seule. Par-dessus : arêtiers et noues (trait encre), faîtage (bande
## dessinée), gouttière sous les égouts sud, solin au pied d'un mur d'étage et cheminée au-dessus de
## l'objet cheminée. Visible en mode Vivre avec le réglage « Toits » (touche V).

## Hauteur des murs pleins : le toit commence là.
const WALL_HEIGHT := 64.0
## Montée du toit par case vers l'intérieur, en fraction de case.
const PITCH := 0.5
const GUTTER := 4.0
const OUTLINE_WIDTH := 2.0
const HIP_WIDTH := 1.5
## Faîtage : trait encre, puis la couleur du faîtage par-dessus (quand il n'est pas horizontal).
const RIDGE_INK := 7.0
const RIDGE_FILL := 4.5
const RIDGE_HEIGHT := 9.0
const SOLIN := "res://assets/toits/toit_solin.svg"
const CHIMNEY := "res://assets/sprites/cheminee_toit_%s.svg"
## Point de la cheminée posé sur le toit, au centre de sa case (tokens.json).
const CHIMNEY_ANCHOR := {&"nature": Vector2(16, 50), &"retro": Vector2(16, 56), &"moderne": Vector2(16, 49)}
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
## Motifs du style en cours, par orientation (Facing → texture ou null).
var _patterns: Dictionary = {}
## Faîtages à tracer après tous les pans : [a, b] à l'écran.
var _ridges: Array = []


## Bande du faîtage et gouttière du style en cours. Toutes les textures sont chargées avant le
## dessin : chargée pendant `_draw`, une texture sort blanche à son premier affichage.
var _ridge: Texture2D
var _gutter: Texture2D
var _solin: Texture2D
var _chimneys: Dictionary = {}


func _init() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func render(lot: Lot, level: int, top_visible: int) -> void:
	_lot = lot
	_level = level
	_top_visible = top_visible
	_patterns.clear()
	if lot.roof != null:
		var style: RoofDefinition = lot.roof.definition
		_patterns = {Facing.SOUTH: style.pattern("sud"), Facing.NORTH: style.pattern("nord"),
				Facing.TOP: style.pattern("nord"), Facing.EAST: style.pattern("est"), Facing.WEST: style.pattern("ouest")}
		_ridge = style.pattern("faitage")
		_gutter = style.pattern("gouttiere")
	if _solin == null and ResourceLoader.exists(SOLIN):
		_solin = load(SOLIN)
	for collection in CHIMNEY_ANCHOR:
		if not _chimneys.has(collection) and ResourceLoader.exists(CHIMNEY % collection):
			_chimneys[collection] = load(CHIMNEY % collection)
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
	_draw_gutters(ordered, style)
	_facings.clear()
	_ridges.clear()
	for cell in ordered:
		_draw_cell(cell, style)
	for cell in ordered:
		_draw_ridges(cell, style)
		_draw_outline(cell)
	for segment in _merged_ridges():
		_draw_ridge(segment[0], segment[1], style, _ridge)
	_draw_chimneys()


## Gouttière sous les égouts sud (le chaume n'en a pas : un bord épais à la place).
func _draw_gutters(ordered: Array, style: RoofDefinition) -> void:
	var gutter := _gutter
	var cs := float(_lot.cell_size)
	for cell in ordered:
		if _cells.has(cell + Vector2i.DOWN):
			continue
		var a := _screen(cell.x, cell.y + 1, 0)
		if gutter != null:
			draw_texture_rect(gutter, Rect2(a + Vector2(0, -1), Vector2(cs, gutter.get_height())), false)
		else:
			draw_line(a + Vector2(0, 1), a + Vector2(cs, 1), style.line_color, 3.0)
			draw_line(a + Vector2(0, 3), a + Vector2(cs, 3), Palette.CONTOUR, OUTLINE_WIDTH)


## Faîtages bout à bout réunis : les morceaux alignés (horizontaux ou verticaux à l'écran) qui se
## touchent ne font qu'un, pour que la bande du faîtage se répète d'un seul tenant. Un morceau vertical
## isolé, plus court qu'une case, n'est qu'un pli du dessus plat : il n'est pas tracé.
func _merged_ridges() -> Array:
	var horizontal: Array = []
	var vertical: Array = []
	for segment in _ridges:
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		if absf(a.y - b.y) < 0.5:
			horizontal.append([Vector2(minf(a.x, b.x), a.y), Vector2(maxf(a.x, b.x), a.y)])
		elif absf(a.x - b.x) < 0.5:
			vertical.append([Vector2(a.x, minf(a.y, b.y)), Vector2(a.x, maxf(a.y, b.y))])
	var merged := _merge(horizontal, 0)
	for segment in _merge(vertical, 1):
		if segment[1].y - segment[0].y >= _lot.cell_size * 0.75:
			merged.append(segment)
	return merged


## Réunit des morceaux alignés sur l'axe `axis` (0 : x, 1 : y), déjà rangés du plus petit au plus grand.
func _merge(segments: Array, axis: int) -> Array:
	var other := 1 - axis
	segments.sort_custom(func(p: Array, q: Array) -> bool:
		return p[0][other] < q[0][other] - 0.5 or absf(p[0][other] - q[0][other]) < 0.5 and p[0][axis] < q[0][axis])
	var merged: Array = []
	for segment in segments:
		if not merged.is_empty():
			var last: Array = merged[-1]
			if absf(last[1][other] - segment[0][other]) < 0.5 and segment[0][axis] <= last[1][axis] + 0.5:
				var end: Vector2 = last[1]
				end[axis] = maxf(end[axis], segment[1][axis])
				last[1] = end
				continue
		merged.append([segment[0], segment[1]])
	return merged


## Faîtage horizontal : la bande dessinée, répétée ; sinon (faîtage nord-sud), trait encre et couleur.
func _draw_ridge(a: Vector2, b: Vector2, style: RoofDefinition, ridge: Texture2D) -> void:
	if ridge != null and absf(a.y - b.y) < 0.5:
		# Bande répétée à la main, morceau par morceau (sans répétition de texture).
		var width := float(ridge.get_width())
		var x := a.x
		while x < b.x - 0.01:
			var piece := minf(width, b.x - x)
			draw_texture_rect_region(ridge, Rect2(x, a.y - RIDGE_HEIGHT / 2.0, piece, RIDGE_HEIGHT),
					Rect2(0, 0, piece, ridge.get_height()))
			x += piece
		return
	draw_line(a, b, Palette.CONTOUR, RIDGE_INK)
	draw_line(a, b, style.ridge_color, RIDGE_FILL)


## Cheminée qui sort du toit au-dessus de l'objet cheminée de ce niveau.
func _draw_chimneys() -> void:
	for placed in _lot.level(_level).objects:
		if placed.definition.id != &"cheminee":
			continue
		var footprint: Rect2i = placed.footprint()
		var cell := footprint.position + footprint.size / 2
		if not _cells.has(cell):
			continue
		var collection: StringName = placed.get_collection()
		var texture: Texture2D = _chimneys.get(collection)
		if texture == null:
			continue
		var anchor: Vector2 = CHIMNEY_ANCHOR.get(collection, Vector2(16, 50))
		draw_texture(texture, _screen(cell.x + 0.5, cell.y + 0.5, _center_height(cell)) - anchor)


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
	var uvs: Array = []
	for i in 8:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 8]
		facings.append(_facing(center, a, b))
		polygons.append(PackedVector2Array([_screen(center.x, center.y, center.z), _screen(a.x, a.y, a.z), _screen(b.x, b.y, b.z)]))
		uvs.append(PackedVector2Array([Vector2(center.x, center.y), Vector2(a.x, a.y), Vector2(b.x, b.y)]))
	_facings[cell] = facings
	# Du fond vers l'avant : les triangles du haut de la case d'abord.
	var order := [0, 1, 7, 2, 6, 3, 5, 4]
	for i in order:
		var pattern: Texture2D = _patterns.get(facings[i])
		if pattern != null:
			draw_polygon(polygons[i], PackedColorArray([Color.WHITE]), uvs[i], pattern)
		else:
			draw_colored_polygon(polygons[i], _color(style, facings[i]))
	# Arêtiers et faîtages à l'intérieur de la case : entre deux triangles qui ne regardent pas du même côté.
	for i in 8:
		if facings[i] != facings[(i + 7) % 8]:
			var p: Vector3 = ring[i]
			_crease(center, p)


## Hauteur du centre d'une case : sa distance au bord de la pièce, moins une demi-case.
func _center_height(cell: Vector2i) -> float:
	return float(_cell_height[cell]) - 0.5


## Point du milieu d'un côté : au bord de la pièce, à 0 ; sinon le plus haut de deux estimations, la
## moyenne des deux centres (faîtage sur une rangée de cases) et la moyenne des deux coins du côté
## (faîtage sur la ligne entre deux rangées, pièce de largeur paire). Le faîtage reste droit.
func _middle(cell: Vector2i, side: Vector2i) -> Vector3:
	var point := Vector2(cell) + Vector2(0.5, 0.5) + Vector2(side) * 0.5
	var height := 0.0
	if _cells.has(cell + side):
		var along := Vector2i(absi(side.y), absi(side.x))
		var a := Vector2(point) - Vector2(along) * 0.5
		var b := Vector2(point) + Vector2(along) * 0.5
		var nodes := (_corner(Vector2i(roundi(a.x), roundi(a.y))).z + _corner(Vector2i(roundi(b.x), roundi(b.y))).z) / 2.0
		height = maxf((_center_height(cell) + _center_height(cell + side)) / 2.0, nodes)
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


func _ridge_segment(differs: bool, a: Vector3, b: Vector3, _style: RoofDefinition) -> void:
	if differs:
		_crease(a, b)


## Pli entre deux pans : à hauteur constante, c'est un faîtage (tracé à la fin, par-dessus) ;
## sinon un arêtier ou une noue, en trait encre.
func _crease(a: Vector3, b: Vector3) -> void:
	var from := _screen(a.x, a.y, a.z)
	var to := _screen(b.x, b.y, b.z)
	if absf(a.z - b.z) < 0.01 and a.z > 0.0:
		_ridges.append([from, to])
	else:
		draw_line(from, to, Palette.CONTOUR, HIP_WIDTH)


## Le contour du toit : les côtés de case qui donnent sur l'extérieur.
func _draw_outline(cell: Vector2i) -> void:
	var sides := [[Vector2i.UP, Vector2i(0, 0), Vector2i(1, 0)], [Vector2i.DOWN, Vector2i(0, 1), Vector2i(1, 1)],
			[Vector2i.LEFT, Vector2i(0, 0), Vector2i(0, 1)], [Vector2i.RIGHT, Vector2i(1, 0), Vector2i(1, 1)]]
	for side in sides:
		if _cells.has(cell + side[0]):
			continue
		var a := _corner(cell + side[1])
		var b := _corner(cell + side[2])
		var from := _screen(a.x, a.y, a.z)
		var to := _screen(b.x, b.y, b.z)
		if _lot.floor_at(cell + side[0], _level + 1) != null:
			_draw_solin(from, to)
		else:
			draw_line(from, to, Palette.CONTOUR, OUTLINE_WIDTH)


## Solin : bande de zinc au pied d'un mur d'étage qui dépasse du toit.
func _draw_solin(from: Vector2, to: Vector2) -> void:
	var texture := _solin
	if texture != null and absf(from.y - to.y) < 0.5:
		draw_texture_rect(texture, Rect2(Vector2(minf(from.x, to.x), from.y - texture.get_height()),
				Vector2(absf(to.x - from.x), texture.get_height())), true)
	else:
		draw_line(from, to, Color("#A9B4C2"), 4.0)
		draw_line(from, to, Palette.CONTOUR, 1.5)
