class_name Lot
extends Resource
## Le terrain : murs posés sur les arêtes, sols case par case, portes et fenêtres, objets.
## C'est la donnée que l'éditeur modifie et que la sauvegarde enregistre.

## Taille du terrain, en cases.
@export var size: Vector2i = Vector2i(30, 20)
## Taille d'une case, en pixels.
@export var cell_size: int = 32
## Sol des cases sans revêtement (l'herbe).
@export var default_floor: FloorDefinition
@export var walls: Dictionary[Vector3i, PlacedWall] = {}
@export var floors: Dictionary[Vector2i, PlacedFloor] = {}
@export var openings: Array[PlacedOpening] = []
@export var objects: Array[PlacedObject] = []
## Cases de départ des personnages (un par fiche, dans l'ordre).
@export var spawn_cells: Array[Vector2i] = [Vector2i(1, 18), Vector2i(3, 18)]


func contains(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).has_point(cell)


## Vrai si l'arête est sur le terrain (bords compris).
func contains_edge(edge: Vector3i) -> bool:
	if edge.z == Edges.HORIZONTAL:
		return edge.x >= 0 and edge.x < size.x and edge.y >= 0 and edge.y <= size.y
	return edge.x >= 0 and edge.x <= size.x and edge.y >= 0 and edge.y < size.y


func has_wall(edge: Vector3i) -> bool:
	return walls.has(edge)


## La porte ou la fenêtre posée sur cette arête, ou null.
func opening_at(edge: Vector3i) -> PlacedOpening:
	for opening in openings:
		if edge in opening.edges():
			return opening
	return null


## Vrai si l'on ne peut pas passer de la case `a` à sa voisine `b` (mur sans porte).
func blocks_passage(a: Vector2i, b: Vector2i) -> bool:
	var edge := Edges.between(a, b)
	if not has_wall(edge):
		return false
	var opening := opening_at(edge)
	return opening == null or not opening.definition.is_passable()


## Revêtement de la case (l'herbe par défaut).
func floor_at(cell: Vector2i) -> FloorDefinition:
	return floors[cell].definition if floors.has(cell) else default_floor


## Objet solide qui occupe la case, ou null.
func blocking_object_at(cell: Vector2i) -> PlacedObject:
	for placed in objects:
		if placed.definition.blocks_movement and placed.footprint().has_point(cell):
			return placed
	return null
