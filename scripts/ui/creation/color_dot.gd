class_name ColorDot
extends BaseButton
## Pastille ronde d'une couleur. Choisie : anneau papier puis encre ; survolée : anneau accent.

const RING_GAP := 1.5
const RING_WIDTH := 2.0

var color: Color
var diameter := 26.0
var selected := false:
	set(value):
		selected = value
		queue_redraw()


func _init(p_color := Color.WHITE, p_diameter := 26.0, p_name := "") -> void:
	color = p_color
	diameter = p_diameter
	tooltip_text = p_name.capitalize()
	custom_minimum_size = Vector2.ONE * (diameter + (RING_GAP + RING_WIDTH) * 2)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _draw() -> void:
	var center := size / 2
	var radius := diameter / 2
	if selected or is_hovered():
		draw_arc(center, radius + RING_GAP + RING_WIDTH / 2, 0, TAU, 32,
				Palette.CONTOUR if selected else Palette.ACCENT, RING_WIDTH, true)
	draw_circle(center, radius, color)
	draw_arc(center, radius - 0.75, 0, TAU, 32, Color(Palette.CONTOUR, 0.35), 1.5, true)
