class_name WorldSerializer
extends RefCounted
## Convertit l'état de la famille jouée en données JSON (et inversement) : argent, famille,
## Mouz (position, besoins, relations, autonomie, métier, compétences), factures, caméra.
## Le terrain passe par LotSerializer, le quartier et l'heure par SaveManager (voir Neighborhood).
## `FORMAT_VERSION` augmente à chaque changement du format ; `migrate()` met les anciennes
## sauvegardes à jour.

const FORMAT_VERSION := 4
## Objets dont l'ancien sprite (format 1) avait la face avant en bas : depuis le format 2,
## tous les sprites ont la face en haut, on les tourne d'un demi-tour pour garder leur aspect.
const V1_FACE_DOWN_OBJECTS := ["frigo", "plan_travail", "lit", "tele", "douche", "lavabo"]


## Le foyer joué (rangé dans son emplacement du quartier, voir Neighborhood).
static func household_data(world: World) -> Dictionary:
	var characters: Array = []
	for character in world.characters:
		var relationships := {}
		for other in world.characters:
			if other != character:
				relationships[String(other.profile.id)] = character.relationships.get_value(other)
		characters.append({
			"profile": String(character.profile.id),
			"position": [character.standing_position().x, character.standing_position().y],
			"needs": character.needs.snapshot(),
			"relationships": relationships,
			"autonomy": character.brain.enabled,
			"job": character.job.to_dict(),
			"skills": character.skills.to_dict(),
		})
	var selected := world.selection.selected
	return {
		"funds": Wallet.funds,
		"family": world.family.to_dict(),
		"characters": characters,
		"bills": world.bills.to_dict(),
		"selected": String(selected.profile.id) if selected != null else "",
		"camera": {"position": [world.camera.position.x, world.camera.position.y], "zoom": world.camera.zoom.x},
	}


## Applique ce qui dépend des personnages et de la caméra, une fois le monde construit
## (foyer déjà joué : `data` contient "characters").
static func apply_to_world(world: World, data: Dictionary) -> void:
	var by_id := {}
	for character in world.characters:
		by_id[String(character.profile.id)] = character
	for entry in data.get("characters", []):
		var character: Character = by_id.get(entry.get("profile", ""))
		if character == null:
			continue
		var position: Array = entry.get("position", [])
		if position.size() == 2:
			var cell := world.navigation.world_to_cell(Vector2(position[0], position[1]))
			character.position = world.navigation.cell_to_world(world.navigation.nearest_walkable(cell))
		character.needs.restore(entry.get("needs", {}))
		character.brain.enabled = bool(entry.get("autonomy", true))
		character.job.restore(entry.get("job", {}))
		character.skills.restore(entry.get("skills", {}))
		var relationships: Dictionary = entry.get("relationships", {})
		for other_id in relationships:
			if by_id.has(other_id):
				character.relationships.restore_with(by_id[other_id], float(relationships[other_id]))
	world.bills.restore(data.get("bills", {}))
	if by_id.has(data.get("selected", "")):
		world.selection.select.call_deferred(by_id[data["selected"]])
	var camera: Dictionary = data.get("camera", {})
	var camera_position: Array = camera.get("position", [])
	if camera_position.size() == 2:
		world.camera.position = Vector2(camera_position[0], camera_position[1])
		var zoom := float(camera.get("zoom", 1.0))
		world.camera.zoom = Vector2(zoom, zoom)


## Met une sauvegarde d'un ancien format au format actuel.
## Renvoie un dictionnaire vide si elle vient d'une version plus récente du jeu.
static func migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version > FORMAT_VERSION:
		push_warning("Sauvegarde créée par une version plus récente du jeu (format %d)." % version)
		return {}
	if version < 2:
		# Format 2 : styles d'objets (Nature par défaut) et sprites tous face avant en haut.
		for entry in data.get("lot", {}).get("objects", []):
			if entry.get("object", "") in V1_FACE_DOWN_OBJECTS:
				entry["rotation"] = (int(entry.get("rotation", 0)) + 2) % 4
			entry["style"] = entry.get("style", "nature")
	if version < 3:
		# Format 3 : la famille (prénoms, apparences, liens). Les anciennes parties gardent
		# Pépin et Myrtille, devenus humains.
		var profiles: Array[CharacterProfile] = [load("res://data/characters/pepin.tres"),
				load("res://data/characters/myrtille.tres")]
		data["family"] = Family.from_profiles(profiles).to_dict()
	if version < 4:
		# Format 4 : la partie devient un quartier. L'ancienne maison prend le premier
		# emplacement libre, avec sa famille, qu'on continue de jouer.
		var hood := Neighborhood.create(RandomNumberGenerator.new(), false)
		var free: Array = hood["plots"].filter(func(p: Dictionary) -> bool: return p["house_name"] == "")
		var plot: Dictionary = free[0] if not free.is_empty() else hood["plots"][0]
		plot["house_name"] = "Ma maison"
		plot["price"] = 0
		plot["lot"] = data.get("lot", {})
		plot["household"] = {"family": data.get("family", {}), "funds": int(data.get("funds", 0)), "moved_in_day": 1,
				"characters": data.get("characters", []), "bills": data.get("bills", {}),
				"selected": data.get("selected", ""), "camera": data.get("camera", {})}
		for key in ["lot", "family", "funds", "characters", "bills", "selected", "camera"]:
			data.erase(key)
		data["neighborhood"] = hood
		data["active_plot"] = plot["id"]
	data["version"] = FORMAT_VERSION
	return data
