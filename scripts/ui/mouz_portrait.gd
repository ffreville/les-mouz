class_name MouzPortrait
extends Control
## Portrait de face d'un Mouz (tête et épaules), à la taille du contrôle,
## sur un rond de couleur facultatif.

var appearance: MouzAppearance:
	set(value):
		appearance = value
		queue_redraw()
## Couleur du rond de fond (transparent = pas de rond).
var background := Color.TRANSPARENT:
	set(value):
		background = value
		queue_redraw()
## Anneau autour du rond (épaisseur 0 = aucun).
var ring_color := Palette.TRAIT
var ring_width := 0.0


func _init(p_size := 48.0) -> void:
	custom_minimum_size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var side := minf(size.x, size.y)
	var rect := Rect2((size - Vector2(side, side)) / 2, Vector2(side, side))
	if background.a > 0:
		draw_circle(rect.get_center(), side / 2, background)
	if appearance != null:
		MouzLayers.draw(self, appearance.portrait_layers(), rect)
	if ring_width > 0:
		draw_arc(rect.get_center(), side / 2 - ring_width / 2, 0, TAU, 48, ring_color, ring_width, true)
