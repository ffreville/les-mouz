class_name Character
extends Node2D
## Un personnage (« Mouz »). Ce script assemble ses composants et gère son apparence ;
## la logique est déléguée aux nœuds enfants (déplacement, besoins, file d'actions…).

## Zone cliquable autour des pieds (la position du nœud) : le corps monte au-dessus.
const CLICK_RECT := Rect2(-12, -46, 24, 50)
const SELECTION_RADIUS := 17.0
## Anneau aplati : on le voit en perspective, posé au sol.
const SELECTION_FLATTEN := 0.55
const SELECTION_DASH := 7.0
const SELECTION_GAP := 4.0
## Silhouette provisoire en vue trois quarts (lot 1), en attendant les vrais humains.
const BODY_PATH := "res://assets/personnages/provisoire_%s%s.svg"
## Couleur du haut dans la silhouette provisoire, remplacée par la couleur du personnage.
const SHIRT_COLOR := Color("#8DB596")
## Durée d'un pas (secondes réelles, à la vitesse x1).
const STEP_TIME := 0.18
const SHIRT_SHADER := """
shader_type canvas_item;
uniform vec4 from_color : source_color;
uniform vec4 to_color : source_color;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (distance(c.rgb, from_color.rgb) < 0.08) {
		c.rgb = to_color.rgb;
	}
	COLOR = c * COLOR;
}
"""

static var _body_textures: Dictionary = {}

var _walk_time := 0.0

var profile: CharacterProfile
var world: World

## Vrai quand le joueur contrôle ce personnage.
var is_selected: bool = false:
	set(value):
		is_selected = value
		name_tag.visible = value
		queue_redraw()

@onready var mover: GridMover = $Mover
@onready var needs: NeedsComponent = $Needs
@onready var queue: ActionQueue = $Queue
@onready var brain: AutonomyBrain = $Brain
@onready var relationships: Relationships = $Relationships
@onready var body: Sprite2D = $Body
@onready var name_tag: Label = $NameTag
@onready var bubble: ActionBubble = $Bubble


## À appeler juste après l'ajout dans l'arbre.
func setup(p_world: World, p_profile: CharacterProfile, cell: Vector2i) -> void:
	world = p_world
	profile = p_profile
	name = profile.display_name
	position = world.navigation.cell_to_world(cell)
	var material := ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.code = SHIRT_SHADER
	material.set_shader_parameter("from_color", SHIRT_COLOR)
	material.set_shader_parameter("to_color", profile.color)
	body.material = material
	_update_body()
	name_tag.text = profile.display_name
	name_tag.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
	name_tag.visible = is_selected
	mover.setup(world.navigation, self, profile.walk_speed)
	needs.setup(self, profile.needs)
	queue.setup(self)
	relationships.setup(self)
	brain.setup(self, profile.autonomy_enabled)
	bubble.setup(queue)
	queue_redraw()


func get_cell() -> Vector2i:
	return world.navigation.world_to_cell(position)


func get_display_name() -> String:
	return profile.display_name


## Vrai si un clic à cette position (monde) touche le personnage.
func contains_point(world_position: Vector2) -> bool:
	return CLICK_RECT.has_point(world_position - position)


func _process(delta: float) -> void:
	if mover.is_moving():
		_walk_time += delta * GameClock.time_scale
	else:
		_walk_time = 0.0
	_update_body()


## Choisit l'image selon la direction de marche (4 vues) et le pas en cours.
func _update_body() -> void:
	var facing := mover.facing
	var view := "bas"
	if absf(facing.x) > absf(facing.y):
		view = "gauche"
	elif facing.y < 0:
		view = "haut"
	var frame := ""
	if mover.is_moving():
		frame = "_marche_1" if int(_walk_time / STEP_TIME) % 2 == 0 else "_marche_2"
	body.flip_h = absf(facing.x) > absf(facing.y) and facing.x > 0
	body.texture = _body_texture(view + frame)


static func _body_texture(key: String) -> Texture2D:
	if not _body_textures.has(key):
		_body_textures[key] = load(BODY_PATH % [key.get_slice("_", 0), key.trim_prefix(key.get_slice("_", 0))])
	return _body_textures[key]


## Anneau de sélection en pointillés, posé au sol sous les pieds.
func _draw() -> void:
	if not is_selected:
		return
	var accent := Palette.ACCENT
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, SELECTION_FLATTEN))
	draw_circle(Vector2.ZERO, SELECTION_RADIUS, Color(accent, 0.18))
	var circumference := TAU * SELECTION_RADIUS
	var dash_angle := TAU * SELECTION_DASH / circumference
	var step := TAU * (SELECTION_DASH + SELECTION_GAP) / circumference
	var angle := 0.0
	while angle < TAU:
		draw_arc(Vector2.ZERO, SELECTION_RADIUS, angle, minf(angle + dash_angle, TAU), 6, accent, 3.0, true)
		angle += step
	draw_set_transform_matrix(Transform2D.IDENTITY)
