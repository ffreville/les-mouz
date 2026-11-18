class_name AutoSaver
extends Node
## Sauvegarde automatique de la partie en cours (voir SaveManager) : peu après chaque
## modification du terrain, au retour en mode Vivre, toutes les 2 minutes réelles,
## et à la fermeture du jeu.

@export var delay_after_change: float = 1.0
@export var periodic_interval: float = 120.0

var world: World
var _pending := Timer.new()
var _periodic := Timer.new()


func setup(p_world: World) -> void:
	world = p_world


func _ready() -> void:
	_pending.one_shot = true
	_pending.wait_time = delay_after_change
	_pending.timeout.connect(save_now)
	add_child(_pending)
	_periodic.wait_time = periodic_interval
	_periodic.timeout.connect(save_now)
	add_child(_periodic)
	_periodic.start()
	EventBus.lot_changed.connect(_pending.start)
	GameMode.mode_changed.connect(_on_mode_changed)


func _on_mode_changed(mode: int) -> void:
	if mode == GameMode.Mode.LIVE:
		save_now()


func save_now() -> void:
	if world != null and world.lot != null:
		SaveManager.save_current(world)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()
