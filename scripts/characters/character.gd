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
## Métier et journées de travail.
var job := MouzJob.new()
## Compétences (cuisine, informatique…).
var skills := MouzSkills.new()
## Installé sur un objet (chaise, lit…) : la place, l'objet et la position debout à retrouver.
## Assis, le nœud prend le point de tri de l'objet (il s'affiche juste après lui) et le corps
## est décalé vers sa place ; un calque de l'objet peut repasser devant lui (`_front`).
var _seat: Dictionary = {}
var _seat_object: SmartObject
var _stand_position := Vector2.ZERO
var _front := SeatFront.new()
var _name_tag_base := Vector2.ZERO
var _bubble_base := Vector2.ZERO

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
	_name_tag_base = name_tag.position
	_bubble_base = bubble.position
	add_child(_front)
	move_child(_front, body.get_index() + 1)
	name_tag.visible = is_selected
	mover.setup(world.navigation, self, profile.walk_speed)
	needs.setup(self, profile.needs)
	queue.setup(self)
	relationships.setup(self)
	brain.setup(self, profile.autonomy_enabled)
	add_child(job)
	job.setup(self)
	add_child(skills)
	skills.setup(self)
	bubble.setup(queue)
	queue_redraw()


func get_cell() -> Vector2i:
	return world.navigation.world_to_cell(standing_position())


## Position des pieds quand le Mouz est debout (celle d'avant de s'installer s'il est assis).
func standing_position() -> Vector2:
	return _stand_position if is_seated() else position


## Au travail : hors du terrain, ni cliquable ni disponible.
func is_away() -> bool:
	return job.away


## Au travail ou en route : on ne lui donne plus d'ordres.
func is_busy_with_job() -> bool:
	return job.away or job.is_leaving()


func is_seated() -> bool:
	return not _seat.is_empty()


## S'installe à sa place sur l'objet (s'il en a une pour lui), le temps de l'action.
func sit_on(smart_object: SmartObject) -> void:
	var place := smart_object.place_for(self)
	var sprite := smart_object.sprite_rect_local()
	if place.is_empty() or sprite.size == Vector2.ZERO:
		return
	var age := String(profile.appearance.age if profile.appearance != null else &"adulte")
	_stand_position = position
	_seat = place
	_seat_object = smart_object
	var anchor: Vector2
	if place["pose"] == "allonge":
		anchor = _vec(place["tete"])
		body.lying_rotation = float(place["rotation"])
		body.lying_pivot = _vec(place["pivot"][age])
	else:
		anchor = _vec(place["decalage"][age]) + Vector2(MouzBody.SIZE.x / 2, MouzBody.FEET_FROM_TOP)
		body.head_drop = SeatPlaces.head_drop(place["pose"], StringName(age))
	# Juste après l'objet dans l'ordre d'affichage ; entre Mouz installés sur le même objet,
	# la place la plus basse à l'écran (la plus proche) passe devant. Moins d'un pixel en tout.
	var shift := 0.01 + clampf(anchor.y, 0.0, 400.0) * 0.0002
	position = smart_object.position + Vector2(0, shift)
	body.position = sprite.position - Vector2(0, shift) + anchor
	var origin := sprite.position - Vector2(0, shift)
	_front.show_layer(SeatPlaces.front_texture(place), Rect2(origin, sprite.size), place.has("miroir_de"))
	name_tag.position = _name_tag_base + body.position + Vector2(0, body.head_drop)
	bubble.position = _bubble_base + body.position
	_update_body()
	queue_redraw()


## Se relève et reprend sa place debout.
func stand_up() -> void:
	if not is_seated():
		return
	position = _stand_position
	_seat = {}
	_seat_object = null
	body.position = Vector2.ZERO
	body.head_drop = 0.0
	_front.show_layer(null, Rect2(), false)
	name_tag.position = _name_tag_base
	bubble.position = _bubble_base
	_update_body()
	queue_redraw()


static func _vec(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


func get_display_name() -> String:
	return profile.display_name


## Vrai si un clic à cette position (monde) touche le personnage.
func contains_point(world_position: Vector2) -> bool:
	if is_away():
		return false
	if is_seated() and _seat["pose"] == "allonge":
		return Rect2(-16, -16, 32, 32).has_point(world_position - position - body.position)
	return CLICK_RECT.has_point(world_position - position - body.position)


func _process(delta: float) -> void:
	if mover.is_moving():
		_walk_time += delta * GameClock.time_scale
	else:
		_walk_time = 0.0
	_update_body()


## Choisit la vue selon la direction de marche (4 directions) et le pas en cours.
func _update_body() -> void:
	if is_seated():
		body.show_pose(StringName(_seat.get("direction", "bas")), _seat["pose"])
		return
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
	if not is_selected or is_seated():
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
