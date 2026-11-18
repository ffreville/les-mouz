class_name RoomDefinition
extends Resource
## Une pièce de la maison : un rectangle de cases avec une couleur de sol.

@export var display_name: String = "Pièce"
## Position et taille de la pièce, en cases.
@export var rect: Rect2i = Rect2i(1, 1, 4, 4)
@export var floor_color: Color = Color(0.8, 0.8, 0.8)
