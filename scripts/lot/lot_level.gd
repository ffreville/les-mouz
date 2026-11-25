class_name LotLevel
extends Resource
## Un niveau d'un terrain (0 : rez-de-chaussée, puis les étages) : murs, sols, ouvertures,
## papiers peints et objets. À l'étage, une case sans sol est du vide (on y voit le niveau du dessous).

@export var walls: Dictionary[Vector3i, PlacedWall] = {}
@export var floors: Dictionary[Vector2i, PlacedFloor] = {}
@export var openings: Array[PlacedOpening] = []
## Papiers peints, par segment de mur horizontal (ils habillent sa face sud, visible).
@export var wallpapers: Dictionary[Vector3i, PlacedWallpaper] = {}
@export var objects: Array[PlacedObject] = []


func is_empty() -> bool:
	return walls.is_empty() and floors.is_empty() and openings.is_empty() and objects.is_empty()
