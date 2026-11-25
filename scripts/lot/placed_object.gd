class_name PlacedObject
extends Purchase
## Un objet posé sur le terrain : quelle définition, où, et tourné de combien de quarts de tour.

@export var definition: SmartObjectDefinition
## Coin haut-gauche de l'emprise, en cases.
@export var cell: Vector2i
## Quarts de tour dans le sens horaire (0 à 3).
@export_range(0, 3) var rotation: int = 0
## Collection (style) de l'objet : &"nature", &"retro" ou &"moderne".
@export var collection: StringName = &""
## Allumé (lampes) : affiche l'image « en marche » même sans utilisateur.
@export var switched_on: bool = false
## Usure, de 0 (neuf) à 100 (en panne). Voir Upkeep.
@export var wear: float = 0.0
## Minute de jeu où le réparateur appelé passera (0 : pas appelé).
@export var repair_at: float = 0.0


func is_broken() -> bool:
	return wear >= 100.0


## Collection effective (celle par défaut si aucune n'est choisie ou si elle n'existe plus).
func get_collection() -> StringName:
	return collection if definition.sprites.has(collection) else definition.default_collection()


## Taille en cases une fois tourné.
func size() -> Vector2i:
	var s := definition.size
	return Vector2i(s.y, s.x) if rotation % 2 == 1 else s


## Cases occupées.
func footprint() -> Rect2i:
	return Rect2i(cell, size())
