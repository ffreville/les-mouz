class_name LoadPanel
extends VBoxContainer
## Écran « Charger une partie » : barre de titre (Retour, titre, nombre de parties)
## puis la liste des sauvegardes dans un panneau de 940 px.
## Utilisé par l'écran d'accueil et par le menu en jeu.

signal closed
signal new_game_requested

const WIDTH := 940.0
const LIST_HEIGHT := 520.0

var _slots := SlotList.new()
var _count := Label.new()


func _ready() -> void:
	custom_minimum_size.x = WIDTH
	add_theme_constant_override("separation", 10)
	var bar := PanelContainer.new()
	var style := HudTheme.box(Palette.PAPIER, 14, Palette.TRAIT, 2)
	style.content_margin_left = 8
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", style)
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)
	var back := Button.new()
	back.text = "Retour"
	back.theme_type_variation = &"SecondaryButton"
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 13)
	back.custom_minimum_size.y = 36
	for state in ["normal", "hover", "pressed"]:
		back.add_theme_stylebox_override(state, SlotList._compact(Color.WHITE, Palette.ACCENT if state == "hover" else Palette.TRAIT))
	back.pressed.connect(closed.emit)
	row.add_child(back)
	var title := Label.new()
	title.text = "Charger une partie"
	title.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	_count.theme_type_variation = &"MutedLabel"
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_count)

	var panel := PanelContainer.new()
	add_child(panel)
	_slots.custom_minimum_size.y = LIST_HEIGHT
	_slots.slot_chosen.connect(_on_slot_chosen)
	_slots.new_game_requested.connect(new_game_requested.emit)
	panel.add_child(_slots)
	SaveManager.slots_changed.connect(_update_count)
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_slots.refresh()
		_update_count()


func _update_count() -> void:
	var count := _slots.count()
	_count.text = "Aucune partie" if count == 0 else ("1 partie" if count == 1 else "%d parties" % count)


func _on_slot_chosen(slot_id: String) -> void:
	if not SaveManager.load_slot(slot_id):
		push_warning("Partie illisible : %s" % slot_id)
