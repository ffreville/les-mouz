class_name ContextMenu
extends PopupMenu
## Menu contextuel générique, ouvert via EventBus.context_menu_requested.
## Chaque option est un dictionnaire { "label": String, "callback": Callable }.

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
		add_item(options[i]["label"], i)
		_callbacks.append(options[i]["callback"])
	position = Vector2i(screen_position)
	reset_size()
	popup()


func _on_id_pressed(id: int) -> void:
	if id >= 0 and id < _callbacks.size():
		_callbacks[id].call()
