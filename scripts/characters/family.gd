class_name Family
extends RefCounted
## La famille du joueur : nom de famille, 1 à 4 membres (prénom + apparence) et liens.
## Un lien relie deux membres voisins dans la liste et fixe leur relation de départ.

const MAX_MEMBERS := 4
## Liens possibles, dans l'ordre du menu : « a est … de b ».
const LINK_KINDS: Array[StringName] = [&"couple", &"parent", &"enfant", &"fratrie", &"colocs"]
const LINK_NAMES := {&"": "Aucun lien", &"couple": "Couple", &"parent": "Parent", &"enfant": "Enfant",
		&"fratrie": "Frères et sœurs", &"colocs": "Colocs"}
## Relation de départ selon le lien.
const LINK_START := {&"couple": 50.0, &"parent": 40.0, &"enfant": 40.0, &"fratrie": 30.0, &"colocs": 15.0}
## Modèle de fiche (besoins, vitesse) copié pour chaque membre.
const TEMPLATE := "res://data/characters/pepin.tres"

var family_name := ""
## Membres : { "id": String, "first_name": String, "appearance": MouzAppearance }.
var members: Array[Dictionary] = []
## Liens : { "a": id, "b": id, "kind": StringName }.
var links: Array[Dictionary] = []


func add_member(first_name: String, appearance: MouzAppearance) -> Dictionary:
	var member := {"id": _new_id(), "first_name": first_name, "appearance": appearance}
	members.append(member)
	return member


func remove_member(member: Dictionary) -> void:
	members.erase(member)
	var id: String = member["id"]
	links = links.filter(func(link: Dictionary) -> bool: return link["a"] != id and link["b"] != id)


func find(id: String) -> Dictionary:
	for member in members:
		if member["id"] == id:
			return member
	return {}


## Lien entre deux membres (&"" s'il n'y en a pas), vu depuis `a`.
func link_between(a: String, b: String) -> StringName:
	for link in links:
		if link["a"] == a and link["b"] == b:
			return link["kind"]
		if link["a"] == b and link["b"] == a:
			return _reverse(link["kind"])
	return &""


func set_link(a: String, b: String, kind: StringName) -> void:
	links = links.filter(func(link: Dictionary) -> bool: return not (link["a"] in [a, b] and link["b"] in [a, b]))
	if kind != &"":
		links.append({"a": a, "b": b, "kind": kind})


## « Couple », « Sa fille », « Son père »… : ce qu'est `other` pour `me`.
func link_label(me: String, other: String) -> String:
	var other_member := find(other)
	if other_member.is_empty():
		return ""
	var female: bool = other_member["appearance"].sex == &"femme"
	match link_between(other, me):
		&"couple":
			return "Couple"
		&"parent":
			return "Sa mère" if female else "Son père"
		&"enfant":
			return "Sa fille" if female else "Son fils"
		&"fratrie":
			return "Sa sœur" if female else "Son frère"
		&"colocs":
			return "Coloc"
	return ""


# --- Règles de l'écran de création ---------------------------------------------------

## Raison qui empêche de continuer ("" si la famille est prête).
func problem() -> String:
	for member in members:
		if String(member["first_name"]).strip_edges() == "":
			return "Donne un prénom à chaque membre."
	if not has_grown_up():
		return "Ajoute un adulte ou un aîné."
	return ""


func has_grown_up() -> bool:
	for member in members:
		if member["appearance"].age in [&"adulte", &"aine"]:
			return true
	return false


func display_name() -> String:
	return "Famille %s" % family_name if family_name.strip_edges() != "" else "Famille"


func first_names() -> String:
	var names: Array[String] = []
	for member in members:
		names.append(member["first_name"])
	if names.size() <= 1:
		return "".join(names)
	return "%s et %s" % [", ".join(names.slice(0, names.size() - 1)), names[-1]]


# --- Fiches des personnages ------------------------------------------------------------

## Une fiche de personnage par membre, copiée du modèle (besoins, vitesse).
func make_profiles() -> Array[CharacterProfile]:
	var template: CharacterProfile = load(TEMPLATE)
	var profiles: Array[CharacterProfile] = []
	for member in members:
		var profile: CharacterProfile = template.duplicate()
		profile.id = StringName(member["id"])
		profile.display_name = member["first_name"]
		profile.appearance = member["appearance"]
		profile.color = member["appearance"].outfit_color
		profiles.append(profile)
	return profiles


## Famille déduite de fiches existantes (scène de test, anciennes sauvegardes).
static func from_profiles(profiles: Array[CharacterProfile], p_name := "") -> Family:
	var family := Family.new()
	family.family_name = p_name
	for profile in profiles:
		var look: MouzAppearance = profile.appearance if profile.appearance != null else MouzAppearance.new()
		family.members.append({"id": String(profile.id), "first_name": profile.display_name, "appearance": look})
	return family


func to_dict() -> Dictionary:
	var list: Array = []
	for member in members:
		list.append({"id": member["id"], "first_name": member["first_name"],
				"appearance": member["appearance"].to_dict()})
	var link_list: Array = []
	for link in links:
		link_list.append({"a": link["a"], "b": link["b"], "kind": String(link["kind"])})
	return {"name": family_name, "members": list, "links": link_list}


static func from_dict(data: Dictionary) -> Family:
	var family := Family.new()
	family.family_name = data.get("name", "")
	for entry in data.get("members", []):
		family.members.append({"id": String(entry.get("id", "")), "first_name": String(entry.get("first_name", "")),
				"appearance": MouzAppearance.from_dict(entry.get("appearance", {}))})
	for entry in data.get("links", []):
		family.links.append({"a": String(entry["a"]), "b": String(entry["b"]), "kind": StringName(entry["kind"])})
	return family


static func _reverse(kind: StringName) -> StringName:
	match kind:
		&"parent":
			return &"enfant"
		&"enfant":
			return &"parent"
	return kind


func _new_id() -> String:
	var index := members.size() + 1
	while not find("mouz_%d" % index).is_empty():
		index += 1
	return "mouz_%d" % index
