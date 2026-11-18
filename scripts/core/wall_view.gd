class_name WallView
extends Node2D
## Dessine les murs (8 px) et les seuils de porte, au-dessus des objets.
## Murs extérieurs : à l'extérieur du sol. Cloisons : centrées sur la limite entre deux cases.

const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

var _layout: HouseLayout


func render(layout: HouseLayout) -> void:
	_layout = layout
	queue_redraw()


func _draw() -> void:
	if _layout == null:
		return
	var thresholds: Array[Rect2] = []
	for y in _layout.grid_size.y:
		for x in _layout.grid_size.x:
			var cell := Vector2i(x, y)
			if not _layout.is_inside(cell):
				continue
			for direction in DIRECTIONS:
				var other := cell + direction
				var outside := not _layout.is_inside(other)
				# Une cloison n'est traitée qu'une fois (vers la droite ou le bas).
				if not outside and (direction == Vector2i.LEFT or direction == Vector2i.UP):
					continue
				if _layout.room_index_at(cell) == _layout.room_index_at(other):
					continue
				var wall := _wall_rect(cell, direction, outside)
				if _layout.has_wall_between(cell, other):
					draw_rect(wall.grow_side(_along_side(direction), Palette.EPAISSEUR_MUR)
							.grow_side(_along_side(direction) + 2, Palette.EPAISSEUR_MUR), Palette.MUR)
				else:
					thresholds.append(wall)
	# Les seuils sont dessinés en dernier pour couper proprement les murs.
	for threshold in thresholds:
		draw_rect(threshold, Palette.SEUIL)


## Bande de mur sur le côté `direction` de la case.
func _wall_rect(cell: Vector2i, direction: Vector2i, outside: bool) -> Rect2:
	var cs := float(_layout.cell_size)
	var t := Palette.EPAISSEUR_MUR
	var origin := Vector2(cell) * cs
	# Mur extérieur : entièrement dehors. Cloison : à cheval sur la limite.
	var offset := 0.0 if outside else t / 2.0
	match direction:
		Vector2i.RIGHT:
			return Rect2(origin.x + cs - offset, origin.y, t, cs)
		Vector2i.LEFT:
			return Rect2(origin.x - t + offset, origin.y, t, cs)
		Vector2i.DOWN:
			return Rect2(origin.x, origin.y + cs - offset, cs, t)
		_:
			return Rect2(origin.x, origin.y - t + offset, cs, t)


## Côté (SIDE_*) le long duquel on prolonge le mur pour fermer les angles.
func _along_side(direction: Vector2i) -> int:
	return SIDE_TOP if direction.x != 0 else SIDE_LEFT
