class_name Character
extends Node2D
## Un personnage (« Mouz »). Ce script assemble ses composants et gère son apparence ;
## la logique est déléguée aux nœuds enfants (déplacement, besoins, file d'actions…).

const CLICK_RADIUS := 16.0
const SELECTION_RADIUS := 19.0
const SELECTION_DASH := 7.0
const SELECTION_GAP := 4.0
## Vitesse à laquelle le corps pivote vers sa direction de marche.
const TURN_SPEED := 12.0

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
	body.texture = profile.sprite
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
	return position.distance_to(world_position) <= CLICK_RADIUS


func _process(delta: float) -> void:
	# Le sprite regarde vers le haut : on l'oriente dans la direction de marche.
	var target := mover.facing.angle() + PI / 2
	body.rotation = lerp_angle(body.rotation, target, minf(1.0, delta * TURN_SPEED))


## Anneau de sélection en pointillés, sous le sprite.
func _draw() -> void:
	if not is_selected:
		return
	var accent := Palette.ACCENT
	draw_circle(Vector2.ZERO, SELECTION_RADIUS, Color(accent, 0.18))
	var circumference := TAU * SELECTION_RADIUS
	var dash_angle := TAU * SELECTION_DASH / circumference
	var step := TAU * (SELECTION_DASH + SELECTION_GAP) / circumference
	var angle := 0.0
	while angle < TAU:
		draw_arc(Vector2.ZERO, SELECTION_RADIUS, angle, minf(angle + dash_angle, TAU), 6, accent, 3.0, true)
		angle += step
