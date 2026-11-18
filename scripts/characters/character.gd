class_name Character
extends Node2D
## Un personnage (« Mouz »). Ce script assemble ses composants et gère son dessin ;
## la logique est déléguée aux nœuds enfants (déplacement, besoins, file d'actions…).

const RADIUS := 12.0
const CLICK_RADIUS := 16.0

var profile: CharacterProfile
var world: World

## Vrai quand le joueur contrôle ce personnage.
var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

@onready var mover: GridMover = $Mover
@onready var name_label: Label = $NameLabel


## À appeler juste après l'ajout dans l'arbre.
func setup(p_world: World, p_profile: CharacterProfile, cell: Vector2i) -> void:
	world = p_world
	profile = p_profile
	name = profile.display_name
	position = world.navigation.cell_to_world(cell)
	name_label.text = profile.display_name
	mover.setup(world.navigation, self, profile.walk_speed)
	queue_redraw()


func get_cell() -> Vector2i:
	return world.navigation.world_to_cell(position)


func get_display_name() -> String:
	return profile.display_name


## Vrai si un clic à cette position (monde) touche le personnage.
func contains_point(world_position: Vector2) -> bool:
	return position.distance_to(world_position) <= CLICK_RADIUS


func _draw() -> void:
	if profile == null:
		return
	if is_selected:
		draw_circle(Vector2.ZERO, RADIUS + 5, Color(1, 1, 1, 0.9), false, 2.0)
	draw_circle(Vector2.ZERO, RADIUS, profile.color)
	draw_circle(Vector2.ZERO, RADIUS, profile.color.darkened(0.45), false, 2.0)
