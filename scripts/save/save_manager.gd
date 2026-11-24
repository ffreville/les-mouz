extends Node
## Autoload « SaveManager » : les parties enregistrées (une par dossier dans user://saves/).
## Une partie, c'est un quartier (voir Neighborhood) : ses emplacements, ses maisons et ses familles.
## On joue une famille à la fois (`active_plot`) ; l'heure est commune à tout le quartier.
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
const THUMBNAIL_SIZE := Vector2i(640, 360)
const GAME_SCENE := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
const NEIGHBORHOOD_SCENE := "res://scenes/neighborhood.tscn"
const FAMILY_SCENE := "res://scenes/new_game.tscn"
## Ancien emplacement unique (avant la gestion des sauvegardes).
const LEGACY_SAVE := "user://partie.tres"

## Partie en cours ("" si aucune : la partie n'est alors pas enregistrée).
var current_slot: String = ""
## Nom de la partie en cours.
var current_name: String = ""
## Le quartier de la partie en cours, tenu en mémoire (format de Neighborhood).
var neighborhood: Dictionary = {}
## Emplacement de la famille jouée ("" : on est sur l'écran du quartier).
var active_plot: String = ""
## Emplacement où une nouvelle famille est en train d'être créée (écran de création).
var moving_plot: String = ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	_migrate_legacy_save()


# --- Démarrer une partie -----------------------------------------------------------

## Lance une nouvelle partie : un nouveau quartier, avec ses familles tirées au hasard,
## enregistré tout de suite, puis l'écran du quartier.
func start_new_game(game_name := "") -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	neighborhood = Neighborhood.create(rng)
	current_slot = _new_slot_id()
	current_name = game_name.strip_edges() if game_name.strip_edges() != "" else neighborhood["name"]
	active_plot = ""
	GameClock.reset()
	_write_data(current_slot, current_name, _game_data())
	slots_changed.emit()
	go_to_neighborhood()


## Charge une partie enregistrée : la famille qu'on jouait, ou l'écran du quartier.
## Renvoie false si elle est illisible.
func load_slot(slot_id: String) -> bool:
	var data := read_slot(slot_id)
	if data.is_empty():
		return false
	current_slot = slot_id
	current_name = data.get("meta", {}).get("name", slot_id)
	neighborhood = data["neighborhood"]
	GameClock.restore(float(data.get("clock", {}).get("total_minutes", 0.0)))
	var plot_id: String = data.get("active_plot", "")
	if Neighborhood.has_household(Neighborhood.plot(neighborhood, plot_id)):
		play(plot_id)
	else:
		go_to_neighborhood()
	return true


## Joue la famille qui vit sur l'emplacement `plot_id`.
func play(plot_id: String) -> void:
	active_plot = plot_id
	GameClock.set_speed(1)
	GameMode.set_mode(GameMode.Mode.LIVE)
	get_tree().change_scene_to_file(GAME_SCENE)


## Ouvre la création d'une famille qui emménagera sur l'emplacement `plot_id`.
func create_family_for(plot_id: String) -> void:
	moving_plot = plot_id
	get_tree().change_scene_to_file(FAMILY_SCENE)


## La famille créée emménage sur l'emplacement (prix pris sur son budget de départ), puis on la joue.
func move_in(plot_id: String, family: Family) -> void:
	var plot := Neighborhood.plot(neighborhood, plot_id)
	if plot.is_empty():
		return
	plot["household"] = {"family": family.to_dict(), "funds": Wallet.settings.start_funds - int(plot["price"]),
			"moved_in_day": GameClock.get_day()}
	moving_plot = ""
	active_plot = plot_id
	_write_data(current_slot, current_name, _game_data())
	play(plot_id)


## Emplacement de la famille jouée ({} sans famille jouée).
func active_plot_data() -> Dictionary:
	return Neighborhood.plot(neighborhood, active_plot)


## Quitte la famille jouée (enregistrée) pour l'écran du quartier.
func leave_to_neighborhood(world: World) -> void:
	save_current(world)
	active_plot = ""
	_write_data(current_slot, current_name, _game_data())
	go_to_neighborhood()


func go_to_neighborhood() -> void:
	active_plot = ""
	GameClock.set_speed(0)
	GameMode.set_mode(GameMode.Mode.LIVE)
	get_tree().change_scene_to_file(NEIGHBORHOOD_SCENE)


## La partie la plus récemment enregistrée ("" s'il n'y en a pas).
func latest_slot() -> String:
	for slot in list_slots():
		if not slot["damaged"]:
			return slot["id"]
	return ""


func go_to_title() -> void:
	GameMode.set_mode(GameMode.Mode.LIVE)
	current_slot = ""
	current_name = ""
	neighborhood = {}
	active_plot = ""
	GameClock.set_speed(0)
	get_tree().change_scene_to_file(TITLE_SCENE)


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


## Enregistre la famille jouée dans son emplacement, puis tout le quartier.
func _write(slot_id: String, game_name: String, world: World) -> bool:
	if neighborhood.is_empty():
		_adopt_world(world)
	var plot := active_plot_data()
	if not plot.is_empty():
		plot["lot"] = LotSerializer.to_data(world.lot)
		plot["household"].merge(WorldSerializer.household_data(world), true)
	if not _write_data(slot_id, game_name, _game_data()):
		return false
	_write_thumbnail(world, _folder(slot_id).path_join(THUMBNAIL_FILE))
	saved.emit(slot_id)
	return true


## Jeu lancé sans quartier (main.tscn ouvert directement) : un quartier neuf, sans familles,
## où cette maison prend le premier emplacement libre.
func _adopt_world(world: World) -> void:
	neighborhood = Neighborhood.create(RandomNumberGenerator.new(), false)
	var free: Array = neighborhood["plots"].filter(func(p: Dictionary) -> bool: return p["house_name"] == "")
	var plot: Dictionary = free[0] if not free.is_empty() else neighborhood["plots"][0]
	plot["house_name"] = "Ma maison"
	plot["price"] = 0
	plot["household"] = {"family": world.family.to_dict(), "moved_in_day": GameClock.get_day()}
	active_plot = plot["id"]


## Données complètes de la partie en cours (quartier, heure, famille jouée).
func _game_data() -> Dictionary:
	return {
		"version": WorldSerializer.FORMAT_VERSION,
		"clock": {"total_minutes": GameClock.total_minutes, "speed": GameClock.speed_index},
		"neighborhood": neighborhood,
		"active_plot": active_plot,
	}


## Écrit les données avec leurs métadonnées (écran Charger).
func _write_data(slot_id: String, game_name: String, data: Dictionary) -> bool:
	var previous := read_meta(slot_id)
	var plot := Neighborhood.plot(neighborhood, active_plot)
	var household: Dictionary = plot.get("household", {})
	data["meta"] = {
		"name": game_name,
		"created": previous.get("created", Time.get_unix_time_from_system()),
		"saved": Time.get_unix_time_from_system(),
		"day": GameClock.get_day(),
		"time": "%02d:%02d" % [GameClock.get_hour(), GameClock.get_minute()],
		"funds": int(household.get("funds", -1)) if not household.is_empty() else -1,
		"family": Family.from_dict(household["family"]).display_name() if not household.is_empty() else "",
		"families": Neighborhood.household_count(neighborhood),
		"objects": plot.get("lot", {}).get("objects", []).size(),
	}
	var folder := _folder(slot_id)
	DirAccess.make_dir_recursive_absolute(folder)
	return _write_safely(folder.path_join(DATA_FILE), JSON.stringify(data, "\t"))


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
## { "id", "name", "saved", "day", "time", "funds", "objects", "thumbnail" (Texture2D ou null),
##   "damaged" (data.json illisible), "restorable" (la copie .bak, elle, se lit) }.
func list_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for slot_id in DirAccess.get_directories_at(SAVES_DIR):
		var path := _folder(slot_id).path_join(DATA_FILE)
		var main := _read_json(path)
		var meta := {}
		if not main.is_empty():
			meta = WorldSerializer.migrate(main).get("meta", {}).duplicate()
			meta["damaged"] = false
		else:
			var backup := _read_json(path + BACKUP_SUFFIX)
			meta = WorldSerializer.migrate(backup).get("meta", {}).duplicate() if not backup.is_empty() else {}
			meta["damaged"] = true
			meta["restorable"] = not backup.is_empty()
			meta["backup_day"] = meta.get("day", 0)
			if not meta.has("name"):
				meta["name"] = slot_id
			if not meta.has("saved"):
				meta["saved"] = FileAccess.get_modified_time(_folder(slot_id))
		meta["id"] = slot_id
		meta["thumbnail"] = _load_thumbnail(slot_id)
		slots.append(meta)
	slots.sort_custom(func(a, b): return float(a.get("saved", 0)) > float(b.get("saved", 0)))
	return slots


## Remet la copie de secours (.bak) à la place d'une sauvegarde abîmée.
func restore_slot(slot_id: String) -> bool:
	var path := _folder(slot_id).path_join(DATA_FILE)
	if _read_json(path + BACKUP_SUFFIX).is_empty():
		return false
	DirAccess.remove_absolute(path)
	var ok := DirAccess.copy_absolute(path + BACKUP_SUFFIX, path) == OK
	slots_changed.emit()
	return ok


## Famille jouée en dernier dans la dernière partie (portraits de l'accueil), ou {} s'il n'y en a pas.
func latest_family() -> Dictionary:
	var latest := latest_slot()
	if latest == "":
		return {}
	var data := read_slot(latest)
	var hood: Dictionary = data.get("neighborhood", {})
	var plot := Neighborhood.plot(hood, data.get("active_plot", ""))
	if not Neighborhood.has_household(plot):
		for entry in hood.get("plots", []):
			if Neighborhood.has_household(entry):
				plot = entry
				break
	return plot.get("household", {}).get("family", {})


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
	if parsed is Dictionary and (parsed.has("neighborhood") or parsed.has("lot")):
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
