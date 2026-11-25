class_name LotEditor
extends Node
## Modifie le terrain en payant ou en remboursant, et garde un historique pour « Annuler ».
## Murs, portes, fenêtres, sols et objets passent tous par ici.
## Chaque opération réussie émet EventBus.lot_changed. Ctrl+Z annule (hors mode Vivre).

signal history_changed(can_undo: bool)

var world: World
## Entrées : { "revert": Callable, "money": int } (money : variation du solde appliquée).
var _history: Array[Dictionary] = []

var lot: Lot:
	get:
		return world.lot


func setup(p_world: World) -> void:
	world = p_world


func can_undo() -> bool:
	return not _history.is_empty()


## Annule la dernière opération : terrain et argent reviennent à l'état d'avant.
func undo() -> bool:
	if _history.is_empty():
		return false
	var entry: Dictionary = _history.back()
	var money: int = entry["money"]
	# Annuler une revente oblige à rendre l'argent reçu.
	if money > 0 and not Wallet.can_afford(money):
		return false
	_history.pop_back()
	Wallet.adjust(-money)
	entry["revert"].call()
	EventBus.lot_changed.emit()
	history_changed.emit(can_undo())
	return true


# --- Murs ----------------------------------------------------------------------

## Devis pour construire des murs : segments nouveaux, coût, validité.
func quote_walls(edges: Array[Vector3i], style: WallStyleDefinition) -> Dictionary:
	var fresh: Array[Vector3i] = []
	var valid := not edges.is_empty()
	for edge in edges:
		if not can_hold_wall(edge):
			valid = false
		elif not lot.has_wall(edge):
			fresh.append(edge)
	return {"edges": fresh, "cost": fresh.size() * style.price_per_segment, "valid": valid and not fresh.is_empty()}


func build_walls(edges: Array[Vector3i], style: WallStyleDefinition) -> bool:
	var quote := quote_walls(edges, style)
	if not quote["valid"] or not Wallet.pay(quote["cost"]):
		return false
	_commit(_place_walls(quote["edges"], style), -quote["cost"])
	return true


## Pose les murs (déjà payés) ; renvoie de quoi les retirer.
func _place_walls(fresh: Array[Vector3i], style: WallStyleDefinition) -> Callable:
	for edge in fresh:
		var wall := PlacedWall.new()
		wall.style = style
		Wallet.stamp(wall, style.price_per_segment)
		lot.walls[edge] = wall
		EventBus.item_bought.emit(wall, wall.price)
	return func() -> void:
		for edge in fresh:
			lot.walls.erase(edge)


# --- Pièces ----------------------------------------------------------------------

## Les arêtes du pourtour d'un rectangle de cases.
static func room_edges(rect: Rect2i) -> Array[Vector3i]:
	var edges: Array[Vector3i] = []
	for x in range(rect.position.x, rect.end.x):
		edges.append(Vector3i(x, rect.position.y, Edges.HORIZONTAL))
		edges.append(Vector3i(x, rect.end.y, Edges.HORIZONTAL))
	for y in range(rect.position.y, rect.end.y):
		edges.append(Vector3i(rect.position.x, y, Edges.VERTICAL))
		edges.append(Vector3i(rect.end.x, y, Edges.VERTICAL))
	return edges


## Devis d'une pièce : murs neufs sur le pourtour et sol à l'intérieur, en une fois.
func quote_room(rect: Rect2i, style: RoomStyle) -> Dictionary:
	var inside := rect.intersection(Rect2i(Vector2i.ZERO, lot.size)) == rect
	var walls := quote_walls(room_edges(rect), style.wall)
	var floors := quote_floor(rect, style.floor)
	var holds := room_edges(rect).all(can_hold_wall)
	var fresh: Array[Vector3i] = walls["edges"]
	var valid: bool = inside and holds and (not fresh.is_empty() or floors["valid"])
	return {"edges": fresh, "cells": floors["cells"], "cost": walls["cost"] + floors["cost"], "valid": valid,
			"reason": "" if valid else ("Hors du terrain" if not inside else ("Un meuble est sur le tracé" if not holds else "Déjà construite"))}


func build_room(rect: Rect2i, style: RoomStyle) -> bool:
	var quote := quote_room(rect, style)
	var cost: int = quote["cost"]
	if not quote["valid"] or (cost > 0 and not Wallet.pay(cost)):
		return false
	if cost < 0:
		Wallet.receive(-cost)
	var remove_walls := _place_walls(quote["edges"], style.wall)
	var previous := _replace_floors(quote["cells"], style.floor)
	var revert := func() -> void:
		remove_walls.call()
		_restore_floors(previous)
	_commit(revert, -cost)
	return true


## Devis de démolition : murs et ouvertures concernés, montant rendu.
func quote_demolish(edges: Array[Vector3i]) -> Dictionary:
	var walls: Array[Vector3i] = []
	var openings: Array[PlacedOpening] = []
	var refund := 0
	for edge in edges:
		if not lot.has_wall(edge):
			continue
		walls.append(edge)
		refund += Wallet.resale_value(lot.walls[edge])
		var opening := lot.opening_at(edge)
		if opening != null and opening not in openings:
			openings.append(opening)
			refund += Wallet.resale_value(opening)
	return {"edges": walls, "openings": openings, "refund": refund, "valid": not walls.is_empty()}


func demolish_walls(edges: Array[Vector3i]) -> bool:
	var quote := quote_demolish(edges)
	if not quote["valid"]:
		return false
	var removed: Dictionary[Vector3i, PlacedWall] = {}
	for edge in quote["edges"]:
		removed[edge] = lot.walls[edge]
		lot.walls.erase(edge)
		EventBus.item_sold.emit(removed[edge], Wallet.resale_value(removed[edge]))
	var openings: Array[PlacedOpening] = quote["openings"]
	for opening in openings:
		lot.openings.erase(opening)
		EventBus.item_sold.emit(opening, Wallet.resale_value(opening))
	Wallet.receive(quote["refund"])
	var revert := func() -> void:
		for edge in removed:
			lot.walls[edge] = removed[edge]
		lot.openings.append_array(openings)
	_commit(revert, quote["refund"])
	return true


## Un mur ne peut pas couper un objet en deux ni sortir du terrain.
func can_hold_wall(edge: Vector3i) -> bool:
	if not lot.contains_edge(edge):
		return false
	var sides := Edges.sides(edge)
	var a := lot.blocking_object_at(sides[0])
	return a == null or a != lot.blocking_object_at(sides[1])


# --- Portes et fenêtres ---------------------------------------------------------

## Devis pour poser une ouverture à partir de `edge` : il faut un mur sans ouverture sur chaque segment.
func quote_opening(edge: Vector3i, definition: OpeningDefinition) -> Dictionary:
	var valid := true
	for i in definition.width_segments:
		var segment := Edges.next_along(edge, i)
		if not lot.has_wall(segment) or lot.opening_at(segment) != null:
			valid = false
	return {"cost": definition.price, "valid": valid}


func place_opening(edge: Vector3i, definition: OpeningDefinition, swing_positive: bool,
		hinge_flipped: bool) -> bool:
	var quote := quote_opening(edge, definition)
	if not quote["valid"] or not Wallet.pay(quote["cost"]):
		return false
	var opening := PlacedOpening.new()
	opening.definition = definition
	opening.edge = edge
	opening.swing_positive = swing_positive
	opening.hinge_flipped = hinge_flipped
	Wallet.stamp(opening, definition.price)
	lot.openings.append(opening)
	EventBus.item_bought.emit(opening, opening.price)
	_commit(func() -> void: lot.openings.erase(opening), -quote["cost"])
	return true


# --- Sols ------------------------------------------------------------------------

## Devis pour peindre un rectangle : cases à changer, coût net (l'ancien revêtement est revendu).
func quote_floor(rect: Rect2i, definition: FloorDefinition) -> Dictionary:
	var cells: Array[Vector2i] = []
	var cost := 0
	for cell in _cells_in(rect):
		var current: PlacedFloor = lot.floors.get(cell)
		if current != null and current.definition == definition:
			continue
		cells.append(cell)
		cost += definition.price_per_cell
		if current != null:
			cost -= Wallet.resale_value(current)
	return {"cells": cells, "cost": cost, "valid": not cells.is_empty()}


func paint_floor(rect: Rect2i, definition: FloorDefinition) -> bool:
	var quote := quote_floor(rect, definition)
	if not quote["valid"]:
		return false
	var cost: int = quote["cost"]
	if cost > 0 and not Wallet.pay(cost):
		return false
	if cost < 0:
		Wallet.receive(-cost)
	var previous := _replace_floors(quote["cells"], definition)
	_commit(_restore_floors.bind(previous), -cost)
	return true


## Devis pour gommer : revêtements retirés et montant rendu.
func quote_erase(rect: Rect2i) -> Dictionary:
	var cells: Array[Vector2i] = []
	var refund := 0
	for cell in _cells_in(rect):
		if lot.floors.has(cell):
			cells.append(cell)
			refund += Wallet.resale_value(lot.floors[cell])
	return {"cells": cells, "refund": refund, "valid": not cells.is_empty()}


func erase_floor(rect: Rect2i) -> bool:
	var quote := quote_erase(rect)
	if not quote["valid"]:
		return false
	Wallet.receive(quote["refund"])
	var previous := _replace_floors(quote["cells"], null)
	_commit(_restore_floors.bind(previous), quote["refund"])
	return true


## Pose `definition` (ou l'herbe si null) sur les cases ; renvoie les anciens revêtements.
func _replace_floors(cells: Array[Vector2i], definition: FloorDefinition) -> Dictionary:
	var previous := {}
	for cell in cells:
		previous[cell] = lot.floors.get(cell)
		if previous[cell] != null:
			EventBus.item_sold.emit(previous[cell], Wallet.resale_value(previous[cell]))
		if definition == null:
			lot.floors.erase(cell)
			continue
		var placed := PlacedFloor.new()
		placed.definition = definition
		Wallet.stamp(placed, definition.price_per_cell)
		lot.floors[cell] = placed
		EventBus.item_bought.emit(placed, placed.price)
	return previous


func _restore_floors(previous: Dictionary) -> void:
	for cell in previous:
		if previous[cell] == null:
			lot.floors.erase(cell)
		else:
			lot.floors[cell] = previous[cell]


## Cases d'un rectangle, limitées au terrain.
func _cells_in(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var area := rect.intersection(Rect2i(Vector2i.ZERO, lot.size))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			cells.append(Vector2i(x, y))
	return cells


# --- Objets ----------------------------------------------------------------------

## Devis de placement d'un objet : coût et validité, avec la raison d'un refus.
## `moving` : l'objet déplacé, ignoré dans les vérifications de chevauchement.
func quote_object(definition: SmartObjectDefinition, cell: Vector2i, rotation: int,
		moving: PlacedObject = null) -> Dictionary:
	var ghost := PlacedObject.new()
	ghost.definition = definition
	ghost.cell = cell
	ghost.rotation = rotation
	var cost := 0 if moving != null else definition.price
	var problem := _placement_problem(ghost, moving)
	return {"cost": cost, "reason": problem, "valid": problem == ""}


func buy_object(definition: SmartObjectDefinition, cell: Vector2i, rotation: int,
		collection: StringName = &"") -> bool:
	var quote := quote_object(definition, cell, rotation)
	if not quote["valid"] or not Wallet.pay(quote["cost"]):
		return false
	var placed := PlacedObject.new()
	placed.definition = definition
	placed.cell = cell
	placed.rotation = rotation
	placed.collection = collection if definition.sprites.has(collection) else definition.default_collection()
	Wallet.stamp(placed, definition.price)
	lot.objects.append(placed)
	EventBus.item_bought.emit(placed, placed.price)
	_commit(func() -> void: lot.objects.erase(placed), -quote["cost"])
	return true


func sell_object(placed: PlacedObject) -> bool:
	if placed not in lot.objects:
		return false
	var refund := Wallet.resale_value(placed)
	EventBus.object_displaced.emit(placed)
	lot.objects.erase(placed)
	Wallet.receive(refund)
	EventBus.item_sold.emit(placed, refund)
	_commit(func() -> void: lot.objects.append(placed), refund)
	return true


## Déplace (et tourne) un objet déjà posé, gratuitement.
func move_object(placed: PlacedObject, cell: Vector2i, rotation: int) -> bool:
	if not quote_object(placed.definition, cell, rotation, placed)["valid"]:
		return false
	var old_cell := placed.cell
	var old_rotation := placed.rotation
	EventBus.object_displaced.emit(placed)
	placed.cell = cell
	placed.rotation = rotation
	var revert := func() -> void:
		placed.cell = old_cell
		placed.rotation = old_rotation
	_commit(revert, 0)
	return true


## Prix d'un changement de style : gratuit le jour de l'achat, ensuite la différence
## entre une revente (75 %) et un rachat au prix plein, soit 25 % du prix.
func restyle_cost(placed: PlacedObject) -> int:
	return placed.price - Wallet.resale_value(placed)


func restyle_object(placed: PlacedObject, collection: StringName) -> bool:
	if placed not in lot.objects or not placed.definition.sprites.has(collection):
		return false
	var cost := restyle_cost(placed)
	if not Wallet.pay(cost):
		return false
	var old_collection := placed.collection
	var old_day := placed.bought_day
	placed.collection = collection
	# Racheté aujourd'hui : un nouveau changement le même jour est gratuit.
	placed.bought_day = GameClock.get_day()
	var revert := func() -> void:
		placed.collection = old_collection
		placed.bought_day = old_day
	_commit(revert, -cost)
	return true


## L'objet posé sous une case (les objets solides passent avant les tapis), ou null.
func object_at(cell: Vector2i) -> PlacedObject:
	var found: PlacedObject = lot.blocking_object_at(cell)
	if found != null:
		return found
	for placed in lot.objects:
		if placed.footprint().has_point(cell):
			return placed
	return null


## Raison pour laquelle l'objet ne peut pas être posé là ("" s'il le peut).
func _placement_problem(ghost: PlacedObject, moving: PlacedObject) -> String:
	var rect := ghost.footprint()
	if not Rect2i(Vector2i.ZERO, lot.size).encloses(rect):
		return "Hors du terrain"
	for other in lot.objects:
		if other == moving or not other.footprint().intersects(rect):
			continue
		# Un tapis peut passer sous un meuble, mais pas sous un autre tapis.
		if other.definition.blocks_movement == ghost.definition.blocks_movement:
			return "Place occupée"
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if x + 1 < rect.end.x and lot.has_wall(Edges.between(cell, cell + Vector2i.RIGHT)):
				return "Un mur traverse l'objet"
			if y + 1 < rect.end.y and lot.has_wall(Edges.between(cell, cell + Vector2i.DOWN)):
				return "Un mur traverse l'objet"
	if ghost.definition.blocks_movement:
		for character in world.people:
			if rect.has_point(character.get_cell()):
				return "Un Mouz est dans le passage"
	# Un objet traversable (tapis de yoga) s'utilise en se tenant dessus.
	if not ghost.definition.actions.is_empty() and ghost.definition.blocks_movement:
		if _usable_spots(rect, moving).is_empty():
			return "Aucune place pour l'utiliser"
	return ""


## Cases libres autour de l'emprise, sans mur entre elles et l'objet.
func _usable_spots(rect: Rect2i, moving: PlacedObject) -> Array[Vector2i]:
	var spots: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var inner := Vector2i(x, y)
			for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
				var outer: Vector2i = inner + direction
				if rect.has_point(outer) or not lot.contains(outer) or lot.blocks_passage(inner, outer):
					continue
				var blocker := lot.blocking_object_at(outer)
				if blocker == null or blocker == moving:
					spots.append(outer)
	return spots


# --- Interne -------------------------------------------------------------------

func _commit(revert: Callable, money: int) -> void:
	_history.append({"revert": revert, "money": money})
	EventBus.lot_changed.emit()
	history_changed.emit(true)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or GameMode.is_live():
		return
	if key.keycode == KEY_Z and key.is_command_or_control_pressed():
		undo()
		get_viewport().set_input_as_handled()
