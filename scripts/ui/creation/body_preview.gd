class_name BodyPreview
extends Control
## Aperçu du sprite en jeu : agrandi, il marche sur place et passe par ses 4 directions
## (ou reste dans une direction fixe, pour les petites vignettes).

const LAYER_SIZE := Vector2(32, 64)
const FEET_FROM_TOP := 48.0
const STEP_TIME := 0.22
const TURN_TIME := 1.6
const DIRECTIONS: Array[StringName] = [&"bas", &"gauche", &"haut", &"droite"]

var appearance: MouzAppearance:
	set(value):
		appearance = value
		queue_redraw()
var scale_factor := 2.0
## Direction fixe (&"" = tourne et marche).
var fixed_direction: StringName = &""
var _time := 0.0


func _init(p_scale := 2.0, p_direction: StringName = &"") -> void:
	scale_factor = p_scale
	fixed_direction = p_direction
	custom_minimum_size = LAYER_SIZE * p_scale
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if fixed_direction == &"" and is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	if appearance == null:
		return
	var direction := fixed_direction
	var pose := ""
	if direction == &"":
		direction = DIRECTIONS[int(_time / TURN_TIME) % DIRECTIONS.size()]
		pose = "marche_1" if int(_time / STEP_TIME) % 2 == 0 else "marche_2"
	var view := &"gauche" if direction == &"droite" else direction
	var drawn := LAYER_SIZE * scale_factor
	# Pieds au centre-bas du contrôle.
	var feet := Vector2(size.x / 2, size.y - (LAYER_SIZE.y - FEET_FROM_TOP) * scale_factor * 0.5)
	var rect := Rect2(feet - Vector2(drawn.x / 2, FEET_FROM_TOP * scale_factor), drawn)
	MouzLayers.draw(self, appearance.body_layers(view, pose), rect, direction == &"droite",
			scale_factor if pose != "" else 0.0)
