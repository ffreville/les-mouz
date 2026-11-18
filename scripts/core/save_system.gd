class_name SaveSystem
extends RefCounted
## Lecture et écriture de la partie, et démarrage d'une nouvelle partie.

const PATH := "user://partie.tres"


static func has_save() -> bool:
	return FileAccess.file_exists(PATH)


## La partie enregistrée, ou null s'il n'y en a pas (ou si elle est illisible).
static func load_game() -> SaveGame:
	if not has_save():
		return null
	var saved := ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame
	if saved == null or saved.lot == null:
		push_warning("Sauvegarde illisible, nouvelle partie : %s" % PATH)
		return null
	return saved


static func save_game(lot: Lot) -> void:
	var saved := SaveGame.new()
	saved.lot = lot
	saved.funds = Wallet.funds
	saved.total_minutes = GameClock.total_minutes
	var error := ResourceSaver.save(saved, PATH)
	if error != OK:
		push_error("Échec de la sauvegarde (%s) : %s" % [error_string(error), PATH])


## Efface la sauvegarde, remet argent, temps et mode à zéro, et relance la scène.
static func new_game(tree: SceneTree) -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Wallet.set_funds(Wallet.settings.start_funds)
	GameClock.reset()
	GameMode.set_mode(GameMode.Mode.LIVE)
	tree.reload_current_scene()
