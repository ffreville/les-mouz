extends Node
## Autoload « GameClock » : le temps de jeu et sa vitesse.
##
## Tout ce qui évolue avec le temps (besoins, actions, déplacements) doit
## passer par ici : soit en écoutant `ticked`, soit en multipliant son delta
## par `time_scale`. Ainsi, Pause / x1 / x2 / x3 s'appliquent à tout le jeu.

## Émis à chaque frame non mise en pause, avec les minutes de jeu écoulées.
signal ticked(game_minutes: float)
## Émis quand la minute affichée change.
signal minute_changed(day: int, hour: int, minute: int)
## Émis quand la vitesse change (index dans `settings.speed_multipliers`).
signal speed_changed(speed_index: int)

const SETTINGS_PATH := "res://data/settings/clock_settings.tres"
const MINUTES_PER_DAY := 1440.0

var settings: ClockSettings
## Minutes de jeu écoulées depuis le début du jour 1 à minuit.
var total_minutes: float = 0.0
## Vitesse courante (0 = pause).
var speed_index: int = 1

## Multiplicateur de vitesse courant (0 en pause).
var time_scale: float:
	get:
		return settings.speed_multipliers[speed_index]

var _last_whole_minute: int = -1


# Chargé dès la création pour être disponible avant tout autre _ready().
func _init() -> void:
	settings = load(SETTINGS_PATH)
	reset()


## Revient au jour et à l'heure de départ (nouvelle partie).
func reset() -> void:
	total_minutes = ((settings.start_day - 1) * 24 + settings.start_hour) * 60.0
	_last_whole_minute = -1


## Reprend une partie enregistrée.
func restore(minutes: float) -> void:
	total_minutes = minutes
	_last_whole_minute = int(total_minutes)
	# L'horloge affichée suit, même si la partie reprend en pause.
	minute_changed.emit(get_day(), get_hour(), get_minute())


func _process(delta: float) -> void:
	if time_scale <= 0.0:
		return
	var minutes := delta * settings.game_minutes_per_second * time_scale
	total_minutes += minutes
	ticked.emit(minutes)
	var whole := int(total_minutes)
	if whole != _last_whole_minute:
		_last_whole_minute = whole
		minute_changed.emit(get_day(), get_hour(), get_minute())


## Change la vitesse du jeu (0 = pause).
func set_speed(index: int) -> void:
	index = clampi(index, 0, settings.speed_multipliers.size() - 1)
	if index == speed_index:
		return
	speed_index = index
	speed_changed.emit(speed_index)


func is_paused() -> bool:
	return time_scale <= 0.0


func get_day() -> int:
	return int(total_minutes / MINUTES_PER_DAY) + 1


func get_hour() -> int:
	return int(total_minutes / 60.0) % 24


func get_minute() -> int:
	return int(total_minutes) % 60


## Texte prêt à afficher, par exemple « Jour 2 — 07:45 ».
## « Lun. 1 — 08:02 » : jour de la semaine (le jour 1 est un lundi), numéro du jour, heure.
func format_time() -> String:
	return "%s %d — %02d:%02d" % [JobBoard.SHORT_DAYS[posmod(get_day() - 1, 7)] + ".", get_day(), get_hour(), get_minute()]
