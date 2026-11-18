class_name LotSerializer
extends RefCounted
## Convertit un terrain en données JSON (et inversement).
## Les éléments du catalogue sont désignés par leur `id` : la sauvegarde ne contient
## aucune ressource ni aucun script, et survit aux réorganisations de fichiers.
## Un identifiant inconnu (élément retiré du catalogue) est ignoré au chargement.


static func to_data(lot: Lot) -> Dictionary:
	var walls: Array = []
	for edge in lot.walls:
		var wall: PlacedWall = lot.walls[edge]
		walls.append({"edge": _edge(edge), "style": String(wall.style.id)}.merged(_purchase(wall)))
	var floors: Array = []
	for cell in lot.floors:
		var placed: PlacedFloor = lot.floors[cell]
		floors.append({"cell": _cell(cell), "floor": String(placed.definition.id)}.merged(_purchase(placed)))
	var openings: Array = []
	for opening in lot.openings:
		openings.append({
			"edge": _edge(opening.edge), "opening": String(opening.definition.id),
			"swing_positive": opening.swing_positive, "hinge_flipped": opening.hinge_flipped,
		}.merged(_purchase(opening)))
	var objects: Array = []
	for placed in lot.objects:
		objects.append({
			"cell": _cell(placed.cell), "object": String(placed.definition.id), "rotation": placed.rotation,
		}.merged(_purchase(placed)))
	return {
		"size": _cell(lot.size),
		"default_floor": String(lot.default_floor.id) if lot.default_floor != null else "",
		"walls": walls, "floors": floors, "openings": openings, "objects": objects,
		"spawn_cells": lot.spawn_cells.map(_cell),
	}


static func from_data(data: Dictionary) -> Lot:
	var lot := Lot.new()
	lot.size = _to_cell(data.get("size", [30, 20]))
	lot.default_floor = Catalog.find(Catalog.FLOORS, StringName(data.get("default_floor", "herbe")))
	for entry in data.get("walls", []):
		var style := Catalog.find(Catalog.WALLS, StringName(entry.get("style", ""))) as WallStyleDefinition
		if _known(style, entry, "style"):
			var wall := PlacedWall.new()
			wall.style = style
			_restore_purchase(wall, entry)
			lot.walls[_to_edge(entry["edge"])] = wall
	for entry in data.get("floors", []):
		var definition := Catalog.find(Catalog.FLOORS, StringName(entry.get("floor", ""))) as FloorDefinition
		if _known(definition, entry, "floor"):
			var placed := PlacedFloor.new()
			placed.definition = definition
			_restore_purchase(placed, entry)
			lot.floors[_to_cell(entry["cell"])] = placed
	for entry in data.get("openings", []):
		var definition := Catalog.find(Catalog.OPENINGS, StringName(entry.get("opening", ""))) as OpeningDefinition
		if _known(definition, entry, "opening"):
			var opening := PlacedOpening.new()
			opening.definition = definition
			opening.edge = _to_edge(entry["edge"])
			opening.swing_positive = bool(entry.get("swing_positive", true))
			opening.hinge_flipped = bool(entry.get("hinge_flipped", false))
			_restore_purchase(opening, entry)
			lot.openings.append(opening)
	for entry in data.get("objects", []):
		var definition := Catalog.find(Catalog.OBJECTS, StringName(entry.get("object", ""))) as SmartObjectDefinition
		if _known(definition, entry, "object"):
			var placed := PlacedObject.new()
			placed.definition = definition
			placed.cell = _to_cell(entry["cell"])
			placed.rotation = int(entry.get("rotation", 0)) % 4
			_restore_purchase(placed, entry)
			lot.objects.append(placed)
	var spawns: Array[Vector2i] = []
	for cell in data.get("spawn_cells", []):
		spawns.append(_to_cell(cell))
	if not spawns.is_empty():
		lot.spawn_cells = spawns
	return lot


static func _purchase(item: Purchase) -> Dictionary:
	return {"price": item.price, "day": item.bought_day}


static func _restore_purchase(item: Purchase, entry: Dictionary) -> void:
	item.price = int(entry.get("price", 0))
	item.bought_day = int(entry.get("day", 1))


static func _known(definition: Resource, entry: Dictionary, key: String) -> bool:
	if definition == null:
		push_warning("Sauvegarde : élément inconnu ignoré (%s = %s)" % [key, entry.get(key, "?")])
	return definition != null


static func _cell(cell: Vector2i) -> Array:
	return [cell.x, cell.y]


static func _edge(edge: Vector3i) -> Array:
	return [edge.x, edge.y, edge.z]


static func _to_cell(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))


static func _to_edge(value: Array) -> Vector3i:
	return Vector3i(int(value[0]), int(value[1]), int(value[2]))
