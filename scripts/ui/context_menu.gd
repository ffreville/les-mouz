class_name ContextMenu
extends PopupMenu
## Menu contextuel générique, ouvert via EventBus.context_menu_requested.
## Chaque option : { "label": String, "callback": Callable, "icon": Texture2D (facultatif) }.
## Il s'ouvre à 12 px du clic, avec une pointe tournée vers lui ; il passe à gauche
## s'il manque de place à droite. Se ferme d'un clic à côté ou avec Échap.

## Distance entre le clic et l'extrémité de la pointe.
const GAP := 12.0
## Hauteur visée pour la pointe, depuis le haut du menu (au niveau de l'en-tête).
const POINTER_ANCHOR := 24.0
## Marge minimale avec les bords de l'écran.
const SCREEN_MARGIN := 8.0
const MIN_WIDTH := 196

var _callbacks: Array[Callable] = []
var _panel: PointerStyleBox


func _ready() -> void:
	# Le coin laissé libre par la pointe doit rester transparent.
	transparent_bg = true
	EventBus.context_menu_requested.connect(_open)
	id_pressed.connect(_on_id_pressed)


func _open(title: String, options: Array, screen_position: Vector2) -> void:
	clear()
	_callbacks.clear()
	add_separator(title)
	if options.is_empty():
		add_item("(aucune action)")
		set_item_disabled(item_count - 1, true)
	for i in options.size():
		var icon: Texture2D = options[i].get("icon")
		if icon != null:
			add_icon_item(icon, options[i]["label"], i)
		else:
			add_item(options[i]["label"], i)
		_callbacks.append(options[i]["callback"])
	_ensure_panel()
	min_size.x = MIN_WIDTH + int(PointerStyleBox.POINTER_LENGTH)
	reset_size()
	_place(screen_position)
	popup()


## Place le menu à côté du clic et oriente la pointe vers lui.
func _place(target: Vector2) -> void:
	var screen := get_parent().get_viewport().get_visible_rect().size
	var width := float(size.x)
	var height := float(size.y)
	var fits_right := target.x + GAP + width <= screen.x - SCREEN_MARGIN
	_panel.pointer_on_left = fits_right
	var x := target.x + GAP if fits_right else target.x - GAP - width
	var y := clampf(target.y - POINTER_ANCHOR, SCREEN_MARGIN, screen.y - height - SCREEN_MARGIN)
	_panel.pointer_y = target.y - y
	position = Vector2i(Vector2(x, y).round())


## Remplace le panneau du thème par sa version à pointe (une seule fois).
func _ensure_panel() -> void:
	if _panel != null:
		return
	var base := get_theme_stylebox("panel") as StyleBoxFlat
	_panel = PointerStyleBox.new(base.duplicate() if base != null else null)
	add_theme_stylebox_override("panel", _panel)


func _on_id_pressed(id: int) -> void:
	if id >= 0 and id < _callbacks.size():
		_callbacks[id].call()
