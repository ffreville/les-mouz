class_name GridNavigation
extends Node
## Recherche de chemin sur la grille du terrain (AStar2D).
## Chaque case libre du terrain est un point ; deux cases voisines sont reliées
## si aucun mur ne les sépare. Les meubles rendent leurs cases inaccessibles.

const NO_CELL := Vector2i(-1, -1)
const ORTHOGONAL: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

var cell_size: int = 32
var _astar := AStar2D.new()
var _lot: Lot
var _blocked: Dictionary[Vector2i, bool] = {}


## Construit le graphe. `blocked_cells` : cases occupées par des meubles.
func setup(lot: Lot, blocked_cells: Array[Vector2i]) -> void:
	_lot = lot
	cell_size = lot.cell_size
	_astar.clear()
	_blocked.clear()
	for cell in blocked_cells:
		_blocked[cell] = true
	for y in lot.size.y:
		for x in lot.size.x:
			var cell := Vector2i(x, y)
			if is_walkable(cell):
				_astar.add_point(_id(cell), Vector2(cell))
	for y in lot.size.y:
		for x in lot.size.x:
			_connect_neighbors(Vector2i(x, y))


func is_walkable(cell: Vector2i) -> bool:
	return _lot.contains(cell) and not _blocked.has(cell)


## Centre d'une case, en coordonnées du monde.
func cell_to_world(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i((world_position / cell_size).floor())


## La case libre la plus proche de `cell` (elle-même si elle est libre).
func nearest_walkable(cell: Vector2i) -> Vector2i:
	if is_walkable(cell):
		return cell
	for radius in range(1, maxi(_lot.size.x, _lot.size.y)):
		for y in range(cell.y - radius, cell.y + radius + 1):
			for x in range(cell.x - radius, cell.x + radius + 1):
				if is_walkable(Vector2i(x, y)):
					return Vector2i(x, y)
	return cell


## Liste des cases de `from` à `to` (incluses). Vide si aucun chemin.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not is_walkable(from) or not is_walkable(to):
		return result
	for id in _astar.get_id_path(_id(from), _id(to)):
		result.append(_cell(id))
	return result


## Longueur du chemin en cases, ou INF si la case est inaccessible.
func path_length(from: Vector2i, to: Vector2i) -> float:
	if from == to:
		return 0.0
	var path := find_path(from, to)
	return INF if path.is_empty() else float(path.size() - 1)


## Parmi `candidates`, la case accessible la plus proche (en chemin) de `from`.
## Renvoie NO_CELL si aucune n'est accessible.
func closest_reachable(candidates: Array[Vector2i], from: Vector2i) -> Vector2i:
	var best := NO_CELL
	var best_length := INF
	for cell in candidates:
		var length := path_length(from, cell)
		if length < best_length:
			best_length = length
			best = cell
	return best


## Cases libres collées à un rectangle (côtés uniquement), sans mur entre elles et lui.
func cells_around(rect: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var inner := Vector2i(x, y)
			for direction in ORTHOGONAL:
				var outer := inner + direction
				if rect.has_point(outer) or outer in result:
					continue
				if is_walkable(outer) and not _lot.blocks_passage(inner, outer):
					result.append(outer)
	return result


## Cases où l'on peut se tenir pour être à côté de `cell` (sans mur entre les deux).
func cells_next_to(cell: Vector2i) -> Array[Vector2i]:
	return cells_around(Rect2i(cell, Vector2i.ONE))


## Vrai si l'on peut aller directement de `a` à `b` en un pas (voisins sans mur).
func are_neighbors(a: Vector2i, b: Vector2i) -> bool:
	if not is_walkable(a) or not is_walkable(b):
		return false
	return _astar.are_points_connected(_id(a), _id(b))


func _connect_neighbors(cell: Vector2i) -> void:
	if not is_walkable(cell):
		return
	# Orthogonal : vers la droite et le bas (le graphe est bidirectionnel).
	for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
		var other: Vector2i = cell + direction
		if is_walkable(other) and not _lot.blocks_passage(cell, other):
			_astar.connect_points(_id(cell), _id(other))
	# Diagonale : seulement si les deux chemins en « L » sont libres (pas de coin coupé).
	for direction in [Vector2i(1, 1), Vector2i(-1, 1)]:
		var other: Vector2i = cell + direction
		var side_a := cell + Vector2i(direction.x, 0)
		var side_b := cell + Vector2i(0, direction.y)
		if is_walkable(other) and _is_open_step(cell, side_a) and _is_open_step(side_a, other) \
				and _is_open_step(cell, side_b) and _is_open_step(side_b, other):
			_astar.connect_points(_id(cell), _id(other))


func _is_open_step(a: Vector2i, b: Vector2i) -> bool:
	return is_walkable(a) and is_walkable(b) and not _lot.blocks_passage(a, b)


func _id(cell: Vector2i) -> int:
	return cell.y * _lot.size.x + cell.x


func _cell(id: int) -> Vector2i:
	return Vector2i(id % _lot.size.x, id / _lot.size.x)
