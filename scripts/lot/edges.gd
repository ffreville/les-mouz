class_name Edges
extends RefCounted
## Outils pour les arêtes de la grille, là où se posent les murs.
## Une arête est un Vector3i(x, y, orientation) :
##  - HORIZONTAL : segment du point (x, y) au point (x + 1, y), en haut de la case (x, y) ;
##  - VERTICAL : segment du point (x, y) au point (x, y + 1), à gauche de la case (x, y).

const HORIZONTAL := 0
const VERTICAL := 1


## Arête qui sépare deux cases voisines (horizontalement ou verticalement).
static func between(a: Vector2i, b: Vector2i) -> Vector3i:
	var d := b - a
	if d == Vector2i.RIGHT:
		return Vector3i(b.x, b.y, VERTICAL)
	if d == Vector2i.LEFT:
		return Vector3i(a.x, a.y, VERTICAL)
	if d == Vector2i.DOWN:
		return Vector3i(b.x, b.y, HORIZONTAL)
	return Vector3i(a.x, a.y, HORIZONTAL)


## Les deux cases de part et d'autre d'une arête : [avant, après] (haut/bas ou gauche/droite).
static func sides(edge: Vector3i) -> Array[Vector2i]:
	var cell := Vector2i(edge.x, edge.y)
	if edge.z == HORIZONTAL:
		return [cell + Vector2i.UP, cell]
	return [cell + Vector2i.LEFT, cell]


## Arête suivante dans le sens de l'arête (pour les ouvertures larges).
static func next_along(edge: Vector3i, steps: int = 1) -> Vector3i:
	if edge.z == HORIZONTAL:
		return Vector3i(edge.x + steps, edge.y, edge.z)
	return Vector3i(edge.x, edge.y + steps, edge.z)


## Arêtes d'une ligne droite entre deux points de la grille.
## La ligne suit l'axe dominant : on ne trace que des murs droits.
static func line(from_point: Vector2i, to_point: Vector2i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var d := to_point - from_point
	if absi(d.x) >= absi(d.y):
		for x in range(mini(from_point.x, to_point.x), maxi(from_point.x, to_point.x)):
			result.append(Vector3i(x, from_point.y, HORIZONTAL))
	else:
		for y in range(mini(from_point.y, to_point.y), maxi(from_point.y, to_point.y)):
			result.append(Vector3i(from_point.x, y, VERTICAL))
	return result


## Point d'arrivée réel d'une ligne (ramené sur l'axe dominant).
static func snap_line_end(from_point: Vector2i, to_point: Vector2i) -> Vector2i:
	var d := to_point - from_point
	if absi(d.x) >= absi(d.y):
		return Vector2i(to_point.x, from_point.y)
	return Vector2i(from_point.x, to_point.y)


## Rectangle d'une arête en pixels, épaissi de `thickness` et prolongé de `extend` à chaque bout.
static func to_rect(edge: Vector3i, cell_size: float, thickness: float, extend: float = 0.0) -> Rect2:
	var origin := Vector2(edge.x, edge.y) * cell_size
	if edge.z == HORIZONTAL:
		return Rect2(origin.x - extend, origin.y - thickness / 2, cell_size + extend * 2, thickness)
	return Rect2(origin.x - thickness / 2, origin.y - extend, thickness, cell_size + extend * 2)


## Arête la plus proche d'une position (monde).
static func nearest(world_position: Vector2, cell_size: float) -> Vector3i:
	var p := world_position / cell_size
	var cell := Vector2i(p.floor())
	var f := p - Vector2(cell)
	# Distance aux quatre côtés de la case.
	var candidates := {
		Vector3i(cell.x, cell.y, HORIZONTAL): f.y,
		Vector3i(cell.x, cell.y + 1, HORIZONTAL): 1.0 - f.y,
		Vector3i(cell.x, cell.y, VERTICAL): f.x,
		Vector3i(cell.x + 1, cell.y, VERTICAL): 1.0 - f.x,
	}
	var best: Vector3i = candidates.keys()[0]
	for edge in candidates:
		if candidates[edge] < candidates[best]:
			best = edge
	return best


## Point de la grille le plus proche d'une position (monde).
static func nearest_point(world_position: Vector2, cell_size: float) -> Vector2i:
	return Vector2i((world_position / cell_size).round())
