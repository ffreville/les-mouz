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
## Dans l'eau, la surface est à 47 px du haut du calque (brief n° 8).
const WATER_FROM_TOP := 47.0
const SPLASH := "res://assets/sprites/eclaboussure_%d.svg"
## Ancrage de l'éclaboussure (32 × 32) sur l'eau.
const SPLASH_ANCHOR := Vector2(16, 26)

var appearance: MouzAppearance:
	set(value):
		appearance = value
		_refresh()
var direction: StringName = &"bas"
var pose: String = ""
var flipped := false
## Dans l'eau de la piscine ou en plein plongeon : pas d'ombre (les calques de nage ont leurs remous).
var in_water := false:
	set(value):
		in_water = value
		shadow = not value
		queue_redraw()
## Éclaboussure posée sur l'eau aux pieds du Mouz : 0 (aucune), 1 (la gerbe) ou 2 (les ronds).
var splash := 0:
	set(value):
		if splash == 0 and value > 0:
			MouzLayers.texture(SPLASH % 2)
		if value != splash:
			splash = value
			queue_redraw()
## Ombre au sol (pas dans un escalier).
var shadow := true:
	set(value):
		if value != shadow:
			shadow = value
			_refresh()
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
	_layers = appearance.body_layers(direction, pose, shadow) if appearance != null else []
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
	elif pose.begins_with("monter") or pose.begins_with("descendre"):
		# Escalier de profil : la tête remonte d'un pixel sur la deuxième image.
		bob = WALK_BOB if pose.ends_with("_2") else 0.0
	elif pose.begins_with("nage"):
		bob = -float(MouzAppearance.SWIM_HEAD_DROP.get(appearance.age, 0.0)) if appearance != null else 0.0
	elif pose != "":
		bob = -head_drop
	var top := WATER_FROM_TOP if pose.begins_with("nage") else FEET_FROM_TOP
	MouzLayers.draw(self, _layers, Rect2(Vector2(-SIZE.x / 2, -top), SIZE), flipped, bob)
	if splash > 0:
		var texture := MouzLayers.texture(SPLASH % splash)
		if texture != null:
			draw_texture(texture, -SPLASH_ANCHOR)
