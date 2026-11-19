extends Node
## Autoload « GameMode » : mode de jeu courant (Vivre, Construire, Acheter).
## Construire et Acheter mettent le temps en pause ; Vivre le relance à sa vitesse d'avant.
## Raccourcis : F1 / F2 / F3.
## Garde aussi la hauteur des murs choisie pour le mode Vivre (touche V) ;
## en Construire et Acheter, les murs sont toujours baissés.

enum Mode { LIVE, BUILD, BUY }
## Murs pleins, coupés (ceux qui cachent l'intérieur sont baissés) ou tous baissés.
enum WallMode { FULL, CUTAWAY, LOW }

signal mode_changed(mode: Mode)
signal wall_mode_changed(wall_mode: WallMode)

const NAMES := {Mode.LIVE: "Vivre", Mode.BUILD: "Construire", Mode.BUY: "Acheter"}
const WALL_MODE_NAMES := {WallMode.FULL: "Murs pleins", WallMode.CUTAWAY: "Murs coupés",
		WallMode.LOW: "Murs baissés"}

var mode: Mode = Mode.LIVE
## Hauteur des murs en mode Vivre.
var wall_mode: WallMode = WallMode.CUTAWAY
var _speed_before_edit: int = 1


func is_live() -> bool:
	return mode == Mode.LIVE


## Hauteur des murs à afficher maintenant.
func effective_wall_mode() -> WallMode:
	return wall_mode if is_live() else WallMode.LOW


## Passe aux murs suivants : pleins → coupés → baissés.
func cycle_wall_mode() -> void:
	wall_mode = ((wall_mode + 1) % WallMode.size()) as WallMode
	wall_mode_changed.emit(wall_mode)


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
		KEY_V:
			if is_live():
				cycle_wall_mode()
		_:
			return
	get_viewport().set_input_as_handled()
