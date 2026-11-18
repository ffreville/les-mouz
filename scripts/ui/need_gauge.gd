class_name NeedGauge
extends Control
## Jauge arrondie dessinée à la main : remplissage simple, hachuré (état critique)
## ou partant du centre (relation de -100 à +100).

const BAR_HEIGHT := 10.0
const STRIPE := 5.0
const STRIPE_GAP := 3.0
const STRIPE_COLOR := Color(1, 1, 1, 0.5)
const CENTER_MARK := Vector2(2, 16)

var min_value: float = 0.0
var max_value: float = 100.0
var value: float = 0.0:
	set(v):
		value = v
		queue_redraw()
var fill_color: Color = Palette.ACCENT:
	set(v):
		fill_color = v
		queue_redraw()
var track_color: Color = Palette.PISTE:
	set(v):
		track_color = v
		queue_redraw()
## Bandes blanches en diagonale sur le remplissage.
var striped: bool = false:
	set(v):
		striped = v
		queue_redraw()
## Remplit depuis le centre (valeurs négatives vers la gauche).
var from_center: bool = false

var _track_style := HudTheme.box(Color.WHITE, int(BAR_HEIGHT / 2))
var _fill_style := HudTheme.box(Color.WHITE, int(BAR_HEIGHT / 2))


func _init() -> void:
	custom_minimum_size.y = BAR_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var track := Rect2(0, (size.y - BAR_HEIGHT) / 2, size.x, BAR_HEIGHT)
	_track_style.bg_color = track_color
	draw_style_box(_track_style, track)
	var fill := _fill_rect(track)
	if fill.size.x >= 1.0:
		_fill_style.bg_color = fill_color
		draw_style_box(_fill_style, fill)
		if striped:
			_draw_stripes(fill)
	if from_center:
		var mark := Rect2(Vector2(track.get_center().x - CENTER_MARK.x / 2, track.get_center().y - CENTER_MARK.y / 2), CENTER_MARK)
		draw_rect(mark, Palette.CONTOUR)


func _fill_rect(track: Rect2) -> Rect2:
	if from_center:
		var half := track.size.x / 2
		var width := clampf(value / max_value, -1.0, 1.0) * half
		var start := track.position.x + half + minf(width, 0.0)
		return Rect2(start, track.position.y, absf(width), track.size.y)
	var ratio := clampf((value - min_value) / (max_value - min_value), 0.0, 1.0)
	return Rect2(track.position, Vector2(track.size.x * ratio, track.size.y))


## Bandes à 135°, découpées pour rester dans le remplissage.
func _draw_stripes(fill: Rect2) -> void:
	var clip := PackedVector2Array([fill.position, Vector2(fill.end.x, fill.position.y), fill.end,
			Vector2(fill.position.x, fill.end.y)])
	var h := fill.size.y
	var x := fill.position.x - h
	while x < fill.end.x:
		var stripe := PackedVector2Array([Vector2(x, fill.end.y), Vector2(x + STRIPE, fill.end.y),
				Vector2(x + STRIPE + h, fill.position.y), Vector2(x + h, fill.position.y)])
		for piece in Geometry2D.intersect_polygons(stripe, clip):
			draw_colored_polygon(piece, STRIPE_COLOR)
		x += STRIPE + STRIPE_GAP
