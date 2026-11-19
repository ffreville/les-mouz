class_name Toast
extends PanelContainer
## Message en bas au centre de l'écran (« Partie enregistrée »), qui disparaît tout seul.
##  - réussite : rond vert avec une coche, 2 s ;
##  - échec : rond rouge avec une alerte, la raison, un bouton « Réessayer », 6 s ;
##  - information : texte seul, 2 s.
## Il arrive en glissant de 8 px vers le haut.

enum Kind { INFO, SUCCESS, FAILURE }

const DURATION := 2.0
const FAILURE_DURATION := 6.0
const BOTTOM_GAP := 24.0
const SLIDE := 8.0
const CHECK := preload("res://assets/icons/white/valider.svg")
const ALERT := preload("res://assets/icons/white/alerte.svg")

var _badge := PanelContainer.new()
var _badge_icon := TextureRect.new()
var _label := Label.new()
var _detail := Label.new()
var _retry := Button.new()
var _retry_action := Callable()
var _tween: Tween


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := HudTheme.box(Color.WHITE, 14, Palette.TRAIT, 2)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Palette.OMBRE
	style.shadow_size = 1
	style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	_badge.custom_minimum_size = Vector2(24, 24)
	_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_badge_icon.custom_minimum_size = Vector2(14, 14)
	_badge_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_badge_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_badge.add_child(_badge_icon)
	row.add_child(_badge)
	_label.theme_type_variation = &"StrongLabel"
	_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_label)
	_detail.theme_type_variation = &"MutedLabel"
	_detail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_detail)
	_retry.text = "Réessayer"
	_retry.theme_type_variation = &"SecondaryButton"
	_retry.focus_mode = Control.FOCUS_NONE
	_retry.add_theme_font_size_override("font_size", 13)
	_retry.pressed.connect(_on_retry)
	row.add_child(_retry)


func show_message(text: String, kind: Kind = Kind.INFO, detail := "", retry := Callable()) -> void:
	_label.text = text
	_detail.text = detail
	_detail.visible = detail != ""
	_retry_action = retry
	_retry.visible = retry.is_valid()
	# Un bouton « Réessayer » doit pouvoir être cliqué.
	mouse_filter = Control.MOUSE_FILTER_STOP if retry.is_valid() else Control.MOUSE_FILTER_IGNORE
	_badge.visible = kind != Kind.INFO
	if kind != Kind.INFO:
		_badge.add_theme_stylebox_override("panel", HudTheme.box(Palette.GAIN if kind == Kind.SUCCESS else Palette.CRITIQUE, 12))
		_badge_icon.texture = CHECK if kind == Kind.SUCCESS else ALERT
	var border := Palette.CRITIQUE if kind == Kind.FAILURE else Palette.TRAIT
	(get_theme_stylebox("panel") as StyleBoxFlat).border_color = border
	reset_size()
	var screen := get_viewport_rect().size
	var resting := Vector2((screen.x - size.x) / 2, screen.y - size.y - BOTTOM_GAP)
	position = resting + Vector2(0, SLIDE)
	modulate.a = 0.0
	visible = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", resting, 0.18)
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.set_parallel(false)
	_tween.tween_interval(FAILURE_DURATION if kind == Kind.FAILURE else DURATION)
	_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(hide)


func _on_retry() -> void:
	hide()
	if _retry_action.is_valid():
		_retry_action.call()
