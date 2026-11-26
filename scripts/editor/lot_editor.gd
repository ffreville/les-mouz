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
## Niveau où l'on construit : celui que l'on regarde (voir Levels).
var level_index: int:
	get:
		return world.view_level
## Les données de ce niveau.
var data: LotLevel:
	get:
		return world.lot.level(world.view_level)


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
		elif not lot.has_wall(edge, level_index):
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
		data.walls[edge] = wall
		EventBus.item_bought.emit(wall, wall.price)
	return func() -> void:
		for edge in fresh:
			data.walls.erase(edge)


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
	var floors := quote_floor(rect, style.floor)
	# À l'étage, toute la pièce doit être au-dessus de pièces fermées ; ses murs bordent
	# le plancher qu'elle pose.
	var supported := true
	for cell in _cells_in(rect):
		if not supports_floor(cell):
			supported = false
	var fresh: Array[Vector3i] = []
	var holds := true
	for edge in room_edges(rect):
		var ok := can_hold_wall(edge) or level_index > 0 and supported and lot.contains_edge(edge) \
				and _crosses_no_object(edge)
		if not ok:
			holds = false
		elif not data.walls.has(edge):
			fresh.append(edge)
	var cost: int = fresh.size() * style.wall.price_per_segment + floors["cost"]
	var valid: bool = inside and holds and supported and (not fresh.is_empty() or floors["valid"])
	var reason := ""
	if not inside:
		reason = "Hors du terrain"
	elif not supported:
		reason = FLOOR_NEEDS_ROOM
	elif not holds:
		reason = "Un meuble est sur le tracé"
	elif not valid:
		reason = "Déjà construite"
	return {"edges": fresh, "cells": floors["cells"], "cost": cost, "valid": valid, "reason": reason}


## Un mur sur cette arête ne coupe aucun objet en deux.
func _crosses_no_object(edge: Vector3i) -> bool:
	var sides := Edges.sides(edge)
	var a := lot.blocking_object_at(sides[0], level_index)
	return a == null or a != lot.blocking_object_at(sides[1], level_index)


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


## Devis de démolition : murs, clôtures et ouvertures concernés, montant rendu.
func quote_demolish(edges: Array[Vector3i]) -> Dictionary:
	var walls: Array[Vector3i] = []
	var fences: Array[Vector3i] = []
	var openings: Array[PlacedOpening] = []
	var refund := 0
	for edge in edges:
		if level_index == 0 and lot.fences.has(edge):
			fences.append(edge)
			refund += Wallet.resale_value(lot.fences[edge])
		elif not lot.has_wall(edge, level_index):
			continue
		else:
			walls.append(edge)
			refund += Wallet.resale_value(data.walls[edge])
			if data.wallpapers.has(edge):
				refund += Wallet.resale_value(data.wallpapers[edge])
		var opening := lot.opening_at(edge, level_index)
		if opening != null and opening not in openings:
			openings.append(opening)
			refund += Wallet.resale_value(opening)
	return {"edges": walls, "fences": fences, "openings": openings, "refund": refund,
			"valid": not walls.is_empty() or not fences.is_empty()}


func demolish_walls(edges: Array[Vector3i]) -> bool:
	var quote := quote_demolish(edges)
	if not quote["valid"]:
		return false
	var removed: Dictionary[Vector3i, PlacedWall] = {}
	var papers: Dictionary[Vector3i, PlacedWallpaper] = {}
	for edge in quote["edges"]:
		removed[edge] = data.walls[edge]
		data.walls.erase(edge)
		EventBus.item_sold.emit(removed[edge], Wallet.resale_value(removed[edge]))
		if data.wallpapers.has(edge):
			papers[edge] = data.wallpapers[edge]
			data.wallpapers.erase(edge)
	var fences: Dictionary[Vector3i, PlacedFence] = {}
	for edge in quote["fences"]:
		fences[edge] = lot.fences[edge]
		lot.fences.erase(edge)
		EventBus.item_sold.emit(fences[edge], Wallet.resale_value(fences[edge]))
	var openings: Array[PlacedOpening] = quote["openings"]
	for opening in openings:
		data.openings.erase(opening)
		EventBus.item_sold.emit(opening, Wallet.resale_value(opening))
	Wallet.receive(quote["refund"])
	var revert := func() -> void:
		for edge in removed:
			data.walls[edge] = removed[edge]
		for edge in papers:
			data.wallpapers[edge] = papers[edge]
		for edge in fences:
			lot.fences[edge] = fences[edge]
		data.openings.append_array(openings)
	_commit(revert, quote["refund"])
	return true


## Un mur (ou une clôture) ne peut pas couper un objet en deux, sortir du terrain,
## ni se poser là où il y a déjà une clôture (ou un mur).
func can_hold_wall(edge: Vector3i) -> bool:
	if not lot.contains_edge(edge) or level_index == 0 and lot.fences.has(edge):
		return false
	var sides := Edges.sides(edge)
	# À l'étage, un mur se pose au bord d'un plancher.
	if level_index > 0 and lot.floor_at(sides[0], level_index) == null and lot.floor_at(sides[1], level_index) == null:
		return false
	var a := lot.blocking_object_at(sides[0], level_index)
	return a == null or a != lot.blocking_object_at(sides[1], level_index)


# --- Clôtures ---------------------------------------------------------------------

func can_hold_fence(edge: Vector3i) -> bool:
	# Les clôtures sont au jardin : au rez-de-chaussée seulement.
	if level_index > 0 or not lot.contains_edge(edge) or lot.has_wall(edge, level_index):
		return false
	var sides := Edges.sides(edge)
	var a := lot.blocking_object_at(sides[0], level_index)
	return a == null or a != lot.blocking_object_at(sides[1], level_index)


## Devis pour une clôture : segments nouveaux (ou d'un autre style, l'ancien est revendu), coût, validité.
func quote_fences(edges: Array[Vector3i], definition: FenceDefinition) -> Dictionary:
	var fresh: Array[Vector3i] = []
	var cost := 0
	var valid := not edges.is_empty()
	for edge in edges:
		if not can_hold_fence(edge):
			valid = false
			continue
		var current: PlacedFence = lot.fences.get(edge)
		if current != null and current.definition == definition:
			continue
		fresh.append(edge)
		cost += definition.price_per_segment - (Wallet.resale_value(current) if current != null else 0)
	return {"edges": fresh, "cost": cost, "valid": valid and not fresh.is_empty()}


func build_fences(edges: Array[Vector3i], definition: FenceDefinition) -> bool:
	var quote := quote_fences(edges, definition)
	var cost: int = quote["cost"]
	if not quote["valid"] or (cost > 0 and not Wallet.pay(cost)):
		return false
	if cost < 0:
		Wallet.receive(-cost)
	var previous: Dictionary = {}
	for edge in quote["edges"]:
		previous[edge] = lot.fences.get(edge)
		var fence := PlacedFence.new()
		fence.definition = definition
		Wallet.stamp(fence, definition.price_per_segment)
		lot.fences[edge] = fence
		EventBus.item_bought.emit(fence, fence.price)
	var revert := func() -> void:
		for edge in previous:
			if previous[edge] == null:
				lot.fences.erase(edge)
			else:
				lot.fences[edge] = previous[edge]
	_commit(revert, -cost)
	return true


# --- Portes et fenêtres ---------------------------------------------------------

## Devis pour poser une ouverture à partir de `edge` : il faut un mur (une clôture pour un portail)
## sans ouverture sur chaque segment.
func quote_opening(edge: Vector3i, definition: OpeningDefinition) -> Dictionary:
	var valid := true
	for i in definition.width_segments:
		var segment := Edges.next_along(edge, i)
		var holder := lot.fences.has(segment) if definition.on_fence else lot.has_wall(segment, level_index)
		if not holder or lot.opening_at(segment, level_index) != null:
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
	data.openings.append(opening)
	EventBus.item_bought.emit(opening, opening.price)
	_commit(func() -> void: data.openings.erase(opening), -quote["cost"])
	return true


# --- Piscine --------------------------------------------------------------------

## Prix d'une case de piscine.
const POOL_PRICE_PER_CELL := 60


## Devis d'une piscine : au jardin (rez-de-chaussée, hors des pièces), sans objet, mur ni clôture
## qui la traverse, et sans Mouz dedans.
func quote_pool(rect: Rect2i) -> Dictionary:
	var result := {"cells": [], "cost": 0, "valid": false, "reason": ""}
	if level_index > 0:
		result["reason"] = "La piscine se creuse au jardin"
		return result
	if rect.intersection(Rect2i(Vector2i.ZERO, lot.size)) != rect:
		result["reason"] = "Hors du terrain"
		return result
	var interior := lot.interior_cells(0)
	var cells: Array[Vector2i] = []
	for cell in _cells_in(rect):
		if interior.has(cell):
			result["reason"] = "Pas dans une pièce"
			return result
		if _object_on(cell) != null:
			result["reason"] = "Un objet est sur le passage"
			return result
		for step in [Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if rect.has_point(next) and (lot.has_wall(Edges.between(cell, next)) or lot.fences.has(Edges.between(cell, next))):
				result["reason"] = "Un mur ou une clôture la traverse"
				return result
		for character in world.people:
			if character.get_cell() == cell:
				result["reason"] = "Un Mouz est dans le passage"
				return result
		if not lot.pool.has(cell):
			cells.append(cell)
	if cells.is_empty():
		result["reason"] = "Déjà creusée"
		return result
	result["cells"] = cells
	result["cost"] = cells.size() * POOL_PRICE_PER_CELL
	result["valid"] = true
	return result


func build_pool(rect: Rect2i) -> bool:
	var quote := quote_pool(rect)
	if not quote["valid"] or not Wallet.pay(quote["cost"]):
		return false
	var cells: Array = quote["cells"]
	for cell in cells:
		var water := PlacedPool.new()
		Wallet.stamp(water, POOL_PRICE_PER_CELL)
		lot.pool[cell] = water
		EventBus.item_bought.emit(water, water.price)
	var revert := func() -> void:
		for cell in cells:
			lot.pool.erase(cell)
	_commit(revert, -quote["cost"])
	return true


# --- Toit -----------------------------------------------------------------------

## Option « sans toit » de l'outil (identifiant réservé).
const NO_ROOF := &"sans_toit"


## Devis d'un style de toit pour toute la maison : prix des cases couvertes, moins la revente de l'ancien.
func quote_roof(definition: RoofDefinition) -> Dictionary:
	var current := lot.roof
	var removing := definition.id == NO_ROOF
	if removing and current == null:
		return {"cost": 0, "valid": false, "reason": "Pas de toit"}
	if not removing and current != null and current.definition == definition:
		return {"cost": 0, "valid": false, "reason": "Déjà ce toit"}
	var cells := lot.roof_size()
	if not removing and cells == 0:
		return {"cost": 0, "valid": false, "reason": "Aucune pièce fermée à couvrir"}
	var cost := 0 if removing else cells * definition.price_per_cell
	if current != null:
		cost -= Wallet.resale_value(current)
	return {"cost": cost, "valid": true, "reason": "", "cells": cells}


func set_roof(definition: RoofDefinition) -> bool:
	var quote := quote_roof(definition)
	var cost: int = quote["cost"]
	if not quote["valid"] or (cost > 0 and not Wallet.pay(cost)):
		return false
	if cost < 0:
		Wallet.receive(-cost)
	var previous := lot.roof
	if previous != null:
		EventBus.item_sold.emit(previous, Wallet.resale_value(previous))
	if definition.id == NO_ROOF:
		lot.roof = null
	else:
		lot.roof = PlacedRoof.new()
		lot.roof.definition = definition
		Wallet.stamp(lot.roof, int(quote["cells"]) * definition.price_per_cell)
		EventBus.item_bought.emit(lot.roof, lot.roof.price)
	_commit(func() -> void: lot.roof = previous, -cost)
	return true


# --- Papier peint ---------------------------------------------------------------

## Option « retirer le papier peint » de l'outil (identifiant réservé).
const NO_WALLPAPER := &"retirer"


## Devis pour tapisser la pièce qui contient `cell` (ou retirer son papier peint) :
## segments concernés, coût net (l'ancien papier est revendu), validité et raison d'un refus.
func quote_wallpaper(cell: Vector2i, definition: WallpaperDefinition) -> Dictionary:
	var room := lot.room_cells(cell, level_index)
	if room.is_empty():
		return {"room": room, "edges": [], "cost": 0, "valid": false, "reason": "Clique dans une pièce fermée"}
	var removing := definition.id == NO_WALLPAPER
	var edges: Array[Vector3i] = []
	var cost := 0
	for edge in lot.room_wall_faces(room, level_index):
		var current: PlacedWallpaper = data.wallpapers.get(edge)
		if removing and current == null or not removing and current != null and current.definition == definition:
			continue
		edges.append(edge)
		if not removing:
			cost += definition.price_per_segment
		if current != null:
			cost -= Wallet.resale_value(current)
	var reason := "" if not edges.is_empty() else ("Pas de papier peint ici" if removing else "Déjà tapissée")
	return {"room": room, "edges": edges, "cost": cost, "valid": not edges.is_empty(), "reason": reason}


func apply_wallpaper(cell: Vector2i, definition: WallpaperDefinition) -> bool:
	var quote := quote_wallpaper(cell, definition)
	var cost: int = quote["cost"]
	if not quote["valid"] or (cost > 0 and not Wallet.pay(cost)):
		return false
	if cost < 0:
		Wallet.receive(-cost)
	var previous: Dictionary = {}
	for edge in quote["edges"]:
		previous[edge] = data.wallpapers.get(edge)
		if previous[edge] != null:
			EventBus.item_sold.emit(previous[edge], Wallet.resale_value(previous[edge]))
		if definition.id == NO_WALLPAPER:
			data.wallpapers.erase(edge)
			continue
		var paper := PlacedWallpaper.new()
		paper.definition = definition
		Wallet.stamp(paper, definition.price_per_segment)
		data.wallpapers[edge] = paper
		EventBus.item_bought.emit(paper, paper.price)
	var revert := func() -> void:
		for edge in previous:
			if previous[edge] == null:
				data.wallpapers.erase(edge)
			else:
				data.wallpapers[edge] = previous[edge]
	_commit(revert, -cost)
	return true


# --- Sols ------------------------------------------------------------------------

## Devis pour peindre un rectangle : cases à changer, coût net (l'ancien revêtement est revendu).
func quote_floor(rect: Rect2i, definition: FloorDefinition) -> Dictionary:
	var cells: Array[Vector2i] = []
	var cost := 0
	var unsupported := 0
	for cell in _cells_in(rect):
		if not supports_floor(cell):
			unsupported += 1
			continue
		var current: PlacedFloor = data.floors.get(cell)
		if current != null and current.definition == definition:
			continue
		cells.append(cell)
		cost += definition.price_per_cell
		if current != null:
			cost -= Wallet.resale_value(current)
	var reason := "" if not cells.is_empty() else (FLOOR_NEEDS_ROOM if unsupported > 0 else "")
	return {"cells": cells, "cost": cost, "valid": not cells.is_empty(), "reason": reason}


## Raison affichée quand un sol d'étage n'a rien dessous.
const FLOOR_NEEDS_ROOM := "Un sol d'étage se pose au-dessus d'une pièce fermée"


## Peut-on poser un sol sur cette case du niveau regardé ? Au rez-de-chaussée, partout ;
## à l'étage, au-dessus d'une pièce fermée du niveau du dessous, hors cage d'escalier.
func supports_floor(cell: Vector2i) -> bool:
	if level_index == 0:
		return true
	return lot.interior_cells(level_index - 1).has(cell) and not lot.is_stairwell(cell, level_index)


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
	var water: Array[Vector2i] = []
	for cell in _cells_in(rect):
		# À l'étage, on ne retire pas le plancher sous un objet.
		if data.floors.has(cell) and (level_index == 0 or _object_on(cell) == null):
			cells.append(cell)
			refund += Wallet.resale_value(data.floors[cell])
		# La gomme rebouche aussi la piscine.
		if level_index == 0 and lot.pool.has(cell):
			water.append(cell)
			refund += Wallet.resale_value(lot.pool[cell])
	return {"cells": cells, "pool": water, "refund": refund, "valid": not cells.is_empty() or not water.is_empty()}


func erase_floor(rect: Rect2i) -> bool:
	var quote := quote_erase(rect)
	if not quote["valid"]:
		return false
	Wallet.receive(quote["refund"])
	var previous := _replace_floors(quote["cells"], null)
	var filled: Dictionary = {}
	for cell in quote["pool"]:
		filled[cell] = lot.pool[cell]
		lot.pool.erase(cell)
		EventBus.item_sold.emit(filled[cell], Wallet.resale_value(filled[cell]))
	var revert := func() -> void:
		_restore_floors(previous)
		for cell in filled:
			lot.pool[cell] = filled[cell]
	_commit(revert, quote["refund"])
	return true


## L'objet posé sur cette case du niveau regardé (tapis compris), ou null.
func _object_on(cell: Vector2i) -> PlacedObject:
	for placed in data.objects:
		if placed.footprint().has_point(cell):
			return placed
	return null


## Pose `definition` (ou l'herbe si null) sur les cases ; renvoie les anciens revêtements.
func _replace_floors(cells: Array[Vector2i], definition: FloorDefinition) -> Dictionary:
	var previous := {}
	for cell in cells:
		previous[cell] = data.floors.get(cell)
		if previous[cell] != null:
			EventBus.item_sold.emit(previous[cell], Wallet.resale_value(previous[cell]))
		if definition == null:
			data.floors.erase(cell)
			continue
		var placed := PlacedFloor.new()
		placed.definition = definition
		Wallet.stamp(placed, definition.price_per_cell)
		data.floors[cell] = placed
		EventBus.item_bought.emit(placed, placed.price)
	return previous


func _restore_floors(previous: Dictionary) -> void:
	for cell in previous:
		if previous[cell] == null:
			data.floors.erase(cell)
		else:
			data.floors[cell] = previous[cell]


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
	# Une plantation achetée part des graines.
	if definition.grows:
		placed.growth = 0.0
	Wallet.stamp(placed, definition.price)
	data.objects.append(placed)
	EventBus.item_bought.emit(placed, placed.price)
	_commit(func() -> void: data.objects.erase(placed), -quote["cost"])
	return true


func sell_object(placed: PlacedObject) -> bool:
	if placed not in data.objects:
		return false
	var refund := Wallet.resale_value(placed)
	EventBus.object_displaced.emit(placed)
	data.objects.erase(placed)
	Wallet.receive(refund)
	EventBus.item_sold.emit(placed, refund)
	_commit(func() -> void: data.objects.append(placed), refund)
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
	if placed not in data.objects or not placed.definition.sprites.has(collection):
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
	var found: PlacedObject = lot.blocking_object_at(cell, level_index)
	if found != null:
		return found
	for placed in data.objects:
		if placed.footprint().has_point(cell):
			return placed
	return null


## Raison pour laquelle l'objet ne peut pas être posé là ("" s'il le peut).
func _placement_problem(ghost: PlacedObject, moving: PlacedObject) -> String:
	var rect := ghost.footprint()
	if not Rect2i(Vector2i.ZERO, lot.size).encloses(rect):
		return "Hors du terrain"
	for other in data.objects:
		if other == moving or not other.footprint().intersects(rect):
			continue
		# Un tapis peut passer sous un meuble, mais pas sous un autre tapis.
		if other.definition.blocks_movement == ghost.definition.blocks_movement:
			return "Place occupée"
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if x + 1 < rect.end.x and lot.has_wall(Edges.between(cell, cell + Vector2i.RIGHT), level_index):
				return "Un mur traverse l'objet"
			if y + 1 < rect.end.y and lot.has_wall(Edges.between(cell, cell + Vector2i.DOWN), level_index):
				return "Un mur traverse l'objet"
	if level_index == 0:
		# Le plongeoir avance au-dessus de l'eau : sa rangée de devant doit y être, le reste sur la terre.
		var over := ghost.definition.water_cells(rect, ghost.rotation)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				if lot.pool.has(cell) and not cell in over:
					return "Dans l'eau de la piscine"
				if cell in over and not lot.pool.has(cell):
					return "La planche doit avancer au-dessus de l'eau"
	# À l'étage, un objet se pose sur le plancher.
	if level_index > 0:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if lot.floor_at(Vector2i(x, y), level_index) == null:
					return "Il faut un plancher dessous"
	if ghost.definition.is_stairs:
		var problem := _stairs_problem(ghost)
		if problem != "":
			return problem
	if ghost.definition.blocks_movement:
		for character in world.people:
			var at := character.get_cell()
			if Levels.level_of(at) == level_index and rect.has_point(Levels.flat(at)):
				return "Un Mouz est dans le passage"
	# Un objet traversable (tapis de yoga) s'utilise en se tenant dessus.
	if not ghost.definition.actions.is_empty() and ghost.definition.blocks_movement:
		if _usable_spots(rect, moving).is_empty():
			return "Aucune place pour l'utiliser"
	return ""


## Un escalier monte au niveau suivant : il faut que ce niveau existe, un plancher au bout
## de la dernière marche, et rien à l'étage au-dessus des marches (la cage d'escalier).
func _stairs_problem(ghost: PlacedObject) -> String:
	if level_index >= Levels.COUNT - 1:
		return "Pas d'étage au-dessus"
	var path := GridNavigation.stairs_path(ghost, level_index)
	var exit := Levels.flat(path["exit"])
	if not lot.contains(exit) or lot.level(level_index + 1).floors.get(exit) == null:
		return "Il faut un plancher à l'étage, au bout de l'escalier"
	var above := lot.level(level_index + 1)
	for placed in above.objects:
		if placed.footprint().intersects(ghost.footprint()):
			return "Un objet de l'étage est au-dessus"
	var entry := Levels.flat(path["entry"])
	if not lot.contains(entry):
		return "Pas de place devant la première marche"
	return ""


## Cases libres autour de l'emprise, sans mur entre elles et l'objet.
func _usable_spots(rect: Rect2i, moving: PlacedObject) -> Array[Vector2i]:
	var spots: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var inner := Vector2i(x, y)
			for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
				var outer: Vector2i = inner + direction
				if rect.has_point(outer) or not lot.contains(outer) or lot.blocks_passage(inner, outer, level_index):
					continue
				if level_index > 0 and lot.floor_at(outer, level_index) == null:
					continue
				var blocker := lot.blocking_object_at(outer, level_index)
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
