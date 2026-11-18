class_name FloorDefinition
extends Resource
## Un revêtement de sol du catalogue (tuile 32 × 32 raccordable).

@export var id: StringName = &"sol"
@export var display_name: String = "Sol"
@export var texture: Texture2D
@export var price_per_cell: int = 10
