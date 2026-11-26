class_name WeatherGround
extends Node2D
## Le sol selon la saison et la neige (rez-de-chaussée, juste au-dessus des sols et de la piscine) :
##  - l'herbe change de teinte avec la saison (sèche l'été, rousse l'automne, terne l'hiver) ; si
##    Claude Design a dessiné `assets/floors/herbe_<saison>.svg`, la tuile remplace la teinte ;
##  - la neige couvre tout ce qui est dehors (herbe, terrasse, allées), sauf l'eau, d'autant plus
##    qu'elle est épaisse ; tuile `assets/floors/neige.svg` si elle existe.

const GRASS_TINT := {&"ete": Color("#E8D36A", 0.18), &"automne": Color("#D08A3A", 0.26), &"hiver": Color("#C9D3DC", 0.35)}
const SNOW := Color("#F6F9FC")
const SNOW_SHADE := Color("#DCE6F0")
const GRASS_PATH := "res://assets/floors/herbe_%s.svg"
const SNOW_PATH := "res://assets/floors/neige.svg"

var _world: World
var _season := &""
var _snow := 0.0


func render(world: World) -> void:
	if _world == null:
		_world = world
		world.weather.changed.connect(_on_weather_changed)
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_season = Weather.season()
	_snow = world.weather.snow
	# Tuiles chargées ici, avant d'être dessinées (sinon blanches à la première image).
	MouzLayers.texture(GRASS_PATH % _season)
	MouzLayers.texture(SNOW_PATH)
	queue_redraw()


func _on_weather_changed() -> void:
	render(_world)


func _draw() -> void:
	if _world == null:
		return
	var lot := _world.lot
	var cs := float(lot.cell_size)
	var area := Rect2(Vector2.ZERO, Vector2(lot.size) * cs)
	var outside := area.grow(FloorView.OUTSIDE_MARGIN)
	var grass := MouzLayers.texture(GRASS_PATH % _season)
	var tint: Color = GRASS_TINT.get(_season, Color.TRANSPARENT)
	var snow_texture := MouzLayers.texture(SNOW_PATH)
	var snow_alpha := clampf(_snow * 1.4, 0.0, 0.95)
	# Autour du terrain : quatre bandes d'herbe.
	var bands := [Rect2(outside.position, Vector2(outside.size.x, -outside.position.y)),
			Rect2(Vector2(outside.position.x, area.end.y), Vector2(outside.size.x, outside.end.y - area.end.y)),
			Rect2(Vector2(outside.position.x, 0), Vector2(-outside.position.x, area.size.y)),
			Rect2(Vector2(area.end.x, 0), Vector2(outside.end.x - area.end.x, area.size.y))]
	for band in bands:
		_paint(band, grass, tint, true)
		_paint_snow(band, snow_texture, snow_alpha)
	var weather := _world.weather
	for y in lot.size.y:
		for x in lot.size.x:
			var cell := Vector2i(x, y)
			if lot.pool.has(cell) or not weather.is_outdoor_cell(cell):
				continue
			var rect := Rect2(Vector2(cell) * cs, Vector2(cs, cs))
			if not lot.floors.has(cell):
				_paint(rect, grass, tint, false)
			_paint_snow(rect, snow_texture, snow_alpha)


func _paint(rect: Rect2, texture: Texture2D, tint: Color, _band: bool) -> void:
	if texture != null:
		draw_texture_rect(texture, rect, true)
	elif tint.a > 0.0:
		draw_rect(rect, tint)


func _paint_snow(rect: Rect2, texture: Texture2D, alpha: float) -> void:
	if alpha <= 0.0:
		return
	if texture != null:
		draw_texture_rect(texture, rect, true, Color(1, 1, 1, alpha))
		return
	draw_rect(rect, Color(SNOW, alpha))
	# Quelques creux bleutés, toujours aux mêmes endroits, pour que la neige ne soit pas plate.
	if rect.size.x <= 64.0 and alpha > 0.3:
		var seed := int(rect.position.x * 7.0 + rect.position.y * 13.0)
		var spot := Vector2(posmod(seed, 23) + 4, posmod(seed / 3, 21) + 6)
		draw_circle(rect.position + spot, 3.0, Color(SNOW_SHADE, alpha * 0.8))
