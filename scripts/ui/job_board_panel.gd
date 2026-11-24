class_name JobBoardPanel
extends Control
## Les petites annonces, ouvertes depuis le téléphone (clic sur son Mouz) ou l'ordinateur.
## Une carte par annonce : métier, horaires, phrase, salaire, « Accepter ».
## En haut, le métier actuel du Mouz avec « Démissionner ». Échap ou clic à côté : fermer.

const WIDTH := 600.0
const COIN := preload("res://assets/sprites/piece_mz.svg")
const CLOSE_ICON := preload("res://assets/icons/white/fermer.svg")
const VEIL := Color(0.169, 0.141, 0.251, 0.35)
## Hauteur maximale de la liste : au-delà, elle défile.
const MAX_LIST_HEIGHT := 470.0

var _character: Character
var _source: StringName
var _title := Label.new()
var _subtitle := Label.new()
var _list := VBoxContainer.new()
var _scroll := ScrollContainer.new()


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = VEIL
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.gui_input.connect(_on_veil_input)
	add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size.x = WIDTH
	center.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	header.add_child(titles)
	_title.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	_title.add_theme_font_size_override("font_size", 24)
	titles.add_child(_title)
	_subtitle.theme_type_variation = &"MutedLabel"
	titles.add_child(_subtitle)
	var close := Button.new()
	close.theme_type_variation = &"IconButton"
	close.icon = CLOSE_ICON
	close.expand_icon = true
	close.custom_minimum_size = Vector2(32, 32)
	close.focus_mode = Control.FOCUS_NONE
	close.tooltip_text = "Fermer (Échap)"
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(hide)
	header.add_child(close)

	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.add_child(_list)
	column.add_child(_scroll)
	EventBus.job_board_requested.connect(open)


## Ouvre les annonces du jour pour ce Mouz, lues sur `source` (&"telephone" ou &"ordinateur").
func open(character: Node, source: StringName) -> void:
	_character = character
	_source = source
	_title.text = "Petites annonces"
	_subtitle.text = "%s · %s · %d annonces aujourd'hui" % [
		"Sur le téléphone de %s" % character.get_display_name() if source == &"telephone" else "Sur l'ordinateur",
		JobBoard.DAY_NAMES[JobBoard.weekday(GameClock.get_day())].capitalize(),
		JobBoard.OFFERS.get(source, 3)]
	_rebuild()
	visible = true


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	var job: JobDefinition = _character.job.definition
	if job != null:
		_list.add_child(_section("TON MÉTIER"))
		_list.add_child(_job_card(job, true))
		_list.add_child(_section("ANNONCES DU JOUR"))
	var age: StringName = _character.profile.appearance.age if _character.profile.appearance != null else &"adulte"
	for offer in JobBoard.offers(GameClock.get_day(), _source):
		if offer != job:
			_list.add_child(_job_card(offer, false, JobBoard.problem(offer, age)))
	if _source == &"telephone":
		var hint := Label.new()
		hint.text = "Plus d'annonces sur l'ordinateur (« Lire les petites annonces »)."
		hint.theme_type_variation = &"MutedLabel"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(hint)
	_fit_height.call_deferred()


## La liste prend la hauteur de son contenu, sans dépasser MAX_LIST_HEIGHT.
func _fit_height() -> void:
	_scroll.custom_minimum_size.y = minf(_list.get_combined_minimum_size().y, MAX_LIST_HEIGHT)


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"SectionTitle"
	return label


func _job_card(job: JobDefinition, current: bool, problem := "") -> Control:
	var card := PanelContainer.new()
	var style := HudTheme.box(Color.WHITE if current else Palette.PAPIER_2, Palette.RAYON_ELEMENT,
			Palette.ACCENT if current else Color.TRANSPARENT, 2 if current else 0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon := IconBox.new(40.0, 24.0, 10)
	icon.set_icon(job.icon)
	icon.set_colors(Palette.PAPIER if current else Color.WHITE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	row.add_child(texts)
	var title := Label.new()
	title.text = job.display_name
	title.theme_type_variation = &"StrongLabel"
	texts.add_child(title)
	var schedule := Label.new()
	schedule.text = job.schedule_text()
	schedule.theme_type_variation = &"MutedLabel"
	texts.add_child(schedule)
	var description := Label.new()
	description.text = job.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 12)
	texts.add_child(description)

	var side := VBoxContainer.new()
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.add_theme_constant_override("separation", 6)
	row.add_child(side)
	var pay := HBoxContainer.new()
	pay.alignment = BoxContainer.ALIGNMENT_END
	pay.add_theme_constant_override("separation", 4)
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.custom_minimum_size = Vector2(16, 16)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pay.add_child(coin)
	var amount := Label.new()
	amount.text = "%s / jour" % Palette.format_mz(job.salary)
	amount.theme_type_variation = &"StrongLabel"
	pay.add_child(amount)
	side.add_child(pay)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(150, 36)
	if current:
		button.text = "Démissionner"
		button.theme_type_variation = &"DangerButton"
		var resign := func() -> void:
			_character.job.quit()
			_rebuild()
		button.pressed.connect(resign)
	elif problem != "":
		button.text = problem
		button.theme_type_variation = &"SecondaryButton"
		button.disabled = true
	else:
		button.text = "Changer de métier" if _character.job.definition != null else "Accepter"
		button.theme_type_variation = &"PrimaryButton"
		var accept := func() -> void:
			_character.job.take(job)
			hide()
		button.pressed.connect(accept)
	side.add_child(button)
	return card


func _on_veil_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
