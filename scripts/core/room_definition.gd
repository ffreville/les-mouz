class_name RoomDefinition
extends Resource
## Une pièce de la maison : un rectangle de cases avec un sol (couleur + motif).

enum FloorPattern { NONE, PLANKS, CHECKER, DOTS, GRID }

@export var display_name: String = "Pièce"
## Position et taille de la pièce, en cases.
@export var rect: Rect2i = Rect2i(0, 0, 4, 4)
@export var floor_color: Color = Color(0.8, 0.8, 0.8)
## Motif du sol : lames (parquet), damier (carrelage), points (moquette), quadrillage (faïence).
@export var pattern: FloorPattern = FloorPattern.NONE
@export var pattern_color: Color = Color(0.7, 0.7, 0.7)
