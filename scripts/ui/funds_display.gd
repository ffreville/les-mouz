class_name FundsDisplay
extends PanelContainer
## Solde du foyer dans la barre du haut : pièce + montant.
## Une pastille « −1 200 Mz » ou « +900 Mz » apparaît dessous à chaque variation,
## et le montant défile vers sa nouvelle valeur.

const COIN := preload("res://assets/sprites/piece_mz.svg")
const ROLL_TIME := 0.4
const PILL_TIME := 1.2
const PILL_RISE := 12.0

var _amount := Label.new()
var _shown_funds: float = 0.0
var _pill := PanelContainer.new()
var _pill_label := Label.new()
var _roll: Tween
var _pill_tween: Tween


func _ready() -> void:
	var style := HudTheme.box(Palette.PAPIER_2, 12)
	style.content_margin_left = 10
	style.content_margin_right = 14
	custom_minimum_size.y = 36
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.custom_minimum_size = Vector2(20, 20)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coin)
	_amount.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 700))
	_amount.add_theme_font_size_override("font_size", 20)
	_amount.add_theme_color_override("font_color", Palette.ENCRE)
	row.add_child(_amount)

	# La pastille de variation flotte sous la capsule, hors de la mise en page.
	_pill.top_level = true
	_pill.visible = false
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill_label.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
	_pill_label.add_theme_font_size_override("font_size", 13)
	_pill.add_child(_pill_label)
	add_child(_pill)

	_shown_funds = Wallet.funds
	_amount.text = Palette.format_mz(Wallet.funds)
	EventBus.money_changed.connect(_on_money_changed)


func _on_money_changed(funds: int, delta: int) -> void:
	if _roll != null:
		_roll.kill()
	_roll = create_tween()
	_roll.tween_method(_set_shown_funds, _shown_funds, float(funds), ROLL_TIME)
	_show_pill(delta)


func _set_shown_funds(value: float) -> void:
	_shown_funds = value
	_amount.text = Palette.format_mz(roundi(value))


func _show_pill(delta: int) -> void:
	var gain := delta > 0
	_pill_label.text = ("+" if gain else "") + Palette.format_mz(delta)
	_pill_label.add_theme_color_override("font_color", Palette.GAIN if gain else Palette.CRITIQUE)
	var style := HudTheme.box(Palette.GAIN_DOUX if gain else Palette.CRITIQUE_DOUX, 8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	style.shadow_color = Palette.OMBRE
	style.shadow_size = 1
	style.shadow_offset = Vector2(0, 4)
	_pill.add_theme_stylebox_override("panel", style)
	_pill.reset_size()
	# Alignée à droite, 8 px sous la capsule.
	var start := global_position + Vector2(size.x - _pill.size.x, size.y + 8)
	_pill.global_position = start
	_pill.modulate.a = 1.0
	_pill.visible = true
	if _pill_tween != null:
		_pill_tween.kill()
	_pill_tween = create_tween().set_parallel()
	_pill_tween.tween_property(_pill, "global_position:y", start.y - PILL_RISE, PILL_TIME)
	_pill_tween.tween_property(_pill, "modulate:a", 0.0, PILL_TIME).set_ease(Tween.EASE_IN)
	_pill_tween.chain().tween_callback(_pill.hide)
