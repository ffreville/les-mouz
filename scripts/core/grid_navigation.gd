class_name GridNavigation
extends Node
## Recherche de chemin sur la grille de la maison (AStarGrid2D).
## Les murs et les meubles sont des cases « solides ».

const NO_CELL := Vector2i(-1, -1)

var astar := AStarGrid2D.new()
var cell_size: int = 32


func setup(grid_size: Vector2i, p_cell_size: int) -> void:
	cell_size = p_cell_size
	astar.region = Rect2i(Vector2i.ZERO, grid_size)
	astar.cell_size = Vector2(cell_size, cell_size)
	# Diagonales autorisées seulement si elles ne frôlent pas un obstacle.
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()


func set_blocked(cell: Vector2i, blocked: bool) -> void:
	if astar.is_in_boundsv(cell):
		astar.set_point_solid(cell, blocked)


func is_walkable(cell: Vector2i) -> bool:
	return astar.is_in_boundsv(cell) and not astar.is_point_solid(cell)


## Centre d'une case, en coordonnées du monde.
func cell_to_world(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i((world_position / cell_size).floor())


## Liste des cases de `from` à `to` (incluses). Vide si aucun chemin.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not is_walkable(from) or not is_walkable(to):
		return []
	return astar.get_id_path(from, to)


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


## Cases libres qui touchent un rectangle (côtés uniquement, pas les coins).
func cells_around(rect: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(rect.position.x, rect.end.x):
		result.append(Vector2i(x, rect.position.y - 1))
		result.append(Vector2i(x, rect.end.y))
	for y in range(rect.position.y, rect.end.y):
		result.append(Vector2i(rect.position.x - 1, y))
		result.append(Vector2i(rect.end.x, y))
	return result.filter(is_walkable)
