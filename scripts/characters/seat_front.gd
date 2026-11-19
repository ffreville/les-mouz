class_name SeatFront
extends Node2D
## Calque de l'objet qui passe devant un Mouz installé (dossier de chaise, couette, eau du bain).
## Il se dessine juste après le corps, à l'endroit exact du sprite de l'objet.

var _texture: Texture2D
var _rect := Rect2()
var _flip := false


func show_layer(texture: Texture2D, rect: Rect2, flip: bool) -> void:
	_texture = texture
	_rect = rect
	_flip = flip
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	if _flip:
		draw_set_transform(Vector2(_rect.position.x * 2 + _rect.size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect(_texture, _rect, false)
	draw_set_transform_matrix(Transform2D.IDENTITY)
