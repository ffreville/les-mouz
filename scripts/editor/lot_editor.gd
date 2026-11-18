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
