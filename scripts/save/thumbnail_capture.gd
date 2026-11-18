class_name ThumbnailCapture
extends RefCounted
## Vignette d'une partie : le terrain entier vu d'en haut, sans l'interface.
## Une vue séparée (SubViewport) partage le monde 2D du jeu avec sa propre caméra,
## rend une seule image, puis disparaît. Rien n'est capturé sans rendu (mode headless).

const RENDER_SIZE := Vector2i(640, 360)
const MARGIN := 48.0


## Coroutine : la vignette est écrite une image plus tard. Renvoie true si elle l'a été.
static func capture(world: World, path: String, size: Vector2i) -> bool:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(world):
		return false
	var viewport := SubViewport.new()
	viewport.size = RENDER_SIZE
	viewport.world_2d = world.get_viewport().world_2d
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var camera := Camera2D.new()
	var lot_size := Vector2(world.lot.size * world.lot.cell_size)
	camera.position = lot_size / 2
	var fit := minf(RENDER_SIZE.x / (lot_size.x + MARGIN * 2), RENDER_SIZE.y / (lot_size.y + MARGIN * 2))
	camera.zoom = Vector2(fit, fit)
	viewport.add_child(camera)
	world.add_child(viewport)
	await RenderingServer.frame_post_draw
	var ok := false
	if is_instance_valid(viewport):
		var image := viewport.get_texture().get_image()
		if image != null and not image.is_empty():
			image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
			ok = image.save_png(path) == OK
		viewport.queue_free()
	return ok
