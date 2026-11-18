extends Node
## Autoload « SaveManager » : les parties enregistrées (une par dossier dans user://saves/).
## Chaque partie contient :
##  - data.json : l'état complet (voir WorldSerializer), avec ses métadonnées sous "meta" ;
##  - data.json.bak : la version précédente, utilisée si data.json est abîmé ;
##  - vignette.png : une image de la partie pour l'écran Charger.
## L'écriture passe par un fichier temporaire : une coupure en pleine sauvegarde
## ne détruit jamais la dernière version valide.

## Une partie a été enregistrée (`slot_id`).
signal saved(slot_id: String)
## La liste des parties a changé (création, suppression, renommage).
signal slots_changed

const SAVES_DIR := "user://saves"
const DATA_FILE := "data.json"
const BACKUP_SUFFIX := ".bak"
const TEMP_SUFFIX := ".tmp"
const THUMBNAIL_FILE := "vignette.png"
const THUMBNAIL_SIZE := Vector2i(320, 180)
const GAME_SCENE := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
## Ancien emplacement unique (avant la gestion des sauvegardes).
const LEGACY_SAVE := "user://partie.tres"

## Partie en cours ("" si aucune : la partie n'est alors pas enregistrée).
var current_slot: String = ""
## Nom de la partie en cours.
var current_name: String = ""
## Données à appliquer au prochain démarrage du monde (vide pour une nouvelle partie).
var _pending: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	_migrate_legacy_save()


# --- Démarrer une partie -----------------------------------------------------------

## Lance une nouvelle partie sur un terrain vide.
func start_new_game(game_name: String) -> void:
	current_slot = _new_slot_id()
	current_name = game_name.strip_edges() if game_name.strip_edges() != "" else "Nouvelle partie"
	_pending = {}
	Wallet.set_funds(Wallet.settings.start_funds)
	GameClock.reset()
	GameClock.set_speed(1)
	GameMode.set_mode(GameMode.Mode.LIVE)
	get_tree().change_scene_to_file(GAME_SCENE)


## Charge une partie enregistrée. Renvoie false si elle est illisible.
func load_slot(slot_id: String) -> bool:
	var data := read_slot(slot_id)
	if data.is_empty():
		return false
	current_slot = slot_id
	current_name = data.get("meta", {}).get("name", slot_id)
	_pending = data
	GameMode.set_mode(GameMode.Mode.LIVE)
	get_tree().change_scene_to_file(GAME_SCENE)
	return true


## La partie la plus récemment enregistrée ("" s'il n'y en a pas).
func latest_slot() -> String:
	var slots := list_slots()
	return slots[0]["id"] if not slots.is_empty() else ""


func go_to_title() -> void:
	GameMode.set_mode(GameMode.Mode.LIVE)
	current_slot = ""
	current_name = ""
	get_tree().change_scene_to_file(TITLE_SCENE)


## Données à appliquer par le monde qui démarre (lues une seule fois).
func take_pending() -> Dictionary:
	var data := _pending
	_pending = {}
	return data


# --- Enregistrer -------------------------------------------------------------------

## Enregistre la partie en cours dans son emplacement. Sans emplacement, ne fait rien.
func save_current(world: World) -> bool:
	if current_slot == "":
		return false
	return _write(current_slot, current_name, world)


## Enregistre une copie sous un nouveau nom ; elle devient la partie en cours.
func save_as(world: World, game_name: String) -> bool:
	current_slot = _new_slot_id()
	current_name = game_name.strip_edges() if game_name.strip_edges() != "" else "Sans nom"
	var ok := _write(current_slot, current_name, world)
	slots_changed.emit()
	return ok


func _write(slot_id: String, game_name: String, world: World) -> bool:
	var data := WorldSerializer.to_data(world)
	var previous := read_meta(slot_id)
	data["meta"] = {
		"name": game_name,
		"created": previous.get("created", Time.get_unix_time_from_system()),
		"saved": Time.get_unix_time_from_system(),
		"day": GameClock.get_day(),
		"time": "%02d:%02d" % [GameClock.get_hour(), GameClock.get_minute()],
		"funds": Wallet.funds,
		"objects": world.lot.objects.size(),
	}
	var folder := _folder(slot_id)
	DirAccess.make_dir_recursive_absolute(folder)
	if not _write_safely(folder.path_join(DATA_FILE), JSON.stringify(data, "\t")):
		return false
	_write_thumbnail(world, folder.path_join(THUMBNAIL_FILE))
	saved.emit(slot_id)
	return true


## Écrit dans un fichier temporaire, garde l'ancienne version en .bak, puis remplace.
func _write_safely(path: String, text: String) -> bool:
	var temp := path + TEMP_SUFFIX
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_error("Sauvegarde impossible : %s (%s)" % [temp, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(text)
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, path + BACKUP_SUFFIX)
	return DirAccess.rename_absolute(temp, path) == OK


## Vignette rendue une image plus tard ; la liste des parties est rafraîchie ensuite.
func _write_thumbnail(world: World, path: String) -> void:
	if await ThumbnailCapture.capture(world, path, THUMBNAIL_SIZE):
		slots_changed.emit()


# --- Lire et gérer les emplacements --------------------------------------------------

## Toutes les parties, de la plus récente à la plus ancienne :
## { "id", "name", "saved", "day", "time", "funds", "objects", "thumbnail" (Texture2D ou null) }.
func list_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for slot_id in DirAccess.get_directories_at(SAVES_DIR):
		var meta := read_meta(slot_id)
		if meta.is_empty():
			continue
		meta["id"] = slot_id
		meta["thumbnail"] = _load_thumbnail(slot_id)
		slots.append(meta)
	slots.sort_custom(func(a, b): return float(a.get("saved", 0)) > float(b.get("saved", 0)))
	return slots


## Données complètes d'une partie, mises au format actuel ({} si illisible).
## Si data.json est abîmé, on essaie la version précédente (.bak).
func read_slot(slot_id: String) -> Dictionary:
	var path := _folder(slot_id).path_join(DATA_FILE)
	for candidate in [path, path + BACKUP_SUFFIX]:
		var data := _read_json(candidate)
		if not data.is_empty():
			if candidate != path:
				push_warning("Sauvegarde abîmée, version précédente utilisée : %s" % slot_id)
			return WorldSerializer.migrate(data)
	return {}


func read_meta(slot_id: String) -> Dictionary:
	var data := read_slot(slot_id)
	return data.get("meta", {}).duplicate() if not data.is_empty() else {}


func rename_slot(slot_id: String, new_name: String) -> bool:
	var data := read_slot(slot_id)
	if data.is_empty() or new_name.strip_edges() == "":
		return false
	data["meta"]["name"] = new_name.strip_edges()
	var ok := _write_safely(_folder(slot_id).path_join(DATA_FILE), JSON.stringify(data, "\t"))
	if slot_id == current_slot:
		current_name = new_name.strip_edges()
	slots_changed.emit()
	return ok


func delete_slot(slot_id: String) -> void:
	var folder := _folder(slot_id)
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	if slot_id == current_slot:
		current_slot = ""
	slots_changed.emit()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary and parsed.has("lot"):
		return parsed
	return {}


func _load_thumbnail(slot_id: String) -> Texture2D:
	var path := _folder(slot_id).path_join(THUMBNAIL_FILE)
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	return ImageTexture.create_from_image(image) if image != null else null


func _folder(slot_id: String) -> String:
	return SAVES_DIR.path_join(slot_id)


## Identifiant unique et lisible : partie_<horodatage>.
func _new_slot_id() -> String:
	var base := "partie_%d" % int(Time.get_unix_time_from_system())
	var slot_id := base
	var i := 2
	while DirAccess.dir_exists_absolute(_folder(slot_id)):
		slot_id = "%s_%d" % [base, i]
		i += 1
	return slot_id


# --- Ancien format -------------------------------------------------------------------

## Convertit l'ancienne sauvegarde unique (user://partie.tres) en une partie « Ma maison ».
func _migrate_legacy_save() -> void:
	if not FileAccess.file_exists(LEGACY_SAVE):
		return
	var legacy := ResourceLoader.load(LEGACY_SAVE, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame
	if legacy == null or legacy.lot == null:
		return
	var data := {
		"version": WorldSerializer.FORMAT_VERSION,
		"clock": {"total_minutes": legacy.total_minutes, "speed": 1},
		"funds": legacy.funds,
		"lot": LotSerializer.to_data(legacy.lot),
		"characters": [],
		"meta": {
			"name": "Ma maison", "created": Time.get_unix_time_from_system(),
			"saved": Time.get_unix_time_from_system(), "day": int(legacy.total_minutes / 1440.0) + 1,
			"time": "%02d:%02d" % [int(legacy.total_minutes / 60.0) % 24, int(legacy.total_minutes) % 60],
			"funds": legacy.funds, "objects": legacy.lot.objects.size(),
		},
	}
	var slot_id := _new_slot_id()
	DirAccess.make_dir_recursive_absolute(_folder(slot_id))
	if _write_safely(_folder(slot_id).path_join(DATA_FILE), JSON.stringify(data, "\t")):
		DirAccess.rename_absolute(LEGACY_SAVE, LEGACY_SAVE + ".ancien")
