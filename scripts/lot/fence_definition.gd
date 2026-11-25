class_name FenceDefinition
extends Resource
## Une clôture : posée sur les arêtes de la grille comme un mur, mais basse, et elle ne ferme
## pas de pièce (le jardin clôturé reste dehors). Un portail s'y pose comme une porte sur un mur.

enum Look { PICKETS, BOARDS, HEDGE }

@export var id: StringName = &"cloture"
@export var display_name: String = "Clôture"
@export var look: Look = Look.PICKETS
@export var color: Color = Color("#F4EFE6")
## Poteaux, lisses et contours.
@export var post_color: Color = Color("#D9CFBF")
@export var price_per_segment: int = 25
