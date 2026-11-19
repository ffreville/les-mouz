class_name MouzBody
extends Node2D
## Le corps d'un Mouz en jeu : calques 32 × 64 posés sur les pieds (position du nœud),
## dans l'une des 4 directions, debout ou en marche.

## Taille d'un calque et hauteur des pieds dans l'image.
const SIZE := Vector2(32, 64)
const FEET_FROM_TOP := 48.0
## En marche, la tête et les cheveux remontent d'un pixel.
const WALK_BOB := 1.0

var appearance: MouzAppearance:
	set(value):
		appearance = value
		_refresh()
var direction: StringName = &"bas"
var pose: String = ""
var flipped := false
var _layers: Array = []


## Change de direction (bas, haut, gauche, droite) et de pose ("", "marche_1", "marche_2").
func show_pose(p_direction: StringName, p_pose: String) -> void:
	var view := &"gauche" if p_direction == &"droite" else p_direction
	var flip := p_direction == &"droite"
	if view == direction and p_pose == pose and flip == flipped and not _layers.is_empty():
		return
	direction = view
	pose = p_pose
	flipped = flip
	_refresh()


func _refresh() -> void:
	_layers = appearance.body_layers(direction, pose) if appearance != null else []
	queue_redraw()


func _draw() -> void:
	MouzLayers.draw(self, _layers, Rect2(Vector2(-SIZE.x / 2, -FEET_FROM_TOP), SIZE), flipped,
			WALK_BOB if pose != "" else 0.0)
