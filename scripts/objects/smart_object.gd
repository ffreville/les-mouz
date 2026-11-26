class_name SmartObject
extends Node2D
## Un objet posé dans la maison. Il se dessine (dans sa collection, « en marche » ou non),
## annonce ses actions et gère qui l'utilise (réservation).

## Les objets traversables (tapis) passent sous les autres.
const FLOOR_OBJECT_Z := -1

## L'objet tel qu'il est posé sur le terrain (définition, case, rotation, style, prix payé).
var placed: PlacedObject
var definition: SmartObjectDefinition
## Cases occupées par l'objet.
var footprint: Rect2i
## Niveau où il est posé (voir Levels).
var level := 0
var _cell_size: float
var _users: Array[Node] = []
## Place occupée par chaque utilisateur (0, 1, 2…) : chacun garde la sienne jusqu'à ce qu'il parte.
var _seats: Dictionary[Node, int] = {}
## Personnages qui font fonctionner l'objet à distance (la télé pour le canapé).
var _powered_by: Array[Node] = []
## Escalier : ce qui passe devant les Mouz qui le prennent (voir StairsFront).
var front: StairsFront
## Image courante des flammes (objet en feu) et temps écoulé depuis la précédente.
var _fire_frame := 0
var _fire_time := 0.0

## Objets qui changent avec les saisons, et leur teinte en attendant leurs dessins de saison.
const SEASONAL: Array[StringName] = [&"arbre"]
const SEASON_TINT := {&"ete": Color(1.0, 0.98, 0.86), &"automne": Color(1.0, 0.78, 0.5), &"hiver": Color(0.86, 0.88, 0.92)}
## Flammes dessinées par Claude Design (3 images), sinon dessinées ici.
const FIRE_FRAMES := "res://assets/sprites/feu_%d.svg"
const FIRE_FRAME_TIME := 0.14
const FLAME_OUTER := Color("#F08A24")
const FLAME_INNER := Color("#FFD34D")
const SMOKE := Color("#6E6680")


func setup(p_placed: PlacedObject, cell_size: int) -> void:
	placed = p_placed
	definition = placed.definition
	footprint = placed.footprint()
	_cell_size = cell_size
	name = definition.display_name
	# Le nœud est posé au bas de l'emprise : c'est ce point qui fixe l'ordre d'affichage.
	position = Vector2(footprint.position.x, footprint.end.y) * cell_size
	z_index = FLOOR_OBJECT_Z if not definition.blocks_movement else 0
	if definition.is_stairs:
		_update_front.call_deferred()
	if definition.grows:
		Garden.warm(definition)
	queue_redraw()


## Le calque de devant de l'escalier, posé à côté de lui (juste après lui dans l'ordre d'affichage).
func _update_front() -> void:
	if not is_inside_tree():
		return
	if front == null:
		front = StairsFront.new()
		front.stairs = self
		get_parent().add_child(front)
	front.position = position + Vector2(0, 0.02)
	front.queue_redraw()


func _exit_tree() -> void:
	if front != null and is_instance_valid(front):
		front.queue_free()
		front = null


## Dessine un objet tourné de `rotation` quarts de tour, emprise posée à `origin` (coin haut-gauche).
## En vue trois quarts, l'image monte au-dessus de l'emprise : son bas est le bas de l'emprise.
## Sans vues trois quarts, on dessine à plat l'image vue de dessus, tournée.
## Partagé avec l'aperçu de placement de l'éditeur.
static func draw_definition(canvas: CanvasItem, p_definition: SmartObjectDefinition, rotation: int,
		origin: Vector2, cell_size: float, modulate := Color.WHITE, collection: StringName = &"",
		active := false) -> void:
	var view := p_definition.get_view(collection, rotation, active)
	if not view.is_empty():
		var rect := view_rect(p_definition, rotation, origin, cell_size, view[0])
		if view[1]:
			# Vue `droite` = vue `gauche` retournée.
			canvas.draw_set_transform(Vector2(rect.position.x * 2 + rect.size.x, 0), 0.0, Vector2(-1, 1))
		canvas.draw_texture_rect(view[0], rect, false, modulate)
		canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	var native := Vector2(p_definition.size) * cell_size
	var turned := Vector2(native.y, native.x) if rotation % 2 == 1 else native
	canvas.draw_set_transform(origin + turned / 2, rotation * PI / 2)
	var area := Rect2(-native / 2, native)
	var sprite := p_definition.get_sprite(collection, active)
	if sprite != null:
		canvas.draw_texture_rect(sprite, area, false, modulate)
	else:
		# Graphisme provisoire si aucune image n'est fournie.
		canvas.draw_rect(area.grow(-3), p_definition.color * modulate)
		canvas.draw_rect(area.grow(-3), Palette.CONTOUR * modulate, false, 2.0)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


## Rectangle de l'image trois quarts : même largeur que l'emprise, posée sur son bas.
static func view_rect(p_definition: SmartObjectDefinition, rotation: int, origin: Vector2,
		cell_size: float, texture: Texture2D) -> Rect2:
	var cells := Vector2(p_definition.size)
	var turned := Vector2(cells.y, cells.x) if rotation % 2 == 1 else cells
	var width := turned.x * cell_size
	var height := texture.get_height() * width / texture.get_width()
	return Rect2(origin.x, origin.y + turned.y * cell_size - height, width, height)


func get_display_name() -> String:
	return definition.display_name


## Actions de l'objet ; en feu, « Éteindre le feu » passe en premier, et en panne, « Réparer ».
func get_actions() -> Array[ActionDefinition]:
	if placed != null and placed.is_burning():
		var actions: Array[ActionDefinition] = [Mishaps.EXTINGUISH]
		actions.append_array(definition.actions)
		return actions
	if placed != null and placed.is_broken():
		var actions: Array[ActionDefinition] = [Upkeep.REPAIR_ACTION]
		actions.append_array(definition.actions)
		return actions
	if definition.built and placed != null and placed.growth >= 100.0:
		return definition.actions.filter(func(action: ActionDefinition) -> bool: return not action.builds)
	return definition.actions


func has_actions() -> bool:
	return not get_actions().is_empty()


## Les cases de la piscine qui touche l'objet (rez-de-chaussée), ou [] s'il n'y en a pas.
func pool_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if level != 0 or world_lot() == null:
		return result
	var pool: Dictionary = world_lot().pool
	var todo: Array[Vector2i] = []
	for y in range(footprint.position.y - 1, footprint.end.y + 1):
		for x in range(footprint.position.x - 1, footprint.end.x + 1):
			var cell := Vector2i(x, y)
			var beside := (x >= footprint.position.x and x < footprint.end.x) or (y >= footprint.position.y and y < footprint.end.y)
			if beside and pool.has(cell) and not cell in todo:
				todo.append(cell)
	var index := 0
	while index < todo.size():
		var cell := todo[index]
		index += 1
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if pool.has(next) and not next in todo:
				todo.append(next)
	result.assign(todo)
	return result


## Le terrain où l'objet est posé (null hors du monde).
func world_lot() -> Lot:
	var node := get_parent()
	while node != null and not node is World:
		node = node.get_parent()
	return (node as World).lot if node != null else null


## Emprise en cases de navigation (niveau compris).
func nav_footprint() -> Rect2i:
	return Rect2i(Levels.nav(footprint.position, level), footprint.size)


## `cell` : case de navigation.
func occupies(cell: Vector2i) -> bool:
	return nav_footprint().has_point(cell)


## Coin haut-gauche de l'emprise, dans le repère du nœud.
func _origin() -> Vector2:
	return Vector2(0, -footprint.size.y * _cell_size)


## Zone visible de l'objet à l'écran (monde), hauteur comprise.
func screen_rect() -> Rect2:
	var view := definition.get_view(placed.get_collection(), placed.rotation, is_active())
	var rect := Rect2(_origin(), Vector2(footprint.size) * _cell_size)
	if not view.is_empty():
		rect = view_rect(definition, placed.rotation, _origin(), _cell_size, view[0])
	return Rect2(rect.position + position, rect.size)


## Rectangle du sprite trois quarts dans le repère du nœud (vide sans vue trois quarts).
func sprite_rect_local() -> Rect2:
	var view := definition.get_view(placed.get_collection(), placed.rotation, is_active())
	if view.is_empty():
		return Rect2()
	return view_rect(definition, placed.rotation, _origin(), _cell_size, view[0])


## Place que prend ce Mouz sur l'objet, {} s'il n'y en a pas.
func place_for(character: Node) -> Dictionary:
	return SeatPlaces.find(definition.id, placed.get_collection(),
			SmartObjectDefinition.VIEWS[posmod(placed.rotation, 4)], _seats.get(character, -1))


## Vrai si un clic à cette position (monde) touche l'image de l'objet.
func contains_point(world_position: Vector2) -> bool:
	return screen_rect().has_point(world_position)


## « En marche » : utilisé, alimenté à distance ou allumé.
func is_active() -> bool:
	if Bills.cut and definition.id in Bills.ELECTRIC or placed.is_broken():
		return false
	return not _users.is_empty() or not _powered_by.is_empty() or placed.switched_on


## Cases où se tenir pour s'en servir : autour d'un meuble, dessus pour un tapis.
func get_spots(navigation: GridNavigation) -> Array[Vector2i]:
	var rect := nav_footprint()
	if definition.blocks_movement:
		return navigation.cells_around(rect)
	var cells: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if navigation.is_walkable(Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	return cells


## Raison pour laquelle l'action n'est pas possible ici ("" si elle l'est).
func action_problem(action: ActionDefinition, world: World) -> String:
	if action == Mishaps.EXTINGUISH:
		return "" if placed.is_burning() else "pas de feu"
	if placed.is_burning():
		return "en feu"
	if action.swim and pool_cells().is_empty():
		return "pas de piscine à côté"
	if action.needs_ripe and definition.grows:
		if Garden.is_wilted(placed):
			return "fané : à arroser"
		if not Garden.is_ripe(placed):
			return "pas encore mûr" if definition.id == &"potager" else "pas encore fleuri"
	var weather := world.weather.problem_for(self, action)
	if weather != "":
		return weather
	if action == Upkeep.REPAIR_ACTION:
		return "réparateur appelé" if placed.repair_at > 0.0 else ""
	if placed.is_broken():
		return "en panne"
	var power := world.bills.problem_for(definition.id)
	if power == "" and action.nearby_object_id != &"":
		power = world.bills.problem_for(action.nearby_object_id)
	if power != "":
		return power
	if action.cost > 0 and not Wallet.can_afford(action.cost):
		return "pas assez d'argent"
	match action.switch:
		ActionDefinition.Switch.TURN_ON:
			if placed.switched_on:
				return "déjà allumé"
		ActionDefinition.Switch.TURN_OFF:
			if not placed.switched_on:
				return "déjà éteint"
	if action.nearby_object_id != &"" and find_nearby(action, world) == null:
		var needed := Catalog.find(Catalog.OBJECTS, action.nearby_object_id)
		return "pas de %s à côté" % (needed.display_name if needed != null else String(action.nearby_object_id))
	return ""


## L'objet voisin requis par l'action (la télé la plus proche du canapé), ou null.
func find_nearby(action: ActionDefinition, world: World) -> SmartObject:
	var best: SmartObject = null
	var best_distance := action.nearby_radius + 1
	var center := footprint.get_center()
	for other in world.smart_objects:
		if other == self or other.level != level or other.definition.id != action.nearby_object_id:
			continue
		var d := other.footprint.get_center() - center
		var distance := maxi(absi(d.x), absi(d.y))
		if distance < best_distance:
			best_distance = distance
			best = other
	return best


## Autres personnages en train d'utiliser l'objet.
func other_users(user: Node) -> Array[Node]:
	return _users.filter(func(other: Node) -> bool: return other != user)


## Vrai si `user` peut utiliser l'objet maintenant.
func can_use(user: Node) -> bool:
	return user in _users or _users.size() < definition.capacity


func is_used_by_other(user: Node) -> bool:
	return not can_use(user)


## Réserve l'objet pour `user`. Renvoie false s'il est déjà plein.
func reserve(user: Node) -> bool:
	if not can_use(user):
		return false
	if user not in _users:
		_users.append(user)
		var seat := 0
		while seat in _seats.values():
			seat += 1
		_seats[user] = seat
		queue_redraw()
	return true


func release(user: Node) -> void:
	_users.erase(user)
	_seats.erase(user)
	queue_redraw()


## L'objet fonctionne pour `user` qui s'en sert à distance (canapé → télé).
func power_on(user: Node) -> void:
	if user not in _powered_by:
		_powered_by.append(user)
		queue_redraw()


func power_off(user: Node) -> void:
	_powered_by.erase(user)
	queue_redraw()


func _draw() -> void:
	if placed != null:
		var designed := definition.grows and Garden.draw_design(self, placed, _origin(), _cell_size)
		if definition.built and placed.growth < 100.0:
			_draw_partly_built()
		elif not designed and _draw_season():
			pass
		elif not designed:
			draw_definition(self, definition, placed.rotation, _origin(), _cell_size, Color.WHITE,
					placed.get_collection(), is_active())
			if definition.grows:
				Garden.draw_plants(self, placed, Rect2(_origin(), Vector2(footprint.size) * _cell_size), sprite_rect_local())
		if placed.is_burning():
			_draw_fire()
		elif placed.is_broken():
			_draw_broken_mark()


func _process(delta: float) -> void:
	if placed == null or not placed.is_burning():
		return
	_fire_time += delta
	if _fire_time >= FIRE_FRAME_TIME:
		_fire_time = 0.0
		_fire_frame = (_fire_frame + 1) % 3
		queue_redraw()


## Les flammes au-dessus de l'objet en feu, et un peu de fumée.
func _draw_fire() -> void:
	var rect := sprite_rect_local()
	if rect.size == Vector2.ZERO:
		rect = Rect2(_origin(), Vector2(footprint.size) * _cell_size)
	var texture := MouzLayers.texture(FIRE_FRAMES % (_fire_frame + 1))
	if texture != null:
		# Image de 32 px de large, posée sur le haut de l'objet, une par case de largeur.
		for i in footprint.size.x:
			var at := Vector2(rect.position.x + i * _cell_size, rect.position.y + rect.size.y * 0.3 - texture.get_height())
			draw_texture(texture, at)
		return
	var base_y := rect.position.y + minf(rect.size.y * 0.35, 24.0)
	var count := maxi(2, footprint.size.x * 2)
	for i in count:
		var x := rect.position.x + rect.size.x * (i + 0.5) / count
		var flicker := sin((_fire_frame + i * 1.7) * 2.1)
		var height := 18.0 + 6.0 * flicker + (4.0 if i % 2 == 0 else 0.0)
		_draw_flame(Vector2(x, base_y), height, 7.0, flicker * 2.0)
	for i in 3:
		var drift := float((_fire_frame + i) % 3)
		draw_circle(Vector2(rect.get_center().x + (i - 1) * 7 + drift, base_y - 30 - i * 7 - drift * 2),
				5.0 + i * 1.5, Color(SMOKE, 0.45 - i * 0.1))


func _draw_flame(base: Vector2, height: float, half_width: float, sway: float) -> void:
	var outer := _flame_points(base, height, half_width, sway)
	draw_colored_polygon(outer, FLAME_OUTER)
	var closed := outer.duplicate()
	closed.append(outer[0])
	draw_polyline(closed, Palette.CONTOUR, 1.5, true)
	draw_colored_polygon(_flame_points(base + Vector2(0, -1), height * 0.55, half_width * 0.5, sway), FLAME_INNER)


static func _flame_points(base: Vector2, height: float, half_width: float, sway: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		var angle := PI * t
		# Bas arrondi, haut en pointe qui ondule.
		points.append(base + Vector2(-cos(angle) * half_width, sin(angle) * half_width * 0.6))
	points.append(base + Vector2(half_width * 0.6 + sway, -height * 0.5))
	points.append(base + Vector2(sway * 1.5, -height))
	points.append(base + Vector2(-half_width * 0.6 + sway, -height * 0.5))
	return points


## Objet en construction : seul le bas de l'image est dessiné, selon l'avancement.
func _draw_partly_built() -> void:
	var view := definition.get_view(placed.get_collection(), placed.rotation)
	if view.is_empty():
		return
	var rect := view_rect(definition, placed.rotation, _origin(), _cell_size, view[0])
	var shown := clampf(0.25 + 0.75 * placed.growth / 100.0, 0.0, 1.0)
	var texture: Texture2D = view[0]
	var source := Rect2(0, texture.get_height() * (1.0 - shown), texture.get_width(), texture.get_height() * shown)
	draw_texture_rect_region(texture, Rect2(rect.position.x, rect.end.y - rect.size.y * shown, rect.size.x, rect.size.y * shown), source)


## Objet qui change avec les saisons (l'arbre) : son image de saison si Claude Design l'a dessinée
## (`<id>_<collection>_<vue>_<saison>.svg`), sinon l'image habituelle teintée. Renvoie false pour
## les autres objets.
func _draw_season() -> bool:
	if not definition.id in SEASONAL:
		return false
	var season := Weather.season()
	var views := definition.get_view(placed.get_collection(), placed.rotation)
	if views.is_empty():
		return false
	var view_name := SmartObjectDefinition.VIEWS[posmod(placed.rotation, 4)]
	var flip: bool = views[1]
	if view_name == &"droite":
		view_name = &"gauche"
	var texture := MouzLayers.texture(SmartObjectDefinition.VIEW_PATH % [definition.id, placed.get_collection(),
			view_name, "_" + String(season)])
	var tint := Color.WHITE
	if texture == null:
		texture = views[0]
		tint = SEASON_TINT.get(season, Color.WHITE)
	var rect := view_rect(definition, placed.rotation, _origin(), _cell_size, texture)
	if flip:
		draw_set_transform(Vector2(rect.position.x * 2 + rect.size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect(texture, rect, false, tint)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	return true


## Signe « en panne » au-dessus de l'objet : un panneau rouge avec un point d'exclamation.
func _draw_broken_mark() -> void:
	var rect := sprite_rect_local()
	if rect.size == Vector2.ZERO:
		rect = Rect2(_origin(), Vector2(footprint.size) * _cell_size)
	var center := Vector2(rect.get_center().x, rect.position.y - 6)
	draw_circle(center, 8.0, Palette.CRITIQUE)
	draw_circle(center, 8.0, Palette.PAPIER, false, 2.0, true)
	draw_rect(Rect2(center.x - 1.2, center.y - 5, 2.4, 6), Palette.PAPIER)
	draw_circle(center + Vector2(0, 3.5), 1.4, Palette.PAPIER)
