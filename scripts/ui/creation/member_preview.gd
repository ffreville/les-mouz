class_name MemberPreview
extends PanelContainer
## Aperçu du membre choisi : grand portrait, prénom, « Nom · Sexe · Âge »,
## sprite ×2 qui marche sur du parquet, et les 4 directions à taille réelle.

const PARQUET := preload("res://assets/floors/parquet.svg")
const SIDE_DIRECTIONS: Array[StringName] = [&"bas", &"gauche", &"haut", &"droite"]

var _portrait := MouzPortrait.new(184)
var _name := Label.new()
var _details := Label.new()
var _walker := BodyPreview.new(2.0)
var _small: Array[BodyPreview] = []


func _ready() -> void:
	custom_minimum_size.x = 360
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	_portrait.background = Palette.PAPIER_2
	_portrait.ring_width = 3.0
	_portrait.ring_color = Palette.TRAIT
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_portrait)
	_name.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	_name.add_theme_font_size_override("font_size", 28)
	_details.theme_type_variation = &"MutedLabel"
	_details.add_theme_font_size_override("font_size", 13)
	for label in [_name, _details]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var floor_box := PanelContainer.new()
	floor_box.add_theme_stylebox_override("panel", HudTheme.box(Palette.PAPIER_2, 12))
	floor_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor_box.clip_contents = true
	var parquet := TextureRect.new()
	parquet.texture = PARQUET
	parquet.stretch_mode = TextureRect.STRETCH_TILE
	parquet.modulate = Color(1, 1, 1, 0.75)
	floor_box.add_child(parquet)
	var walker_box := VBoxContainer.new()
	walker_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_walker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	walker_box.add_child(_walker)
	var caption := Label.new()
	caption.text = "Tourne et marche · ×2"
	caption.theme_type_variation = &"MutedLabel"
	caption.add_theme_font_size_override("font_size", 11)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	walker_box.add_child(caption)
	floor_box.add_child(walker_box)
	row.add_child(floor_box)

	var sizes := PanelContainer.new()
	sizes.add_theme_stylebox_override("panel", HudTheme.box(Palette.PAPIER_2, 12, Color.TRANSPARENT, 0, 8))
	var sizes_column := VBoxContainer.new()
	sizes_column.alignment = BoxContainer.ALIGNMENT_CENTER
	var directions := HBoxContainer.new()
	directions.add_theme_constant_override("separation", 0)
	for direction in SIDE_DIRECTIONS:
		var preview := BodyPreview.new(1.0, direction)
		_small.append(preview)
		directions.add_child(preview)
	sizes_column.add_child(directions)
	var real_size := Label.new()
	real_size.text = "taille réelle"
	real_size.theme_type_variation = &"MutedLabel"
	real_size.add_theme_font_size_override("font_size", 11)
	real_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sizes_column.add_child(real_size)
	sizes.add_child(sizes_column)
	row.add_child(sizes)


func show_member(member: Dictionary, family_name: String) -> void:
	var look: MouzAppearance = member["appearance"]
	_portrait.appearance = look
	_portrait.queue_redraw()
	var first_name := String(member["first_name"]).strip_edges()
	_name.text = first_name if first_name != "" else "Sans prénom"
	_details.text = "%s · %s" % [family_name if family_name.strip_edges() != "" else "Sans nom", look.describe()]
	_walker.appearance = look
	for preview in _small:
		preview.appearance = look
