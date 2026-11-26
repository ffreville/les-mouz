class_name Lot
extends Resource
## Le terrain : ses niveaux (murs posés sur les arêtes, sols case par case, portes et fenêtres,
## objets), ses clôtures et ses cases d'arrivée.
## C'est la donnée que l'éditeur modifie et que la sauvegarde enregistre.

## Taille du terrain, en cases.
@export var size: Vector2i = Vector2i(30, 20)
## Taille d'une case, en pixels.
@export var cell_size: int = 32
## Sol des cases sans revêtement (l'herbe).
@export var default_floor: FloorDefinition
## Clôtures, posées sur les arêtes comme les murs (mais elles ne ferment pas de pièce).
## Au rez-de-chaussée seulement.
@export var fences: Dictionary[Vector3i, PlacedFence] = {}
## Cases de piscine (jardin, rez-de-chaussée) : de l'eau, qu'on ne traverse pas à pied.
@export var pool: Dictionary[Vector2i, PlacedPool] = {}
## Le toit de la maison (null : pas de toit). Sa forme est calculée (voir `roof_cells`).
@export var roof: PlacedRoof
## Les niveaux : 0 est le rez-de-chaussée (voir Levels). Les étages vides peuvent manquer.
@export var levels: Array[LotLevel] = []
## Cases de départ des personnages (un par fiche, dans l'ordre).
@export var spawn_cells: Array[Vector2i] = [Vector2i(1, 18), Vector2i(3, 18)]


# --- Niveaux ----------------------------------------------------------------------

## Le niveau `index` (créé s'il manque).
func level(index: int) -> LotLevel:
	while levels.size() <= index:
		levels.append(LotLevel.new())
	return levels[index]


## Nombre de niveaux qui contiennent quelque chose (au moins le rez-de-chaussée).
func used_levels() -> int:
	var count := 1
	for i in levels.size():
		if not levels[i].is_empty():
			count = i + 1
	return count


## Le rez-de-chaussée, sous ses anciens noms : le code qui ne connaît qu'un niveau y travaille.
var walls: Dictionary[Vector3i, PlacedWall]:
	get:
		return level(0).walls
	set(value):
		level(0).walls = value
var floors: Dictionary[Vector2i, PlacedFloor]:
	get:
		return level(0).floors
	set(value):
		level(0).floors = value
var openings: Array[PlacedOpening]:
	get:
		return level(0).openings
	set(value):
		level(0).openings = value
var wallpapers: Dictionary[Vector3i, PlacedWallpaper]:
	get:
		return level(0).wallpapers
	set(value):
		level(0).wallpapers = value
var objects: Array[PlacedObject]:
	get:
		return level(0).objects
	set(value):
		level(0).objects = value


## Tous les objets posés, de tous les niveaux : [[objet, niveau], …].
func all_objects() -> Array:
	var result: Array = []
	for i in levels.size():
		for placed in levels[i].objects:
			result.append([placed, i])
	return result


## Les escaliers posés au niveau `index` (ils montent au niveau suivant).
func stairs_on(index: int) -> Array[PlacedObject]:
	var result: Array[PlacedObject] = []
	if index < levels.size():
		for placed in levels[index].objects:
			if placed.definition.is_stairs:
				result.append(placed)
	return result


## Cases couvertes par le toit au niveau `index` : ses pièces fermées sans plancher au-dessus.
## `top_visible` : le dernier niveau affiché (les étages au-dessus, cachés, ne comptent pas).
func roof_cells(index: int, top_visible := Levels.COUNT - 1) -> Dictionary:
	var cells := interior_cells(index)
	if index < top_visible and index + 1 < levels.size():
		for cell in levels[index + 1].floors:
			cells.erase(cell)
	return cells


## Nombre de cases couvertes par le toit, à tous les niveaux.
func roof_size() -> int:
	var count := 0
	for index in used_levels():
		count += roof_cells(index).size()
	return count


## Vrai si la case est la cage d'un escalier qui monte du niveau du dessous (pas de sol possible).
func is_stairwell(cell: Vector2i, index: int) -> bool:
	if index <= 0:
		return false
	for placed in stairs_on(index - 1):
		if placed.footprint().has_point(cell):
			return true
	return false


func contains(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).has_point(cell)


## Vrai si l'arête est sur le terrain (bords compris).
func contains_edge(edge: Vector3i) -> bool:
	if edge.z == Edges.HORIZONTAL:
		return edge.x >= 0 and edge.x < size.x and edge.y >= 0 and edge.y <= size.y
	return edge.x >= 0 and edge.x <= size.x and edge.y >= 0 and edge.y < size.y


func has_wall(edge: Vector3i, index := 0) -> bool:
	return index < levels.size() and levels[index].walls.has(edge)


## La porte ou la fenêtre posée sur cette arête, ou null.
func opening_at(edge: Vector3i, index := 0) -> PlacedOpening:
	if index >= levels.size():
		return null
	for opening in levels[index].openings:
		if edge in opening.edges():
			return opening
	return null


## Vrai si l'on ne peut pas passer de la case `a` à sa voisine `b` (mur ou clôture sans porte ni portail).
func blocks_passage(a: Vector2i, b: Vector2i, index := 0) -> bool:
	var edge := Edges.between(a, b)
	if not has_wall(edge, index) and not (index == 0 and fences.has(edge)):
		return false
	var opening := opening_at(edge, index)
	return opening == null or not opening.definition.is_passable()


## Revêtement de la case : l'herbe par défaut au rez-de-chaussée ; à l'étage, null s'il n'y a
## pas de sol (du vide) ou si c'est une cage d'escalier.
func floor_at(cell: Vector2i, index := 0) -> FloorDefinition:
	if index == 0:
		return floors[cell].definition if floors.has(cell) else default_floor
	if index >= levels.size() or not levels[index].floors.has(cell) or is_stairwell(cell, index):
		return null
	return levels[index].floors[cell].definition


## Cases à l'intérieur d'une pièce fermée : celles qu'on ne peut pas atteindre depuis l'extérieur
## du terrain sans traverser un mur (une porte compte comme un mur ici).
func interior_cells(index := 0) -> Dictionary:
	var level_walls := level(index).walls
	var outside := {Vector2i(-1, -1): true}
	var todo: Array[Vector2i] = [Vector2i(-1, -1)]
	while not todo.is_empty():
		var cell: Vector2i = todo.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if next.x < -1 or next.y < -1 or next.x > size.x or next.y > size.y or outside.has(next):
				continue
			if level_walls.has(Edges.between(cell, next)):
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
func room_cells(start: Vector2i, index := 0) -> Array[Vector2i]:
	var interior := interior_cells(index)
	var level_walls := level(index).walls
	if not interior.has(start):
		return []
	var room: Array[Vector2i] = [start]
	var seen := {start: true}
	var cursor := 0
	while cursor < room.size():
		var cell := room[cursor]
		cursor += 1
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or not interior.has(next) or level_walls.has(Edges.between(cell, next)):
				continue
			seen[next] = true
			room.append(next)
	return room


## Segments de mur dont la face visible donne sur la pièce : le mur du haut de chacune de ses cases.
func room_wall_faces(room: Array[Vector2i], index := 0) -> Array[Vector3i]:
	var faces: Array[Vector3i] = []
	for cell in room:
		var edge := Vector3i(cell.x, cell.y, Edges.HORIZONTAL)
		if has_wall(edge, index):
			faces.append(edge)
	return faces


## Objet solide qui occupe la case, ou null.
func blocking_object_at(cell: Vector2i, index := 0) -> PlacedObject:
	if index >= levels.size():
		return null
	for placed in levels[index].objects:
		if placed.definition.blocks_movement and placed.footprint().has_point(cell):
			return placed
	return null
