class_name Garden
extends Node
## Les plantations du jardin (enfant du monde) : le potager et le massif de fleurs poussent tout seuls
## s'ils ont de l'eau : graines → pousses → mûr (ou fleuri) en GROW_DAYS jours. L'eau baisse avec le
## temps ; à 0, la plantation fane et ne pousse plus, jusqu'à ce qu'on l'arrose.
##  - Arroser : l'eau revient au plein (et la plantation reprend).
##  - Jardiner : la pousse avance de TEND_BOOST.
##  - Récolter, vendre les légumes : seulement mûr ; la plantation repart des graines.
## Dessin provisoire des états, en attendant le brief n° 8.

const GROW_DAYS := 3.0
## L'eau tient environ deux jours.
const WATER_HOURS := 48.0
const TEND_BOOST := 15.0
const SPROUTS := 34.0
const THIRSTY := 30.0

const SOIL := Color("#8A6447")
const SOIL_DARK := Color("#6E4E37")
const LEAF := Color("#5E9A55")
const LEAF_LIGHT := Color("#8CC27A")
const WILTED := Color("#B79A55")
const FRUIT := Color("#D9533F")
const FLOWERS := [Color("#E8794A"), Color("#F2C94C"), Color("#D98CB8"), Color("#9B8CE0")]
const DROP := Color("#7CC6E0")

var world: World


func setup(p_world: World) -> void:
	world = p_world
	GameClock.ticked.connect(_on_ticked)
	EventBus.action_finished.connect(_on_action_finished)


static func is_wilted(placed: PlacedObject) -> bool:
	return placed.water <= 0.0


static func is_ripe(placed: PlacedObject) -> bool:
	return placed.growth >= 100.0 and not is_wilted(placed)


## « graines », « pousses », « mur » ou « fane ».
static func stage(placed: PlacedObject) -> StringName:
	if is_wilted(placed):
		return &"fane"
	if placed.growth >= 100.0:
		return &"mur"
	return &"pousses" if placed.growth >= SPROUTS else &"graines"


func _on_ticked(minutes: float) -> void:
	for smart_object in world.smart_objects:
		var placed := smart_object.placed
		if not placed.definition.grows:
			continue
		var before := stage(placed)
		var was_thirsty := placed.water < THIRSTY
		placed.water = maxf(placed.water - 100.0 / WATER_HOURS * minutes / 60.0, 0.0)
		if placed.water > 0.0:
			placed.growth = minf(placed.growth + 100.0 / (GROW_DAYS * 24.0) * minutes / 60.0, 100.0)
		var after := stage(placed)
		if after != before or (placed.water < THIRSTY) != was_thirsty:
			smart_object.queue_redraw()
		if after == &"fane" and before != &"fane":
			EventBus.notice.emit("%s fane : il faut l'arroser !" % smart_object.get_display_name())
		elif after == &"mur" and before != &"mur":
			EventBus.notice.emit("%s est %s." % [smart_object.get_display_name(),
					"mûr : on peut récolter" if placed.definition.id == &"potager" else "en fleurs"])


func _on_action_finished(_character: Node, action: RefCounted) -> void:
	var smart_object: SmartObject = action.target_object
	if smart_object == null or action.definition == null or not smart_object.definition.grows:
		return
	var placed := smart_object.placed
	var definition: ActionDefinition = action.definition
	if definition.waters:
		placed.water = 100.0
	if definition.tends and not is_wilted(placed):
		placed.growth = minf(placed.growth + TEND_BOOST, 100.0)
	if definition.harvests:
		placed.growth = 0.0
	smart_object.queue_redraw()


## Les plants sur le bac (provisoire) : terre, puis graines, pousses, plants mûrs ou fleurs, ou fanés ;
## une goutte au-dessus quand la plantation a soif.
static func draw_plants(canvas: CanvasItem, placed: PlacedObject, ground: Rect2, sprite: Rect2) -> void:
	var bed := ground.grow(-6.0)
	# Un bac dessiné en vue trois quarts a son dessus un peu plus haut que son emprise.
	if sprite.size != Vector2.ZERO:
		bed.position.y -= 10.0
	canvas.draw_rect(bed, SOIL)
	var current := stage(placed)
	var flowers := placed.definition.id != &"potager"
	var columns := maxi(int(bed.size.x / 10.0), 1)
	var rows := maxi(int(bed.size.y / 10.0), 1)
	for row in rows:
		for column in columns:
			var at := bed.position + Vector2((column + 0.5) * bed.size.x / columns, (row + 0.7) * bed.size.y / rows)
			match current:
				&"graines":
					canvas.draw_line(at + Vector2(-3, 0), at + Vector2(3, 0), SOIL_DARK, 2.0)
				&"pousses":
					canvas.draw_line(at, at + Vector2(0, -4), LEAF, 1.5)
					canvas.draw_circle(at + Vector2(-2, -4), 1.6, LEAF_LIGHT)
					canvas.draw_circle(at + Vector2(2, -5), 1.6, LEAF_LIGHT)
				&"mur":
					canvas.draw_circle(at + Vector2(0, -3), 4.0, LEAF)
					var color: Color = FLOWERS[(row + column) % FLOWERS.size()] if flowers else FRUIT
					canvas.draw_circle(at + Vector2(1, -5), 2.2, color)
				&"fane":
					canvas.draw_line(at, at + Vector2(3, -3), WILTED, 2.0)
					canvas.draw_line(at, at + Vector2(-3, -2), WILTED, 2.0)
	if placed.water < THIRSTY:
		var top := Vector2(bed.get_center().x, bed.position.y - 10.0)
		canvas.draw_circle(top, 5.0, Color.WHITE)
		canvas.draw_circle(top + Vector2(0, 1), 3.0, DROP if not is_wilted(placed) else Palette.CRITIQUE)
		canvas.draw_colored_polygon(PackedVector2Array([top + Vector2(-3, 0), top + Vector2(0, -5), top + Vector2(3, 0)]),
				DROP if not is_wilted(placed) else Palette.CRITIQUE)
