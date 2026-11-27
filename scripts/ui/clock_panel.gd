class_name ClockPanel
extends HBoxContainer
## Affiche l'horloge de jeu (jour et heure), puis la saison et le temps qu'il fait (deux icônes et
## la température) ; l'infobulle nomme la saison et le temps et donne les prévisions (voir Weather).

const WEATHER_ICON := "res://assets/icons/ink/%s.svg"
## Icône du temps « nuageux » (le fichier s'appelle `nuages`).
const ICON_NAMES := {&"nuageux": "nuages"}

var _time_label := Label.new()
var _season_icon := TextureRect.new()
var _weather_icon := TextureRect.new()
var _weather_label := Label.new()
var _shown_kind := &""


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_time_label.theme_type_variation = &"BigLabel"
	add_child(_time_label)
	_season_icon = _icon(null)
	_season_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_season_icon)
	_weather_icon = _icon(null)
	_weather_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_weather_icon)
	_weather_label.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_weather_label)
	mouse_filter = Control.MOUSE_FILTER_PASS
	GameClock.minute_changed.connect(_on_minute_changed)
	_refresh()


func _icon(texture: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	_refresh()


func _refresh() -> void:
	_time_label.text = GameClock.format_time()
	var kind := Weather.kind()
	if kind != _shown_kind:
		_shown_kind = kind
		_weather_icon.texture = load(WEATHER_ICON % ICON_NAMES.get(kind, String(kind)))
	_season_icon.texture = load(WEATHER_ICON % Weather.season())
	_weather_label.text = "%d °C" % Weather.temperature_at(GameClock.total_minutes)
	var lines: Array[String] = ["%s · %s" % [Weather.season_text(), Weather.KIND_NAMES[kind]], "Prévisions :"]
	for entry in Weather.forecast():
		lines.append("  %s : %s" % [entry["label"], String(Weather.KIND_NAMES[entry["kind"]]).to_lower()])
	tooltip_text = "\n".join(lines)
	_weather_icon.tooltip_text = tooltip_text
	_season_icon.tooltip_text = tooltip_text
	_weather_label.tooltip_text = tooltip_text
