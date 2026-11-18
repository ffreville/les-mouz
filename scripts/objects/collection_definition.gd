class_name CollectionDefinition
extends Resource
## Une collection de styles (Nature, Rétro, Moderne) : elle change l'apparence des objets,
## jamais leur taille, leur face avant ni leurs interactions.

@export var id: StringName = &"collection"
@export var display_name: String = "Collection"
## Couleur de la pastille de collection.
@export var color: Color = Color.WHITE
## Icône de la pastille (version blanche, teintée selon le fond).
@export var icon: Texture2D
## Couleur de l'icône sur la pastille (encre sur fond clair, blanc sur fond foncé).
@export var icon_color: Color = Color("#2B2440")
## Ordre d'affichage.
@export var order: int = 0
