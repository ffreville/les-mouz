class_name LotOfferCard
extends Button
## Carte d'un terrain à l'emménagement : vignette 16:9, nom, « Terrain vide » ou
## « Maison meublée », taille et prix. Grisée si le budget ne suffit pas.

const COIN := preload("res://assets/sprites/piece_mz.svg")
const WIDTH := 388.0
const HEIGHT := 316.0

var offer: LotOffer


func _init(p_offer: LotOffer) -> void:
	offer = p_offer
	theme_type_variation = &"OptionCard"
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	var chosen := HudTheme.box(Palette.ACCENT_DOUX, 14, Palette.ACCENT, 3, 12)
	add_theme_stylebox_override("normal", HudTheme.box(Color.WHITE, 14, Palette.TRAIT, 2, 12))
	add_theme_stylebox_override("hover", HudTheme.box(Color.WHITE, 14, Palette.ACCENT, 2, 12))
	add_theme_stylebox_override("pressed", chosen)
	add_theme_stylebox_override("hover_pressed", chosen)
	add_theme_stylebox_override("disabled", HudTheme.box(Palette.PAPIER_2, 14, Palette.TRAIT, 2, 12))

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 12
	column.offset_top = 12
	column.offset_right = -12
	column.offset_bottom = -12
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", HudTheme.box(Palette.JARDIN, 10))
	frame.clip_contents = true
	var image := TextureRect.new()
	image.texture = offer.thumbnail
	image.custom_minimum_size = Vector2(WIDTH - 24, (WIDTH - 24) * 9.0 / 16.0)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.add_child(image)
	column.add_child(frame)

	var title_row := HBoxContainer.new()
	var title := Label.new()
	title.text = offer.display_name
	title.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 700))
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var tag := Label.new()
	tag.text = "Maison meublée" if offer.is_furnished() else "Terrain vide"
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Palette.GAIN if offer.is_furnished() else Palette.ENCRE_DOUCE)
	var tag_box := PanelContainer.new()
	tag_box.add_theme_stylebox_override("panel", _tag_style(offer.is_furnished()))
	tag_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_box.add_child(tag)
	title_row.add_child(tag_box)
	column.add_child(title_row)

	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	var size_label := Label.new()
	size_label.text = "%d × %d cases" % [offer.lot.size.x, offer.lot.size.y]
	size_label.theme_type_variation = &"MutedLabel"
	size_label.add_theme_font_size_override("font_size", 13)
	info.add_child(size_label)
	info.add_child(MemberEditor._gap(0))
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.custom_minimum_size = Vector2(16, 16)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(coin)
	var price := Label.new()
	price.text = "Gratuit" if offer.price == 0 else Palette.format_mz(offer.price)
	price.theme_type_variation = &"StrongLabel"
	price.add_theme_font_size_override("font_size", 13)
	info.add_child(price)
	column.add_child(info)
	for control in [frame, image, title_row, title, tag_box, tag, info, size_label, coin, price]:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func _tag_style(furnished: bool) -> StyleBoxFlat:
	var style := HudTheme.box(Palette.GAIN_DOUX if furnished else Palette.PAPIER_2, 8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style
