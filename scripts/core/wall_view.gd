class_name WallView
extends Node2D
## Murs, portes et fenêtres en vue trois quarts.
## Chaque morceau (segment, poteau à chaque nœud, ouverture) est un Sprite2D posé à son
## point de tri : avec `y_sort_enabled`, il passe devant ou derrière les objets et les personnages.
## La hauteur suit GameMode : murs pleins, coupés (ceux qui cachent une pièce sont baissés) ou baissés.
## Les portes s'ouvrent quand un personnage est sur une des deux cases qu'elles séparent.

const WALL_PATH := "res://assets/murs/%s.svg"
const OPENING_PATH := "res://assets/ouvertures/%s.svg"
## Demi-épaisseur d'un mur : il est à cheval sur la ligne de la grille.
const HALF := 4.0
## Les ouvertures sont triées juste après le mur qu'elles recouvrent.
const OPENING_SORT_SHIFT := 0.5
## Le papier peint passe juste après le mur et ses poteaux, avant les ouvertures.
const WALLPAPER_SORT_SHIFT := 0.2
## Face visible d'un segment horizontal : sous le chaperon, au-dessus de la plinthe.
const FACE_TOP := 9.0
const FACE_BOTTOM := 6.0

static var _textures: Dictionary = {}

var _lot: Lot
## Niveau dessiné (voir Levels) et ses données.
var _level_index := 0
var _data: LotLevel
var _characters: Array = []
## Portes posées : { "sprite", "opening", "cells", "name", "open" }.
var _doors: Array[Dictionary] = []
## Cases à l'intérieur d'une pièce fermée.
var _interior: Dictionary = {}


func _ready() -> void:
	GameMode.mode_changed.connect(_on_view_changed)
	GameMode.wall_mode_changed.connect(_on_view_changed)


## `characters` : la liste (partagée) des personnages, pour ouvrir les portes ;
## `level` : le niveau à dessiner.
func render(lot: Lot, characters: Array = [], level := 0) -> void:
	_lot = lot
	_level_index = level
	_data = lot.level(level)
	_characters = characters
	_rebuild()


func _on_view_changed(_mode: int) -> void:
	if _lot != null:
		_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_doors.clear()
	_interior = _lot.interior_cells(_level_index)
	var nodes: Dictionary = {}
	for edge: Vector3i in _data.walls:
		_add_segment(edge)
		nodes[Vector2i(edge.x, edge.y)] = true
		nodes[Vector2i(edge.x, edge.y) + (Vector2i.RIGHT if edge.z == Edges.HORIZONTAL else Vector2i.DOWN)] = true
	for node: Vector2i in nodes:
		_add_pole(node)
	for opening in _data.openings:
		if not opening.definition.on_fence:
			_add_opening(opening)
	if _level_index == 0:
		for edge: Vector3i in _lot.fences:
			_add_fence(edge)


# --- Morceaux -----------------------------------------------------------------------

func _add_segment(edge: Vector3i) -> void:
	var style: StringName = _data.walls[edge].style.id
	var cs := float(_lot.cell_size)
	var point := Vector2(edge.x, edge.y) * cs
	if edge.z == Edges.HORIZONTAL:
		var inside := _interior.has(Vector2i(edge.x, edge.y))
		var name_ := "mur_%s_%s_h_%s" % [style, _level(_is_full(edge)), "int" if inside else "ext"]
		var sprite := _add_sprite(name_, WALL_PATH, Vector2(point.x + HALF, point.y + HALF))
		if inside and sprite != null and _data.wallpapers.has(edge):
			_add_wallpaper(_data.wallpapers[edge].definition, point, sprite.texture.get_height())
	else:
		var name_ := "mur_%s_%s_v" % [style, _level(_is_full(edge))]
		_add_sprite(name_, WALL_PATH, Vector2(point.x - HALF, point.y + cs - HALF))


## Papier peint sur la face visible du segment (entre le chaperon et la plinthe), qui déborde
## d'un demi-poteau de chaque côté pour que les segments voisins se raccordent.
func _add_wallpaper(definition: WallpaperDefinition, point: Vector2, height: float) -> void:
	var patch := WallpaperPatch.new()
	patch.definition = definition
	patch.width = float(_lot.cell_size)
	patch.height = height - FACE_TOP - FACE_BOTTOM
	patch.top = -height + FACE_TOP
	patch.position = Vector2(point.x, point.y + HALF + WALLPAPER_SORT_SHIFT)
	patch.top -= WALLPAPER_SORT_SHIFT
	add_child(patch)


## Poteau à un nœud de la grille : sa forme dépend des murs qui en partent.
func _add_pole(node: Vector2i) -> void:
	var around := {
		"n": Vector3i(node.x, node.y - 1, Edges.VERTICAL),
		"e": Vector3i(node.x, node.y, Edges.HORIZONTAL),
		"s": Vector3i(node.x, node.y, Edges.VERTICAL),
		"o": Vector3i(node.x - 1, node.y, Edges.HORIZONTAL),
	}
	var mask := ""
	var style: StringName = &""
	var full := false
	for letter in ["e", "o", "n", "s"]:
		var edge: Vector3i = around[letter]
		if _data.walls.has(edge):
			if style == &"":
				style = _data.walls[edge].style.id
			full = full or _is_full(edge)
	for letter in ["n", "e", "s", "o"]:
		if _data.walls.has(around[letter]):
			mask += letter
	if mask == "":
		return
	var name_ := "poteau_%s_%s_%s" % [style, _level(full), mask]
	if not "s" in mask:
		var inside := _interior.has(node) or _interior.has(node + Vector2i.LEFT)
		name_ += "_int" if inside else "_ext"
	var point := Vector2(node) * float(_lot.cell_size)
	_add_sprite(name_, WALL_PATH, Vector2(point.x - HALF, point.y + HALF))


## Segment de clôture (ou portail), trié sur son pied comme un mur.
func _add_fence(edge: Vector3i) -> void:
	var cs := float(_lot.cell_size)
	var piece := FencePiece.new()
	piece.definition = _lot.fences[edge].definition
	piece.horizontal = edge.z == Edges.HORIZONTAL
	piece.length = cs
	var point := Vector2(edge.x, edge.y) * cs
	piece.position = point + (Vector2(0, 1) if piece.horizontal else Vector2(0, cs))
	var opening := _lot.opening_at(edge, _level_index)
	if opening != null and opening.definition.on_fence:
		piece.gate = true
		_doors.append({"piece": piece, "cells": Edges.sides(edge), "open": false})
	add_child(piece)


## Calque de porte ou de fenêtre, posé sur le mur juste après lui.
func _add_opening(opening: PlacedOpening) -> void:
	var edge := opening.edge
	var level := _level(_is_full(edge))
	var horizontal := edge.z == Edges.HORIZONTAL
	var base := "%s_%s_%s" % [opening.definition.id, "h" if horizontal else "v", level]
	var cs := float(_lot.cell_size)
	var point := Vector2(edge.x, edge.y) * cs
	var bottom: Vector2
	if horizontal:
		bottom = Vector2(point.x + HALF, point.y + HALF)
	else:
		bottom = Vector2(point.x - HALF, point.y + cs * opening.definition.width_segments - HALF)
	var sprite := _add_sprite(base, OPENING_PATH, bottom, OPENING_SORT_SHIFT)
	if sprite == null:
		return
	sprite.flip_h = horizontal and opening.hinge_flipped
	if opening.definition.is_passable():
		var cells: Array[Vector2i] = []
		for covered in opening.edges():
			cells.append_array(Edges.sides(covered))
		_doors.append({"sprite": sprite, "cells": cells, "name": base, "open": false})


## Ajoute une image dont le bas-gauche est `bottom_left` ; le nœud est trié sur ce bas.
func _add_sprite(file: String, folder: String, bottom_left: Vector2, sort_shift := 0.0) -> Sprite2D:
	var texture := _texture(folder % file)
	if texture == null:
		push_warning("Image de mur manquante : %s" % file)
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = bottom_left + Vector2(0, sort_shift)
	sprite.offset = Vector2(0, -texture.get_height() - sort_shift)
	add_child(sprite)
	return sprite


static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


# --- Hauteur des murs ---------------------------------------------------------------

func _level(full: bool) -> String:
	return "plein" if full else "baisse"


## Le segment est-il à pleine hauteur ? En murs coupés, un mur horizontal est baissé
## quand il cache une pièce (la case au-dessus est à l'intérieur) ; les murs verticaux,
## qui ne cachent presque rien, restent pleins.
func _is_full(edge: Vector3i) -> bool:
	match GameMode.effective_wall_mode():
		GameMode.WallMode.FULL:
			return true
		GameMode.WallMode.LOW:
			return false
	if edge.z == Edges.VERTICAL:
		return true
	return not _interior.has(Vector2i(edge.x, edge.y - 1))


# --- Portes -------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if _doors.is_empty() or _lot == null:
		return
	var occupied := {}
	for character in _characters:
		if is_instance_valid(character) and character.level == _level_index:
			occupied[Vector2i((character.standing_position() / float(_lot.cell_size)).floor())] = true
	for door in _doors:
		var open := false
		for cell in door["cells"]:
			if occupied.has(cell):
				open = true
				break
		if open == door["open"]:
			continue
		door["open"] = open
		if door.has("piece"):
			door["piece"].gate_open = open
			if open:
				Sfx.play_at(&"porte", door["piece"].global_position)
			continue
		var texture := _texture(OPENING_PATH % (door["name"] + ("_ouverte" if open else "")))
		if texture != null:
			door["sprite"].texture = texture
		if open:
			Sfx.play_at(&"porte", door["sprite"].global_position)


## Dessine une porte ou une fenêtre vue de dessus sur `canvas` (aperçus de l'éditeur).
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
