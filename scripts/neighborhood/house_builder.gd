class_name HouseBuilder
extends RefCounted
## Petit outil pour décrire une maison en code (voir tools/construire_quartier.gd) :
## pièces (sol + murs autour), portes, fenêtres, objets. Les murs communs ne sont posés qu'une fois.
## Rotation des objets : sens de leur face avant (0 haut, 1 droite, 2 bas, 3 gauche).

var lot := Lot.new()
var wall_style: WallStyleDefinition
var collection: StringName
## Niveau où l'on construit (voir `on_level`).
var level := 0


func _init(p_wall_style: StringName, p_collection: StringName, size := Vector2i(30, 20)) -> void:
	lot.size = size
	lot.default_floor = Catalog.find(Catalog.FLOORS, &"herbe")
	wall_style = Catalog.find(Catalog.WALLS, p_wall_style)
	collection = p_collection


## Les pièces, portes, fenêtres et objets suivants vont à ce niveau (0 : rez-de-chaussée).
func on_level(index: int) -> HouseBuilder:
	level = index
	return self


## Pièce : sol `floor_id` sur le rectangle et murs sur son pourtour.
func room(rect: Rect2i, floor_id: StringName) -> HouseBuilder:
	var definition: FloorDefinition = Catalog.find(Catalog.FLOORS, floor_id)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var placed := PlacedFloor.new()
			placed.definition = definition
			placed.price = definition.price_per_cell
			lot.level(level).floors[Vector2i(x, y)] = placed
	for x in range(rect.position.x, rect.end.x):
		_wall(Vector3i(x, rect.position.y, Edges.HORIZONTAL))
		_wall(Vector3i(x, rect.end.y, Edges.HORIZONTAL))
	for y in range(rect.position.y, rect.end.y):
		_wall(Vector3i(rect.position.x, y, Edges.VERTICAL))
		_wall(Vector3i(rect.end.x, y, Edges.VERTICAL))
	return self


## Porte ou fenêtre sur une arête de mur (voir Edges).
func opening(opening_id: StringName, edge: Vector3i, swing_positive := true) -> HouseBuilder:
	var placed := PlacedOpening.new()
	placed.definition = Catalog.find(Catalog.OPENINGS, opening_id)
	placed.edge = edge
	placed.swing_positive = swing_positive
	placed.price = placed.definition.price
	lot.level(level).openings.append(placed)
	return self


func door(edge: Vector3i, swing_positive := true) -> HouseBuilder:
	return opening(&"porte_bois", edge, swing_positive)


func window(edge: Vector3i, wide := false) -> HouseBuilder:
	return opening(&"fenetre_large" if wide else &"fenetre", edge)


## Objet du catalogue, coin haut-gauche en `cell`, face avant vers `rotation`.
func put(object_id: StringName, cell: Vector2i, rotation := 0, p_collection := &"") -> HouseBuilder:
	var placed := PlacedObject.new()
	placed.definition = Catalog.find(Catalog.OBJECTS, object_id)
	assert(placed.definition != null, "objet inconnu : %s" % object_id)
	placed.cell = cell
	placed.rotation = rotation
	placed.collection = p_collection if p_collection != &"" else collection
	placed.price = placed.definition.price
	lot.level(level).objects.append(placed)
	return self


## Le toit de la maison (style du catalogue), payé au prix des cases couvertes.
func roof(roof_id: StringName) -> HouseBuilder:
	var definition: RoofDefinition = Catalog.find(Catalog.ROOFS, roof_id)
	lot.roof = PlacedRoof.new()
	lot.roof.definition = definition
	return self


func spawn(cells: Array[Vector2i]) -> HouseBuilder:
	lot.spawn_cells = cells
	return self


## Tout ce qui est livré avec la maison compte comme un achat ancien (revente dépréciée).
func build() -> Lot:
	var items: Array = []
	for data in lot.levels:
		items.append_array(data.walls.values())
		items.append_array(data.floors.values())
		items.append_array(data.openings)
		items.append_array(data.objects)
	if lot.roof != null:
		lot.roof.price = lot.roof_size() * lot.roof.definition.price_per_cell
		items.append(lot.roof)
	for item in items:
		item.bought_day = 0
	return lot


func _wall(edge: Vector3i) -> void:
	if lot.level(level).walls.has(edge):
		return
	var wall := PlacedWall.new()
	wall.style = wall_style
	wall.price = wall_style.price_per_segment
	lot.level(level).walls[edge] = wall
