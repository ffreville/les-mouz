class_name ContextMenu
extends PopupMenu
## Menu contextuel générique, ouvert via EventBus.context_menu_requested.
## Chaque option : { "label": String, "callback": Callable, "icon": Texture2D (facultatif) }.
## Se ferme d'un clic à côté ou avec Échap.

## Décalage du menu par rapport au clic.
const OFFSET := Vector2(12, -12)
const MIN_WIDTH := 196

var _callbacks: Array[Callable] = []


func _ready() -> void:
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
	min_size.x = MIN_WIDTH
	position = Vector2i(screen_position + OFFSET)
	reset_size()
	popup()


func _on_id_pressed(id: int) -> void:
	if id >= 0 and id < _callbacks.size():
		_callbacks[id].call()
