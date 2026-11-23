extends Node
## Musique de fond (autoload `Music`) : une piste par écran, en boucle, avec un fondu enchaîné.
##  - menu : écran d'accueil et création de la famille ;
##  - jeu, construction, achat : selon le mode (Vivre, Construire, Acheter).
## Une piste absente est remplacée par celle du jeu : on peut déposer les autres plus tard
## dans `assets/musique/` (menu, construction, achat), sans toucher au code.
## M coupe ou remet la musique.

const FOLDER := "res://assets/musique/%s.mp3"
const FALLBACK := &"jeu"
const MODE_TRACKS := {GameMode.Mode.LIVE: &"jeu", GameMode.Mode.BUILD: &"construction", GameMode.Mode.BUY: &"achat"}
## Volume normal (dB) et durée du fondu (secondes).
const VOLUME_DB := -8.0
const SILENT_DB := -40.0
const FADE := 1.2

var muted := false
var _in_game := false
var _current: AudioStreamPlayer
var _track_path := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameMode.mode_changed.connect(func(_mode) -> void: _refresh())


## L'écran d'accueil ou de création est affiché.
func enter_menu() -> void:
	_in_game = false
	_refresh()


## Une partie commence (la piste suit ensuite le mode de jeu).
func enter_game() -> void:
	_in_game = true
	_refresh()


func toggle_mute() -> void:
	muted = not muted
	if _current != null:
		var tween := create_tween()
		tween.tween_property(_current, "volume_db", SILENT_DB if muted else VOLUME_DB, 0.3)


func _refresh() -> void:
	play(MODE_TRACKS.get(GameMode.mode, FALLBACK) if _in_game else &"menu")


## Passe à la piste `track` (fondu enchaîné), ou continue si c'est déjà la même musique.
func play(track: StringName) -> void:
	var path := FOLDER % track
	if not ResourceLoader.exists(path):
		path = FOLDER % FALLBACK
	if path == _track_path or not ResourceLoader.exists(path):
		return
	_track_path = path
	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3:
		stream.loop = true
	var previous := _current
	_current = AudioStreamPlayer.new()
	_current.stream = stream
	_current.volume_db = SILENT_DB
	add_child(_current)
	_current.play()
	var tween := create_tween().set_parallel(true)
	if not muted:
		tween.tween_property(_current, "volume_db", VOLUME_DB, FADE)
	if previous != null:
		tween.tween_property(previous, "volume_db", SILENT_DB, FADE)
		tween.chain().tween_callback(previous.queue_free)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_M:
		toggle_mute()
