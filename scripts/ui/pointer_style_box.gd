class_name PointerStyleBox
extends StyleBox
## Panneau arrondi avec une pointe de 14 px sur un côté, tournée vers ce que le menu désigne.
## Le panneau est dessiné en retrait du côté de la pointe, qui occupe cette marge.

## Longueur de la pointe (du bord du panneau à son extrémité).
const POINTER_LENGTH := 14.0
## Demi-hauteur de la base de la pointe.
const POINTER_HALF_BASE := 8.0

## Le panneau lui-même (couleur, bordure, rayon, ombre).
var box: StyleBoxFlat
## Pointe à gauche (sinon à droite).
var pointer_on_left: bool = true:
	set(value):
		pointer_on_left = value
		_update_margins()
		emit_changed()
## Hauteur de l'extrémité de la pointe, depuis le haut du panneau.
var pointer_y: float = 24.0:
	set(value):
		pointer_y = value
		emit_changed()


func _init(p_box: StyleBoxFlat = null) -> void:
	box = p_box if p_box != null else StyleBoxFlat.new()
	_update_margins()


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var inner := rect
	inner.size.x -= POINTER_LENGTH
	if pointer_on_left:
		inner.position.x += POINTER_LENGTH
	box.draw(to_canvas_item, inner)

	# La pointe reste à l'écart des coins arrondis.
	var margin := float(box.corner_radius_top_left) + POINTER_HALF_BASE
	var y := rect.position.y + clampf(pointer_y, margin, rect.size.y - margin)
	var direction := -1.0 if pointer_on_left else 1.0
	var edge_x := inner.position.x if pointer_on_left else inner.end.x
	var tip := Vector2(rect.position.x if pointer_on_left else rect.end.x, y)
	# La base empiète sur la bordure du panneau pour la masquer.
	var base_x := edge_x - direction * box.border_width_left
	var top := Vector2(edge_x, y - POINTER_HALF_BASE)
	var bottom := Vector2(edge_x, y + POINTER_HALF_BASE)
	RenderingServer.canvas_item_add_polygon(to_canvas_item,
			PackedVector2Array([Vector2(base_x, top.y), tip, Vector2(base_x, bottom.y)]),
			PackedColorArray([box.bg_color]))
	RenderingServer.canvas_item_add_line(to_canvas_item, top, tip, box.border_color, box.border_width_left, true)
	RenderingServer.canvas_item_add_line(to_canvas_item, tip, bottom, box.border_color, box.border_width_left, true)


## Marges de contenu : celles du panneau, plus la place de la pointe.
func _update_margins() -> void:
	content_margin_top = box.content_margin_top
	content_margin_bottom = box.content_margin_bottom
	content_margin_left = box.content_margin_left + (POINTER_LENGTH if pointer_on_left else 0.0)
	content_margin_right = box.content_margin_right + (0.0 if pointer_on_left else POINTER_LENGTH)
