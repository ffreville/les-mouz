class_name SmartObjectDefinition
extends Resource
## Un type d'objet « intelligent » : son apparence et les actions qu'il propose.

## Identifiant unique (sert à la sauvegarde et au catalogue).
@export var id: StringName = &"objet"
@export var display_name: String = "Objet"
## Image vue de dessus, à la taille de l'objet (32 px par case). Sans image : un rectangle de `color`.
@export var sprite: Texture2D
@export var color: Color = Color(0.6, 0.5, 0.4)
## Taille en cases.
@export var size: Vector2i = Vector2i.ONE
## Faux pour un objet au sol qu'on peut traverser (tapis…).
@export var blocks_movement: bool = true
## Actions proposées. Un objet sans action est purement décoratif.
@export var actions: Array[ActionDefinition] = []
## Nombre de personnages pouvant l'utiliser en même temps.
@export var capacity: int = 1
## Prix d'achat en Mz.
@export var price: int = 100
## Catégorie du catalogue : cuisine, chambre, salon, salle_de_bain ou deco.
@export var category: StringName = &"deco"
