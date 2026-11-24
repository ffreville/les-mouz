extends Node
## Bruitages (autoload `Sfx`). Les sons sont dans `assets/sons/<nom>.wav` : un fichier
## absent est simplement ignoré, et on peut remplacer chaque son par un vrai sans toucher au code.
##  - interface : clic de chaque bouton, messages de réussite ou d'échec ;
##  - achats : pose d'un objet, construction (murs, sols, portes), revente, refus ;
##  - maison : portes qui s'ouvrent, actions (eau, cuisson, piano…), besoin critique.
## Les sons de la maison sont placés dans le monde : plus faibles quand ils sont loin de l'écran.

const FOLDER := "res://assets/sons/%s.wav"
## Volume des bruitages (dB).
const VOLUME_DB := -6.0
## Écart minimal entre deux fois le même son (secondes), pour ne pas saturer.
const MIN_GAP := 0.08
## Distance au-delà de laquelle un son de la maison ne s'entend plus (px).
const MAX_DISTANCE := 900.0
## Son joué au début d'une action, selon son identifiant.
const ACTION_SOUNDS := {
	&"cuisiner": &"cuisson", &"preparer_repas": &"cuisson", &"barbecue": &"cuisson",
	&"rechauffer": &"micro_ondes",
	&"prendre_bain": &"eau", &"se_laver": &"eau", &"se_laver_mains": &"eau", &"faire_vaisselle": &"eau",
	&"faire_lessive": &"eau", &"lancer_vaisselle": &"eau", &"se_brosser_dents": &"eau", &"se_raser": &"eau",
	&"arroser": &"eau",
	&"allumer": &"interrupteur", &"eteindre": &"interrupteur",
	&"jouer_piano": &"piano",
	&"manger": &"manger", &"manger_table": &"manger", &"en_cas": &"manger",
}
## Son joué à la fin d'une action.
const ACTION_END_SOUNDS := {&"utiliser_toilettes": &"chasse"}

var enabled := true
var _streams: Dictionary = {}
var _last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	EventBus.item_bought.connect(_on_item_bought)
	EventBus.item_sold.connect(func(_item, _refund) -> void: play(&"vente"))
	EventBus.action_started.connect(_on_action_started)
	EventBus.action_finished.connect(_on_action_finished)
	EventBus.need_critical.connect(_on_need_critical)
	EventBus.skill_level_up.connect(func(_character, _skill, _level) -> void: play(&"niveau"))
	EventBus.grade_changed.connect(func(_character, _grade, up: bool) -> void: play(&"promotion" if up else &"alerte"))


## Joue un son de l'interface (même volume partout).
func play(sound: StringName, volume_offset := 0.0) -> void:
	var stream := _stream(sound)
	if stream == null or not _ready_to_play(sound):
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = VOLUME_DB + volume_offset
	_start(player)


## Joue un son de la maison à cet endroit du monde.
func play_at(sound: StringName, world_position: Vector2, volume_offset := 0.0) -> void:
	var stream := _stream(sound)
	if stream == null or not _ready_to_play(sound):
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = VOLUME_DB + volume_offset
	player.max_distance = MAX_DISTANCE
	player.position = world_position
	_start(player)


func _start(player: Node) -> void:
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _ready_to_play(sound: StringName) -> bool:
	if not enabled:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound, -10.0)) < MIN_GAP:
		return false
	_last_played[sound] = now
	return true


func _stream(sound: StringName) -> AudioStream:
	if not _streams.has(sound):
		var path := FOLDER % sound
		_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	return _streams[sound]


# --- Branchements -------------------------------------------------------------------

## Chaque bouton qui apparaît fait « clic » quand on appuie dessus.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind(&"clic"))


func _on_item_bought(item: Resource, _price: int) -> void:
	if item is PlacedObject:
		play(&"poser")
		play(&"achat", -4.0)
	else:
		play(&"construire")


func _on_action_started(character: Node, action: RefCounted) -> void:
	if action.definition == null:
		return
	var sound: StringName = ACTION_SOUNDS.get(action.definition.id, &"")
	if sound != &"":
		play_at(sound, character.standing_position())


func _on_action_finished(character: Node, action: RefCounted) -> void:
	if action.definition == null:
		return
	var sound: StringName = ACTION_END_SOUNDS.get(action.definition.id, &"")
	if sound != &"":
		play_at(sound, character.standing_position())


func _on_need_critical(character: Node, _need_id: StringName, _value: float) -> void:
	if character.is_selected:
		play(&"alerte", -2.0)
