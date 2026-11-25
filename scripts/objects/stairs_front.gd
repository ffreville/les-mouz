class_name StairsFront
extends Node2D
## Ce qui passe devant un Mouz dans l'escalier (brief n° 7) : la rampe en vue de profil,
## les marches du dessus en vue de dos. Posé juste après l'escalier et les Mouz qui le prennent.

var stairs: SmartObject
## Mouz dans l'escalier et la marche où ils sont.
var _climbers: Dictionary[Node, int] = {}


func set_climber(character: Node, step: int) -> void:
	if _climbers.get(character, -1) != step:
		_climbers[character] = step
		queue_redraw()


func remove_climber(character: Node) -> void:
	if _climbers.erase(character):
		queue_redraw()


func _draw() -> void:
	if stairs == null:
		return
	var step := 0
	for value in _climbers.values():
		step = value if step == 0 else mini(step, value)
	# Vue de profil : la rampe est toujours devant ; vue de dos : seulement quand quelqu'un monte.
	if StairsArt.view(stairs) == &"haut" and step == 0:
		return
	var layer := StairsArt.front_layer(stairs, step)
	var texture: Texture2D = layer[0]
	if texture == null:
		return
	var rect := stairs.sprite_rect_local()
	rect.position += stairs.position - position
	if layer[1]:
		draw_set_transform(rect.position + Vector2(rect.size.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect(texture, Rect2(Vector2.ZERO, rect.size), false)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		draw_texture_rect(texture, rect, false)
