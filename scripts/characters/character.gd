class_name Character
extends Node2D
## Un personnage (« Mouz »). Ce script assemble ses composants et gère son apparence ;
## la logique est déléguée aux nœuds enfants (déplacement, besoins, file d'actions…).

## Zone cliquable autour des pieds (la position du nœud) : le corps monte au-dessus.
const CLICK_RECT := Rect2(-12, -46, 24, 50)
## Ellipse de sélection au sol, sous les pieds.
const SELECTION_RADII := Vector2(13, 6.5)
const SELECTION_WIDTH := 2.5
const SELECTION_DASH := 6.0
const SELECTION_GAP := 4.0
## Durée d'un pas (secondes réelles, à la vitesse x1).
const STEP_TIME := 0.18
## Hauteur du personnage selon son âge (pour placer l'étiquette de nom au-dessus de la tête).
const HEIGHTS := {&"enfant": 32.0, &"ado": 42.0, &"adulte": 48.0, &"aine": 46.0}
## Écart entre le haut de la tête et l'étiquette de nom.
const NAME_TAG_GAP := 6.0

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
@onready var body: MouzBody = $Body
@onready var name_tag: Label = $NameTag
@onready var bubble: ActionBubble = $Bubble


## À appeler juste après l'ajout dans l'arbre.
func setup(p_world: World, p_profile: CharacterProfile, cell: Vector2i) -> void:
	world = p_world
	profile = p_profile
	name = profile.display_name
	position = world.navigation.cell_to_world(cell)
	body.appearance = profile.appearance
	_update_body()
	name_tag.text = profile.display_name
	name_tag.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
	# Étiquette centrée au-dessus de la tête.
	var height: float = HEIGHTS.get(profile.appearance.age if profile.appearance != null else &"adulte", 48.0)
	name_tag.reset_size()
	name_tag.position = Vector2(-name_tag.size.x / 2, -height - NAME_TAG_GAP - name_tag.size.y)
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


## Choisit la vue selon la direction de marche (4 directions) et le pas en cours.
func _update_body() -> void:
	var facing := mover.facing
	var view := &"bas"
	if absf(facing.x) > absf(facing.y):
		view = &"droite" if facing.x > 0 else &"gauche"
	elif facing.y < 0:
		view = &"haut"
	var pose := ""
	if mover.is_moving():
		pose = "marche_1" if int(_walk_time / STEP_TIME) % 2 == 0 else "marche_2"
	body.show_pose(view, pose)


## Ellipse de sélection en tirets, posée au sol sous les pieds.
func _draw() -> void:
	if not is_selected:
		return
	var accent := Palette.ACCENT
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, SELECTION_RADII.y / SELECTION_RADII.x))
	var radius := SELECTION_RADII.x
	draw_circle(Vector2.ZERO, radius, Color(accent, 0.18))
	var circumference := TAU * radius
	var dash_angle := TAU * SELECTION_DASH / circumference
	var step := TAU * (SELECTION_DASH + SELECTION_GAP) / circumference
	var angle := 0.0
	while angle < TAU:
		draw_arc(Vector2.ZERO, radius, angle, minf(angle + dash_angle, TAU), 6, accent, SELECTION_WIDTH, true)
		angle += step
	draw_set_transform_matrix(Transform2D.IDENTITY)
