class_name HouseLayout
extends Resource
## Plan de la maison : grille, pièces, murs, portes, meubles et points d'apparition.
## Tout se modifie dans l'inspecteur, sans toucher au code.

## Taille de la grille, en cases.
@export var grid_size: Vector2i = Vector2i(24, 16)
## Taille d'une case, en pixels.
@export var cell_size: int = 32
@export var rooms: Array[RoomDefinition] = []
## Rectangles de murs, en cases.
@export var walls: Array[Rect2i] = []
## Cases de mur transformées en passage.
@export var doors: Array[Vector2i] = []
@export var wall_color: Color = Color(0.23, 0.21, 0.19)
@export var door_color: Color = Color(0.55, 0.47, 0.38)


## Vrai si la case est un mur (et pas une porte).
func is_wall(cell: Vector2i) -> bool:
	if cell in doors:
		return false
	for wall in walls:
		if wall.has_point(cell):
			return true
	return false
