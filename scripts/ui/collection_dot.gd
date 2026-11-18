class_name CollectionDot
extends BaseButton
## Pastille ronde d'une collection (couleur signature + icône). Anneau quand elle est choisie
## (encre) ou survolée (accent). La forme de l'icône distingue les collections sans la couleur.

const RING_GAP := 2.0
const RING_WIDTH := 2.0

var collection: CollectionDefinition
var diameter: float = 22.0
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()


func _init(p_collection: CollectionDefinition = null, p_diameter := 22.0) -> void:
	collection = p_collection
	diameter = p_diameter
	custom_minimum_size = Vector2.ONE * (diameter + (RING_GAP + RING_WIDTH) * 2)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if collection != null:
		tooltip_text = collection.display_name
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _draw() -> void:
	if collection == null:
		return
	var center := size / 2
	var radius := diameter / 2
	if selected or is_hovered():
		var ring := Palette.CONTOUR if selected else Palette.ACCENT
		draw_arc(center, radius + RING_GAP + RING_WIDTH / 2, 0, TAU, 32, ring, RING_WIDTH, true)
	draw_circle(center, radius, collection.color)
	draw_arc(center, radius - 1, 0, TAU, 32, Palette.CONTOUR, 2.0, true)
	if collection.icon != null:
		var icon_size := diameter * 0.55
		draw_texture_rect(collection.icon, Rect2(center - Vector2.ONE * icon_size / 2, Vector2.ONE * icon_size),
				false, collection.icon_color)
