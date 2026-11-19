class_name MouzLayers
extends RefCounted
## Dessine une pile de calques teintés (sprite ou portrait d'un Mouz) dans un rectangle.
## Un calque absent (par exemple des cheveux sans partie arrière) est simplement ignoré.

static var _textures: Dictionary = {}


static func texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


## `layers` : [chemin, teinte, (remonte)] ; `bob` décale vers le haut les calques qui remontent
## (tête et cheveux pendant la marche) ; `flip` retourne l'ensemble (vue de droite).
static func draw(canvas: CanvasItem, layers: Array, rect: Rect2, flip := false, bob := 0.0,
		modulate := Color.WHITE) -> void:
	if flip:
		canvas.draw_set_transform(Vector2(rect.position.x * 2 + rect.size.x, 0), 0.0, Vector2(-1, 1))
	for layer in layers:
		var tex := texture(layer[0])
		if tex == null:
			continue
		var area := rect
		if layer.size() > 2 and layer[2]:
			area.position.y -= bob
		canvas.draw_texture_rect(tex, area, false, layer[1] * modulate)
	if flip:
		canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
