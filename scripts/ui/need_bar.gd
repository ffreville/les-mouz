class_name NeedBar
extends HBoxContainer
## Une ligne de besoin : case d'icône, nom, étiquette d'état, valeur et jauge.
## États : normal (≥ 40), « bas », « critique » (hachures + case cerclée de rouge).

const ALERT_ICON := preload("res://assets/icons/white/alerte.svg")

var _icon_box := IconBox.new()
var _name := Label.new()
var _tag := PanelContainer.new()
var _tag_icon := TextureRect.new()
var _tag_label := Label.new()
var _value := Label.new()
var _gauge := NeedGauge.new()
var _color: Color
var _background: Color
var _critical_threshold: float
var _state := ""


func setup(title: String, icon: Texture2D, color: Color, background: Color, critical_threshold: float) -> void:
	_color = color
	_background = background
	_critical_threshold = critical_threshold
	add_theme_constant_override("separation", 10)

	_icon_box.set_icon(icon)
	add_child(_icon_box)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	add_child(column)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	column.add_child(top)
	_name.text = title
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name)
	_build_tag()
	top.add_child(_tag)
	_value.add_theme_font_size_override("font_size", 13)
	_value.custom_minimum_size.x = 24
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_value)

	_gauge.fill_color = color
	column.add_child(_gauge)


func set_value(value: float) -> void:
	_value.text = str(roundi(value))
	_gauge.value = value
	var state := "normal"
	if value < _critical_threshold:
		state = "critique"
	elif value < Palette.SEUIL_BAS:
		state = "bas"
	if state != _state:
		_state = state
		_apply_state()


## Met à jour couleurs et étiquette, seulement quand l'état change.
func _apply_state() -> void:
	var critical := _state == "critique"
	_gauge.striped = critical
	_gauge.track_color = Palette.CRITIQUE_DOUX if critical else Palette.PISTE
	if critical:
		_icon_box.set_colors(_background, Palette.CRITIQUE, 2)
	else:
		_icon_box.set_colors(_background)
	_tag.visible = _state != "normal"
	_tag_icon.visible = critical
	_tag_label.text = _state
	_tag_label.add_theme_color_override("font_color", Color.WHITE if critical else Palette.ACCENT_TEXTE)
	var tag_style := HudTheme.box(Palette.CRITIQUE if critical else Palette.ACCENT_DOUX, 6)
	tag_style.content_margin_left = 6
	tag_style.content_margin_right = 6
	_tag.add_theme_stylebox_override("panel", tag_style)


func _build_tag() -> void:
	_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_tag.add_child(row)
	_tag_icon.texture = ALERT_ICON
	_tag_icon.custom_minimum_size = Vector2(12, 12)
	_tag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tag_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_tag_icon)
	_tag_label.add_theme_font_size_override("font_size", 11)
	row.add_child(_tag_label)
