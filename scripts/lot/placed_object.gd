class_name PlacedObject
extends Purchase
## Un objet posé sur le terrain : quelle définition, où, et tourné de combien de quarts de tour.

@export var definition: SmartObjectDefinition
## Coin haut-gauche de l'emprise, en cases.
@export var cell: Vector2i
## Quarts de tour dans le sens horaire (0 à 3).
@export_range(0, 3) var rotation: int = 0


## Taille en cases une fois tourné.
func size() -> Vector2i:
	var s := definition.size
	return Vector2i(s.y, s.x) if rotation % 2 == 1 else s


## Cases occupées.
func footprint() -> Rect2i:
	return Rect2i(cell, size())
