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
## Clôtures, posées sur les arêtes comme les murs (mais elles ne ferment pas de pièce).
@export var fences: Dictionary[Vector3i, PlacedFence] = {}
## Papiers peints, par segment de mur horizontal (ils habillent sa face sud, visible).
@export var wallpapers: Dictionary[Vector3i, PlacedWallpaper] = {}
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


## Vrai si l'on ne peut pas passer de la case `a` à sa voisine `b` (mur ou clôture sans porte ni portail).
func blocks_passage(a: Vector2i, b: Vector2i) -> bool:
	var edge := Edges.between(a, b)
	if not has_wall(edge) and not fences.has(edge):
		return false
	var opening := opening_at(edge)
	return opening == null or not opening.definition.is_passable()


## Revêtement de la case (l'herbe par défaut).
func floor_at(cell: Vector2i) -> FloorDefinition:
	return floors[cell].definition if floors.has(cell) else default_floor


## Cases à l'intérieur d'une pièce fermée : celles qu'on ne peut pas atteindre depuis l'extérieur
## du terrain sans traverser un mur (une porte compte comme un mur ici).
func interior_cells() -> Dictionary:
	var outside := {Vector2i(-1, -1): true}
	var todo: Array[Vector2i] = [Vector2i(-1, -1)]
	while not todo.is_empty():
		var cell: Vector2i = todo.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if next.x < -1 or next.y < -1 or next.x > size.x or next.y > size.y or outside.has(next):
				continue
			if walls.has(Edges.between(cell, next)):
				continue
			outside[next] = true
			todo.append(next)
	var inside := {}
	for y in size.y:
		for x in size.x:
			if not outside.has(Vector2i(x, y)):
				inside[Vector2i(x, y)] = true
	return inside


## Les cases de la pièce fermée qui contient `start` (vide si elle n'est pas dans une pièce).
## Les portes séparent les pièces.
func room_cells(start: Vector2i) -> Array[Vector2i]:
	var interior := interior_cells()
	if not interior.has(start):
		return []
	var room: Array[Vector2i] = [start]
	var seen := {start: true}
	var index := 0
	while index < room.size():
		var cell := room[index]
		index += 1
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or not interior.has(next) or walls.has(Edges.between(cell, next)):
				continue
			seen[next] = true
			room.append(next)
	return room


## Segments de mur dont la face visible donne sur la pièce : le mur du haut de chacune de ses cases.
func room_wall_faces(room: Array[Vector2i]) -> Array[Vector3i]:
	var faces: Array[Vector3i] = []
	for cell in room:
		var edge := Vector3i(cell.x, cell.y, Edges.HORIZONTAL)
		if walls.has(edge):
			faces.append(edge)
	return faces


## Objet solide qui occupe la case, ou null.
func blocking_object_at(cell: Vector2i) -> PlacedObject:
	for placed in objects:
		if placed.definition.blocks_movement and placed.footprint().has_point(cell):
			return placed
	return null
