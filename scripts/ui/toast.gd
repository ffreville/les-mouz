class_name Toast
extends PanelContainer
## Petit message en bas de l'écran (« Partie enregistrée »), qui disparaît tout seul.

const DURATION := 2.0

var _label := Label.new()
var _tween: Tween


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := HudTheme.box(Palette.CONTOUR, 12, Color.TRANSPARENT, 0, 10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	add_theme_stylebox_override("panel", style)
	_label.add_theme_color_override("font_color", Palette.PAPIER)
	_label.theme_type_variation = &"StrongLabel"
	add_child(_label)


func show_message(text: String) -> void:
	_label.text = text
	reset_size()
	var screen := get_viewport_rect().size
	position = Vector2((screen.x - size.x) / 2, screen.y - size.y - 28)
	modulate.a = 1.0
	visible = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(DURATION)
	_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(hide)
