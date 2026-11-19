class_name LotOffer
extends Resource
## Un terrain proposé à l'emménagement : vide ou déjà meublé, avec son prix.

@export var id: StringName = &"terrain"
@export var display_name: String = "Terrain"
@export var lot: Lot
## Prix payé à l'emménagement, pris sur le budget de départ.
@export var price: int = 0
## Vignette vue d'en haut (16:9).
@export var thumbnail: Texture2D
## Ordre d'affichage.
@export var order: int = 0


func is_furnished() -> bool:
	return lot != null and not lot.objects.is_empty()
