class_name LoadPanel
extends PanelContainer
## Panneau « Charger une partie » : la liste des sauvegardes et un bouton Retour.
## Utilisé par l'écran d'accueil et par le menu en jeu.

signal closed

var _slots := SlotList.new()


func _ready() -> void:
	custom_minimum_size = Vector2(640, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	var title := Label.new()
	title.text = "CHARGER UNE PARTIE"
	title.theme_type_variation = &"SectionTitle"
	column.add_child(title)
	_slots.custom_minimum_size.y = 420
	_slots.slot_chosen.connect(_on_slot_chosen)
	column.add_child(_slots)
	var back := Button.new()
	back.text = "Retour"
	back.theme_type_variation = &"SecondaryButton"
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void: closed.emit())
	column.add_child(back)
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_slots.refresh()


func _on_slot_chosen(slot_id: String) -> void:
	if not SaveManager.load_slot(slot_id):
		push_warning("Partie illisible : %s" % slot_id)
