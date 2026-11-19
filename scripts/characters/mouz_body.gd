class_name MouzBody
extends Node2D
## Le corps d'un Mouz en jeu : calques 32 × 64 posés sur les pieds (position du nœud),
## dans l'une des 4 directions : debout, en marche, assis, en tailleur, à genoux ou allongé.
## Assis, en tailleur et à genoux, le point d'ancrage est le sol sous les hanches, et la tête
## descend de `head_drop`. Allongé, les calques debout pivotent autour du centre de la tête,
## posé sur la position du nœud.

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
## Descente de la tête dans les poses assises (px).
var head_drop := 0.0
## Allongé : rotation (degrés, sens horaire) et centre de la tête dans l'image 32 × 64.
var lying_rotation := 0.0
var lying_pivot := Vector2(16, 8)
var _layers: Array = []


## Change de direction (bas, haut, gauche, droite) et de pose ("", "marche_1", "marche_2",
## "assis", "tailleur", "genoux", "allonge").
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
	if pose == "allonge":
		draw_set_transform(Vector2.ZERO, deg_to_rad(lying_rotation))
		MouzLayers.draw(self, _layers, Rect2(-lying_pivot, SIZE))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	var bob := 0.0
	if pose.begins_with("marche"):
		bob = WALK_BOB
	elif pose != "":
		bob = -head_drop
	MouzLayers.draw(self, _layers, Rect2(Vector2(-SIZE.x / 2, -FEET_FROM_TOP), SIZE), flipped, bob)
