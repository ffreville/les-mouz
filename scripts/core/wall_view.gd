class_name WallView
extends Node2D
## Dessine les murs (8 px, posés sur les lignes de la grille) et les portes et fenêtres.
## Calque au-dessus des objets.

var _lot: Lot


func render(lot: Lot) -> void:
	_lot = lot
	queue_redraw()


func _draw() -> void:
	if _lot == null:
		return
	var cs := float(_lot.cell_size)
	var covered := {}
	for opening in _lot.openings:
		for edge in opening.edges():
			covered[edge] = true
	# Chaque segment est prolongé de 4 px pour fermer les angles.
	for edge in _lot.walls:
		if not covered.has(edge):
			var rect := Edges.to_rect(edge, cs, Palette.EPAISSEUR_MUR, Palette.EPAISSEUR_MUR / 2)
			draw_rect(rect, _lot.walls[edge].style.color)
	for opening in _lot.openings:
		draw_opening(self, opening, cs)


## Dessine une porte ou une fenêtre sur `canvas` (aussi utilisé par les aperçus de l'éditeur).
## Le sprite est dessiné pour un mur horizontal, pièce en dessous ; on le tourne selon le mur.
static func draw_opening(canvas: CanvasItem, opening: PlacedOpening, cs: float, modulate := Color.WHITE) -> void:
	var sprite := opening.definition.sprite
	if sprite == null:
		return
	var length := cs * opening.definition.width_segments
	var start := Vector2(opening.edge.x, opening.edge.y) * cs
	var center: Vector2
	var angle: float
	if opening.edge.z == Edges.HORIZONTAL:
		center = start + Vector2(length / 2, 0)
		angle = 0.0 if opening.swing_positive else PI
	else:
		center = start + Vector2(0, length / 2)
		angle = -PI / 2 if opening.swing_positive else PI / 2
	var flip := -1.0 if opening.hinge_flipped else 1.0
	canvas.draw_set_transform(center, angle, Vector2(flip, 1))
	var thickness := Palette.EPAISSEUR_MUR
	canvas.draw_texture_rect(sprite, Rect2(Vector2(-length / 2, -thickness / 2), sprite.get_size()), false, modulate)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
