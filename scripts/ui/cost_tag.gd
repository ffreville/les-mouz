class_name CostTag
extends PanelContainer
## Étiquette de coût qui suit le pointeur pendant un tracé ou un placement :
## « 4 murs · 240 Mz », en rouge avec « Il manque 450 Mz » si l'argent ne suffit pas.

const COIN := preload("res://assets/sprites/piece_mz.svg")
const OFFSET := Vector2(14, 14)

var _label := Label.new()
var _missing := Label.new()
var _style := HudTheme.box(Color.WHITE, 10, Palette.CONTOUR, 2)


func _ready() -> void:
	visible = false
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style.content_margin_left = 10
	_style.content_margin_right = 10
	_style.content_margin_top = 5
	_style.content_margin_bottom = 5
	_style.shadow_color = Palette.OMBRE
	_style.shadow_size = 1
	_style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", _style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.custom_minimum_size = Vector2(14, 14)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coin)
	_label.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
	_label.add_theme_font_size_override("font_size", 13)
	row.add_child(_label)
	_missing.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
	_missing.add_theme_font_size_override("font_size", 11)
	_missing.add_theme_color_override("font_color", Palette.CRITIQUE)
	column.add_child(_missing)
	EventBus.cost_preview_changed.connect(_on_cost_preview_changed)


func _process(_delta: float) -> void:
	if visible:
		global_position = get_viewport().get_mouse_position() + OFFSET


## `cost` positif = dépense, négatif = remboursement, texte vide = masquer.
func _on_cost_preview_changed(text: String, cost: int) -> void:
	visible = text != ""
	if not visible:
		return
	var price := ("+" + Palette.format_mz(-cost)) if cost < 0 else Palette.format_mz(cost)
	_label.text = text if cost == 0 else "%s · %s" % [text, price]
	var short := cost > Wallet.funds
	var color := Palette.CRITIQUE if short else Palette.ENCRE
	if cost < 0:
		color = Palette.GAIN
	_label.add_theme_color_override("font_color", color)
	_style.border_color = Palette.CRITIQUE if short else Palette.CONTOUR
	_missing.visible = short
	_missing.text = "Il manque %s" % Palette.format_mz(cost - Wallet.funds)
	reset_size()
