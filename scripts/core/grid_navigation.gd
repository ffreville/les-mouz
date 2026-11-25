class_name GridNavigation
extends Node
## Recherche de chemin sur la grille du terrain (AStar2D), sur tous les niveaux à la fois.
## Les cases sont des « cases de navigation » (voir Levels) : au rez-de-chaussée, la case elle-même ;
## à l'étage, la ligne est décalée de Levels.STRIDE par niveau.
## Chaque case libre est un point ; deux cases voisines sont reliées si aucun mur ne les sépare.
## Les meubles rendent leurs cases inaccessibles ; à l'étage, une case sans sol aussi.
## Un escalier relie la case devant sa marche du bas à la case au-delà de sa marche du haut,
## un niveau plus haut.

const NO_CELL := Vector2i(-1, -1)
const ORTHOGONAL: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
## Sens de la face avant selon la rotation (0 haut, 1 droite, 2 bas, 3 gauche).
const FACING: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var cell_size: int = 32
var _astar := AStar2D.new()
var _lot: Lot
var _blocked: Dictionary[Vector2i, bool] = {}
## Escaliers : par paire de points reliés (« id|id »), les cases de l'escalier du premier au second.
var _stairs: Dictionary[String, Array] = {}


## Construit le graphe. `blocked_cells` : cases de navigation occupées par des meubles.
func setup(lot: Lot, blocked_cells: Array[Vector2i]) -> void:
	_lot = lot
	cell_size = lot.cell_size
	_astar.clear()
	_blocked.clear()
	_stairs.clear()
	for cell in blocked_cells:
		_blocked[cell] = true
	for level in Levels.COUNT:
		for y in lot.size.y:
			for x in lot.size.x:
				var cell := Levels.nav(Vector2i(x, y), level)
				if is_walkable(cell):
					_astar.add_point(_id(cell), Vector2(x, y))
	for level in Levels.COUNT:
		for y in lot.size.y:
			for x in lot.size.x:
				_connect_neighbors(Levels.nav(Vector2i(x, y), level))
	for level in Levels.COUNT - 1:
		for placed in lot.stairs_on(level):
			_connect_stairs(placed, level)


## Les cases d'un escalier, de la marche du bas à celle du haut, et ses deux paliers :
## { "cells", "entry" (devant la marche du bas, à son niveau), "exit" (au-delà du haut, niveau suivant) }.
static func stairs_path(placed: PlacedObject, level: int) -> Dictionary:
	var front := FACING[posmod(placed.rotation, 4)]
	var rect := placed.footprint()
	var cells: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	# La marche du bas est du côté de la face avant.
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Vector2(a).dot(front) > Vector2(b).dot(front))
	return {"cells": cells, "entry": Levels.nav(cells[0] + front, level),
			"exit": Levels.nav(cells[-1] - front, level + 1)}


func _connect_stairs(placed: PlacedObject, level: int) -> void:
	var stairs := stairs_path(placed, level)
	var entry: Vector2i = stairs["entry"]
	var exit: Vector2i = stairs["exit"]
	if not is_walkable(entry) or not is_walkable(exit):
		return
	_astar.connect_points(_id(entry), _id(exit))
	var up: Array = stairs["cells"]
	var down: Array = up.duplicate()
	down.reverse()
	_stairs["%d|%d" % [_id(entry), _id(exit)]] = up
	_stairs["%d|%d" % [_id(exit), _id(entry)]] = down


## Cases (du terrain) de l'escalier pris pour aller de `a` à `b`, ou [] si ce n'est pas un escalier.
func stairs_between(a: Vector2i, b: Vector2i) -> Array:
	return _stairs.get("%d|%d" % [_id(a), _id(b)], [])


func is_walkable(cell: Vector2i) -> bool:
	var level := Levels.level_of(cell)
	var flat := Levels.flat(cell)
	if level < 0 or level >= Levels.COUNT or not _lot.contains(flat) or _blocked.has(cell):
		return false
	return level == 0 or _lot.floor_at(flat, level) != null


## Centre d'une case, en coordonnées du monde (le même à tous les niveaux).
func cell_to_world(cell: Vector2i) -> Vector2:
	return (Vector2(Levels.flat(cell)) + Vector2(0.5, 0.5)) * cell_size


## La case de navigation sous une position du monde, au niveau `level`.
func world_to_cell(world_position: Vector2, level := 0) -> Vector2i:
	return Levels.nav(Vector2i((world_position / cell_size).floor()), level)


## La case libre la plus proche de `cell`, au même niveau (elle-même si elle est libre).
func nearest_walkable(cell: Vector2i) -> Vector2i:
	if is_walkable(cell):
		return cell
	var level := Levels.level_of(cell)
	var flat := Levels.flat(cell)
	for radius in range(1, maxi(_lot.size.x, _lot.size.y)):
		for y in range(flat.y - radius, flat.y + radius + 1):
			for x in range(flat.x - radius, flat.x + radius + 1):
				var candidate := Levels.nav(Vector2i(x, y), level)
				if y >= 0 and is_walkable(candidate):
					return candidate
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
## `rect` est en cases de navigation (un seul niveau).
func cells_around(rect: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var level := Levels.level_of(rect.position)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var inner := Vector2i(x, y)
			for direction in ORTHOGONAL:
				var outer := inner + direction
				if rect.has_point(outer) or outer in result:
					continue
				if is_walkable(outer) and not _lot.blocks_passage(Levels.flat(inner), Levels.flat(outer), level):
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
		if _is_open_step(cell, other):
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
	return is_walkable(a) and is_walkable(b) \
			and not _lot.blocks_passage(Levels.flat(a), Levels.flat(b), Levels.level_of(a))


func _id(cell: Vector2i) -> int:
	var flat := Levels.flat(cell)
	return (Levels.level_of(cell) * _lot.size.y + flat.y) * _lot.size.x + flat.x


func _cell(id: int) -> Vector2i:
	var per_level := _lot.size.x * _lot.size.y
	var rest := id % per_level
	return Levels.nav(Vector2i(rest % _lot.size.x, rest / _lot.size.x), id / per_level)
