class_name DayNight
extends Node2D
## Cycle jour/nuit du monde : une teinte qui suit l'heure du jeu (aube, journée, coucher, nuit)
## et la lumière des objets allumés (lampes, télé, cheminée, ordinateur, cuisinière),
## qui ne se voit vraiment que quand il fait sombre.
## L'interface n'est pas touchée (elle est sur son propre calque).
## En Construire et Acheter, la nuit est moins sombre pour qu'on voie ce qu'on fait.

## Teinte du monde selon l'heure : [heure, couleur], du minuit au minuit suivant.
const SKY := [
	[0.0, Color(0.36, 0.40, 0.62)],
	[5.0, Color(0.36, 0.40, 0.62)],
	[6.5, Color(0.92, 0.78, 0.76)],
	[8.0, Color(1, 1, 1)],
	[18.0, Color(1, 1, 1)],
	[19.5, Color(0.98, 0.78, 0.62)],
	[21.0, Color(0.42, 0.44, 0.66)],
	[22.5, Color(0.36, 0.40, 0.62)],
	[24.0, Color(0.36, 0.40, 0.62)],
]
## Objets qui éclairent quand ils sont en marche : [couleur, rayon en px].
const LIGHTS := {
	&"lampe_chevet": [Color(1.0, 0.86, 0.55), 110.0],
	&"lampe_pied": [Color(1.0, 0.86, 0.55), 150.0],
	&"cheminee": [Color(1.0, 0.6, 0.3), 170.0],
	&"tele": [Color(0.6, 0.75, 1.0), 110.0],
	&"ordinateur": [Color(0.6, 0.75, 1.0), 80.0],
	&"cuisiniere": [Color(1.0, 0.55, 0.3), 60.0],
	&"barbecue": [Color(1.0, 0.55, 0.3), 90.0],
}
## Part de la nuit gardée en Construire et Acheter.
const EDIT_DARKNESS := 0.35
## Rafraîchissement des lumières (secondes réelles).
const LIGHT_REFRESH := 0.2
const TEXTURE_SIZE := 256

var world: World
var _modulate := CanvasModulate.new()
var _lights: Dictionary[SmartObject, PointLight2D] = {}
var _light_texture: Texture2D
var _refresh_timer := 0.0


func setup(p_world: World) -> void:
	world = p_world
	add_child(_modulate)
	_light_texture = _make_light_texture()
	_update_sky()
	_update_lights()


func _process(delta: float) -> void:
	_update_sky()
	_update_energy()
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = LIGHT_REFRESH
		_update_lights()


## Heure de la journée en heures décimales (0 à 24).
static func hour_of_day() -> float:
	return fmod(GameClock.total_minutes, GameClock.MINUTES_PER_DAY) / 60.0


## Couleur du ciel à cette heure.
static func sky_color(hour: float) -> Color:
	for i in range(1, SKY.size()):
		if hour <= SKY[i][0]:
			var t := inverse_lerp(SKY[i - 1][0], SKY[i][0], hour)
			return (SKY[i - 1][1] as Color).lerp(SKY[i][1], t)
	return SKY[-1][1]


## 0 en plein jour, 1 au cœur de la nuit.
static func darkness(color: Color) -> float:
	return clampf((1.0 - color.v) / (1.0 - (SKY[0][1] as Color).v), 0.0, 1.0)


func _update_sky() -> void:
	var color := sky_color(hour_of_day())
	# Le temps assombrit le ciel (nuages, pluie, orage).
	if world != null:
		color *= world.weather.sky_tint()
	if GameMode.mode != GameMode.Mode.LIVE:
		color = Color.WHITE.lerp(color, EDIT_DARKNESS)
	_modulate.color = color


func _update_lights() -> void:
	var night := darkness(_modulate.color)
	for smart_object in _lights.keys():
		if not is_instance_valid(smart_object) or smart_object not in world.smart_objects:
			_lights[smart_object].queue_free()
			_lights.erase(smart_object)
	for smart_object in world.smart_objects:
		var spec: Array = LIGHTS.get(smart_object.definition.id, [])
		# Les lumières des étages cachés (au-dessus de celui qu'on regarde) ne se voient pas.
		var lit := not spec.is_empty() and smart_object.is_active() and night > 0.02 \
				and smart_object.level <= world.view_level
		if not lit:
			if _lights.has(smart_object):
				_lights[smart_object].queue_free()
				_lights.erase(smart_object)
			continue
		var light: PointLight2D = _lights.get(smart_object)
		if light == null:
			light = PointLight2D.new()
			light.texture = _light_texture
			light.blend_mode = Light2D.BLEND_MODE_ADD
			add_child(light)
			_lights[smart_object] = light
		var sprite := smart_object.sprite_rect_local()
		light.position = smart_object.position + (sprite.get_center() if sprite.size != Vector2.ZERO else Vector2.ZERO)
		light.color = spec[0]
		light.texture_scale = spec[1] * 2.0 / TEXTURE_SIZE
	_update_energy()


## Intensité des lumières selon l'obscurité, recalculée à chaque image (fondu au crépuscule).
func _update_energy() -> void:
	var night := darkness(_modulate.color)
	for light in _lights.values():
		# Au carré : presque rien au crépuscule ou en Construire, plein effet en pleine nuit.
		light.energy = 1.4 * night * night


## Halo rond, plein au centre et qui s'efface vers le bord.
func _make_light_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.4, Color(1, 1, 1, 0.55))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	return texture
