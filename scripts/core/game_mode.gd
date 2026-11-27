extends Node
## Autoload « GameMode » : mode de jeu courant (Vivre, Construire, Acheter).
## Construire et Acheter mettent le temps en pause ; Vivre le relance à sa vitesse d'avant.
## Raccourcis : F1 / F2 / F3.
## Garde aussi la vue de la maison choisie pour le mode Vivre : la hauteur des murs (touche V) et
## le toit affiché ou non (touche T, boutons à côté du sélecteur d'étage). Avec le toit, les murs
## sont pleins. En Construire et Acheter, les murs sont toujours baissés et le toit caché.

enum Mode { LIVE, BUILD, BUY }
## Murs pleins, coupés (ceux qui cachent l'intérieur sont baissés) ou tous baissés.
enum WallMode { FULL, CUTAWAY, LOW }

signal mode_changed(mode: Mode)
signal wall_mode_changed(wall_mode: WallMode)
## Le toit est affiché ou masqué.
signal roof_changed(shown: bool)

const NAMES := {Mode.LIVE: "Vivre", Mode.BUILD: "Construire", Mode.BUY: "Acheter"}
const WALL_MODE_NAMES := {WallMode.FULL: "Murs pleins", WallMode.CUTAWAY: "Murs coupés",
		WallMode.LOW: "Murs baissés"}

var mode: Mode = Mode.LIVE
## Hauteur des murs en mode Vivre.
var wall_mode: WallMode = WallMode.CUTAWAY
## Toit affiché en mode Vivre.
var show_roof := false
var _speed_before_edit: int = 1


func is_live() -> bool:
	return mode == Mode.LIVE


## Hauteur des murs à afficher maintenant.
func effective_wall_mode() -> WallMode:
	if not is_live():
		return WallMode.LOW
	return WallMode.FULL if show_roof else wall_mode


## Vrai quand on voit les toits (mode Vivre, toit affiché).
func shows_roofs() -> bool:
	return is_live() and show_roof


## Passe aux murs suivants : pleins → coupés → baissés. Si le toit était affiché, il se masque
## (on veut voir dedans).
func cycle_wall_mode() -> void:
	if show_roof:
		set_show_roof(false)
	else:
		wall_mode = ((wall_mode + 1) % WallMode.size()) as WallMode
	wall_mode_changed.emit(wall_mode)


## Affiche ou masque le toit.
func set_show_roof(value: bool) -> void:
	if value == show_roof:
		return
	show_roof = value
	roof_changed.emit(show_roof)


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
		KEY_T:
			if is_live():
				set_show_roof(not show_roof)
		_:
			return
	get_viewport().set_input_as_handled()
