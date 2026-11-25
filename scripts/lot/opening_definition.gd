class_name OpeningDefinition
extends Resource
## Une porte ou une fenêtre du catalogue, posée sur un mur (ou un portail, posé sur une clôture).

enum Kind { DOOR, WINDOW }

@export var id: StringName = &"ouverture"
@export var display_name: String = "Ouverture"
@export var kind: Kind = Kind.DOOR
## Image dessinée pour un mur horizontal, pièce en dessous (le jeu la tourne au besoin).
## Porte : 32 × 40 (8 px de seuil + battant). Fenêtre : largeur × 8.
@export var sprite: Texture2D
## Nombre de segments de mur occupés.
@export var width_segments: int = 1
@export var price: int = 250
## Se pose sur une clôture (portail) au lieu d'un mur.
@export var on_fence: bool = false


## Les portes laissent passer les personnages, pas les fenêtres.
func is_passable() -> bool:
	return kind == Kind.DOOR
