class_name LotEditor
extends Node
## Modifie le terrain en payant ou en remboursant, et garde un historique pour « Annuler ».
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
	var fresh: Array[Vector3i] = quote["edges"]
	for edge in fresh:
		var wall := PlacedWall.new()
		wall.style = style
		Wallet.stamp(wall, style.price_per_segment)
		lot.walls[edge] = wall
		EventBus.item_bought.emit(wall, wall.price)
	var revert := func() -> void:
		for edge in fresh:
			lot.walls.erase(edge)
	_commit(revert, -quote["cost"])
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
