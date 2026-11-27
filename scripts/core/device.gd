extends Node
## Autoload « Device » : joue-t-on sur un téléphone ou une tablette (écran tactile) ?
##  - Détection : navigateur Android ou iOS, ou plateforme mobile ; pour essayer sur ordinateur,
##    `?mobile=1` dans l'adresse de la version web, ou `-- --mobile` en ligne de commande.
##  - Sur mobile, pendant la partie, l'interface est calculée pour un écran de MOBILE_HEIGHT unités
##    de haut au lieu de 720 : elle reste lisible au lieu de rétrécir en bloc (voir `_apply_scale`).
##    Les écrans d'accueil, du quartier et de création, faits pour 720, gardent cette hauteur.
##  - Le jeu se joue en paysage : en portrait, un voile demande de tourner le téléphone.
## Le reste du jeu lit `Device.mobile` pour adapter ses panneaux et ses gestes (voir README).

## La disposition a changé (taille de l'écran, orientation).
signal layout_changed

## Hauteur de l'écran, en unités d'interface, sur mobile (720 sur ordinateur).
const MOBILE_HEIGHT := 480
const MENU_HEIGHT := 720
## Scène du jeu (les autres sont des menus).
const GAME_SCENE := "res://scenes/main.tscn"

var mobile := false
var portrait := false
var _veil: CanvasLayer


func _ready() -> void:
	mobile = _detect()
	if not mobile:
		return
	get_window().size_changed.connect(_apply_scale)
	get_tree().scene_changed.connect(_apply_scale)
	_make_veil()
	_apply_scale()


func _detect() -> bool:
	if "--mobile" in OS.get_cmdline_user_args():
		return true
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search", true)
		return search is String and "mobile=1" in search
	return false


## L'interface garde une hauteur de MOBILE_HEIGHT unités (sur le petit côté de l'écran) : elle est
## donc plus grosse qu'en 1280 × 720 réduit. La largeur suit la forme de l'écran.
func _apply_scale() -> void:
	var size := DisplayServer.window_get_size()
	if size.x <= 0 or size.y <= 0:
		return
	portrait = size.y > size.x
	var short := float(mini(size.x, size.y))
	var scene := get_tree().current_scene
	var in_game := scene != null and scene.scene_file_path == GAME_SCENE
	var units := Vector2(size) * (MOBILE_HEIGHT if in_game else MENU_HEIGHT) / short
	get_window().content_scale_size = Vector2i(roundi(units.x), roundi(units.y))
	if _veil != null:
		_veil.visible = portrait
	layout_changed.emit()


## Le voile « Tourne ton téléphone », par-dessus tout.
func _make_veil() -> void:
	_veil = CanvasLayer.new()
	_veil.layer = 128
	_veil.visible = false
	add_child(_veil)
	var back := ColorRect.new()
	back.color = Palette.PAPIER
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.add_child(back)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	back.add_child(box)
	var phone := Control.new()
	phone.custom_minimum_size = Vector2(120, 120)
	phone.draw.connect(func() -> void: _draw_phone(phone))
	box.add_child(phone)
	var title := Label.new()
	title.text = "Tourne ton téléphone"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Palette.ENCRE)
	box.add_child(title)
	var text := Label.new()
	text.text = "Les Mouz se jouent en paysage."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 700))
	text.add_theme_font_size_override("font_size", 22)
	text.add_theme_color_override("font_color", Palette.ENCRE_DOUCE)
	box.add_child(text)


## Un téléphone couché, avec une flèche qui tourne.
func _draw_phone(canvas: Control) -> void:
	var center := canvas.size / 2
	var body := Rect2(center - Vector2(46, 26), Vector2(92, 52))
	canvas.draw_rect(body, Palette.PAPIER)
	canvas.draw_style_box(HudTheme.box(Color.WHITE, 10, Palette.CONTOUR, 3), body)
	canvas.draw_circle(center + Vector2(38, 0), 3.0, Palette.CONTOUR)
	canvas.draw_arc(center, 58, -PI * 0.85, -PI * 0.25, 24, Palette.ACCENT, 4.0, true)
	var tip := center + Vector2.from_angle(-PI * 0.25) * 58
	canvas.draw_colored_polygon(PackedVector2Array([tip + Vector2(-2, -12), tip + Vector2(10, 2), tip + Vector2(-10, 6)]), Palette.ACCENT)


## Plein écran (là où le navigateur le permet) : bouton du menu sur mobile.
func toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
