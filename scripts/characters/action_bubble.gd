class_name ActionBubble
extends Node2D
## Bulle au-dessus du personnage : icône de l'action en cours et anneau de progression.

const RADIUS := 16.0
const ICON_SIZE := 16.0
const RING_RADIUS := 15.0
const RING_WIDTH := 3.0

var _queue: ActionQueue


func setup(queue: ActionQueue) -> void:
	_queue = queue


func _process(_delta: float) -> void:
	var action := _running_action()
	visible = action != null
	if visible:
		queue_redraw()


func _draw() -> void:
	var action := _running_action()
	if action == null:
		return
	draw_circle(Vector2.ZERO, RADIUS, Color.WHITE)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Palette.CONTOUR, 2.0, true)
	var progress := action.get_progress()
	if progress > 0.0:
		draw_arc(Vector2.ZERO, RING_RADIUS, -PI / 2, -PI / 2 + TAU * progress, 32,
				Palette.ACCENT, RING_WIDTH, true)
	var icon := action.definition.icon
	if icon != null:
		draw_texture_rect(icon, Rect2(-Vector2.ONE * ICON_SIZE / 2, Vector2.ONE * ICON_SIZE), false)


func _running_action() -> QueuedAction:
	if _queue == null:
		return null
	var action := _queue.current()
	if action == null or action.state != QueuedAction.State.RUNNING:
		return null
	return action
