class_name FencePiece
extends Node2D
## Un segment de clôture en vue trois quarts (voir WallView), dessiné en code et trié comme un mur.
## Segment horizontal : posé sur sa ligne, vu de face. Vertical : vu par la tranche, une bande étroite.
## Avec un portail, le segment devient un battant en bois, ouvert quand un Mouz passe.

const HEIGHT := 22.0
const GATE := Color("#B9875A")
const GATE_DARK := Color("#8A6040")

var definition: FenceDefinition
var horizontal := true
var length := 32.0
var gate := false
var gate_open := false:
	set(value):
		gate_open = value
		queue_redraw()


func _draw() -> void:
	if horizontal:
		_draw_front()
	else:
		_draw_side()


## Segment vu de face : de x = 0 à `length`, posé sur y = 0.
func _draw_front() -> void:
	var outline := Palette.CONTOUR
	if gate:
		_post(Vector2(0, 0))
		_post(Vector2(length - 4, 0))
		if gate_open:
			# Le battant ouvert, vu par la tranche, contre son poteau.
			draw_rect(Rect2(4, -HEIGHT + 2, 3, HEIGHT - 2), GATE_DARK)
			return
		var leaf := Rect2(4, -HEIGHT + 3, length - 8, HEIGHT - 5)
		draw_rect(leaf, GATE)
		for x in range(int(leaf.position.x) + 5, int(leaf.end.x), 5):
			draw_line(Vector2(x, leaf.position.y), Vector2(x, leaf.end.y), GATE_DARK, 1.0)
		draw_line(Vector2(leaf.position.x, leaf.end.y), Vector2(leaf.end.x, leaf.position.y), GATE_DARK, 1.5)
		draw_rect(leaf, outline, false, 1.5)
		return
	match definition.look:
		FenceDefinition.Look.HEDGE:
			var body := Rect2(-2, -HEIGHT + 4, length + 4, HEIGHT - 2)
			draw_rect(body, definition.color)
			for i in 4:
				draw_circle(Vector2(4 + i * 8, -HEIGHT + 6), 6.0, definition.color)
			for i in 6:
				draw_circle(Vector2(3 + i * 6, -HEIGHT * 0.45 + (i % 2) * 4), 1.6, definition.post_color)
			draw_line(Vector2(-2, 2), Vector2(length + 2, 2), definition.post_color, 2.0)
		FenceDefinition.Look.BOARDS:
			draw_rect(Rect2(0, -HEIGHT + 2, length, HEIGHT - 2), definition.color)
			for x in range(6, int(length), 6):
				draw_line(Vector2(x, -HEIGHT + 2), Vector2(x, 0), definition.post_color, 1.0)
			draw_rect(Rect2(0, -HEIGHT + 2, length, HEIGHT - 2), outline, false, 1.5)
			_post(Vector2(0, 0))
			_post(Vector2(length - 4, 0))
		_:
			for rail in [-HEIGHT * 0.72, -HEIGHT * 0.32]:
				draw_rect(Rect2(0, rail, length, 3), definition.post_color)
			for x in range(5, int(length) - 4, 6):
				var top := -HEIGHT + 2.0
				draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x, top + 3), Vector2(x + 2, top),
						Vector2(x + 4, top + 3), Vector2(x + 4, 0)]), definition.color)
				draw_polyline(PackedVector2Array([Vector2(x, 0), Vector2(x, top + 3), Vector2(x + 2, top),
						Vector2(x + 4, top + 3), Vector2(x + 4, 0)]), outline, 1.0)
			_post(Vector2(0, 0))
			_post(Vector2(length - 4, 0))


## Segment vu par la tranche : de y = -length (au fond) à 0 (devant), bande verticale étroite.
func _draw_side() -> void:
	var width := 10.0 if definition.look == FenceDefinition.Look.HEDGE and not gate else 4.0
	var color := GATE if gate else definition.color
	var top := -length - HEIGHT
	if not (gate and gate_open):
		var band := Rect2(-width / 2, top + 2, width, length + HEIGHT - 2)
		draw_rect(band, color)
		if definition.look == FenceDefinition.Look.HEDGE and not gate:
			draw_circle(Vector2(0, top + 4), width / 2, color)
		draw_rect(band, Palette.CONTOUR, false, 1.5)
	elif gate_open:
		draw_rect(Rect2(-6, top + length * 0.5, 12, 3), GATE_DARK)
	if definition.look != FenceDefinition.Look.HEDGE or gate:
		_post(Vector2(-2, -length))
		_post(Vector2(-2, 0))


func _post(bottom_left: Vector2) -> void:
	var post_color := GATE_DARK if gate else definition.post_color
	var rect := Rect2(bottom_left.x, bottom_left.y - HEIGHT, 4, HEIGHT)
	draw_rect(rect, post_color)
	draw_rect(rect, Palette.CONTOUR, false, 1.0)
