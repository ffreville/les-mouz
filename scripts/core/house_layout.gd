class_name HouseLayout
extends Resource
## Plan de la maison : pièces, portes, meubles et points d'apparition.
## Les murs ne sont pas décrits : il y en a un entre deux cases de pièces différentes
## (ou entre une pièce et l'extérieur), sauf si l'une des deux cases est une porte.

## Taille de la grille, en cases.
@export var grid_size: Vector2i = Vector2i(20, 16)
## Taille d'une case, en pixels.
@export var cell_size: int = 32
@export var rooms: Array[RoomDefinition] = []
## Cases de porte : le mur qui sépare cette case d'une autre pièce (ou de l'extérieur) est ouvert.
@export var doors: Array[Vector2i] = []
## Meubles et objets posés dans la maison.
@export var objects: Array[ObjectPlacement] = []
## Cases de départ des personnages (un par fiche, dans l'ordre).
@export var character_spawns: Array[Vector2i] = [Vector2i(4, 4)]


## Indice de la pièce qui contient la case, ou -1 si elle est dehors.
func room_index_at(cell: Vector2i) -> int:
	for i in rooms.size():
		if rooms[i].rect.has_point(cell):
			return i
	return -1


func is_inside(cell: Vector2i) -> bool:
	return room_index_at(cell) >= 0


## Vrai si un mur sépare deux cases voisines (horizontalement ou verticalement).
func has_wall_between(a: Vector2i, b: Vector2i) -> bool:
	if room_index_at(a) == room_index_at(b):
		return false
	return not (a in doors or b in doors)
