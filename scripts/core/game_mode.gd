extends Node
## Autoload « GameMode » : mode de jeu courant (Vivre, Construire, Acheter).
## Construire et Acheter mettent le temps en pause ; Vivre le relance à sa vitesse d'avant.
## Raccourcis : F1 / F2 / F3.

enum Mode { LIVE, BUILD, BUY }

signal mode_changed(mode: Mode)

const NAMES := {Mode.LIVE: "Vivre", Mode.BUILD: "Construire", Mode.BUY: "Acheter"}

var mode: Mode = Mode.LIVE
var _speed_before_edit: int = 1


func is_live() -> bool:
	return mode == Mode.LIVE


func set_mode(new_mode: Mode) -> void:
	if new_mode == mode:
		return
	if mode == Mode.LIVE:
		_speed_before_edit = GameClock.speed_index
		GameClock.set_speed(0)
	elif new_mode == Mode.LIVE:
		GameClock.set_speed(_speed_before_edit)
	mode = new_mode
	mode_changed.emit(mode)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F1:
			set_mode(Mode.LIVE)
		KEY_F2:
			set_mode(Mode.BUILD)
		KEY_F3:
			set_mode(Mode.BUY)
		_:
			return
	get_viewport().set_input_as_handled()
