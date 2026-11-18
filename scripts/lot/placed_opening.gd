class_name PlacedOpening
extends Purchase
## Une porte ou une fenêtre posée sur un ou plusieurs segments de mur.

@export var definition: OpeningDefinition
## Premier segment occupé (les suivants sont dans le sens du mur).
@export var edge: Vector3i
## Côté du battant : vrai = vers le bas (mur horizontal) ou vers la droite (mur vertical).
@export var swing_positive: bool = true
## Charnière de l'autre côté (retournement horizontal du sprite).
@export var hinge_flipped: bool = false


## Tous les segments occupés.
func edges() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for i in definition.width_segments:
		result.append(Edges.next_along(edge, i))
	return result
