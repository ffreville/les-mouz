class_name CharacterSwitcher
extends HBoxContainer
## Un bouton par personnage pour choisir celui que l'on contrôle.
## Raccourci : Tab passe au personnage suivant.

var _world: World
var _buttons: Dictionary[Node, Button] = {}


func _ready() -> void:
	EventBus.character_selected.connect(_on_character_selected)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _world == null or key == null or not key.pressed or key.echo or key.keycode != KEY_TAB:
		return
	var characters := _world.characters
	var index := characters.find(_world.selection.selected)
	_world.selection.select(characters[(index + 1) % characters.size()])
	get_viewport().set_input_as_handled()


func _on_character_selected(character: Node) -> void:
	if _world == null:
		_build(character.world)
	for other in _buttons:
		_buttons[other].set_pressed_no_signal(other == character)


func _build(world: World) -> void:
	_world = world
	var group := ButtonGroup.new()
	for character in world.characters:
		var button := Button.new()
		button.text = character.get_display_name()
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_color_override("font_pressed_color", character.profile.color.lightened(0.3))
		button.pressed.connect(world.selection.select.bind(character))
		add_child(button)
		_buttons[character] = button
