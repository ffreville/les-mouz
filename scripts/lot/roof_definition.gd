class_name RoofDefinition
extends Resource
## Un style de toit (toute la maison le partage) : couleurs des pans et prix par case couverte.
## Le toit lui-même est calculé tout seul (voir RoofView).

@export var id: StringName = &"toit"
@export var display_name: String = "Toit"
## Pan au soleil (sud), pan vu du dessus (nord), pan éclairé (ouest), pan à l'ombre (est).
@export var color: Color = Color("#C4664A")
@export var top_color: Color = Color("#D8896C")
@export var light_color: Color = Color("#D27A5C")
@export var dark_color: Color = Color("#9E4D37")
## Lignes du matériau (rangs de tuiles, joints) et faîtage.
@export var line_color: Color = Color("#8E4330")
## Écart entre deux rangs (tuiles, ardoises, joints du zinc, bottes de chaume).
@export var row_step: float = 6.0
@export var price_per_cell: int = 6
