class_name StairsArt
extends RefCounted
## Les dessins de l'escalier (brief n° 7, `data/vue34/escalier.json`) : la ligne des marches de chaque vue
## (où se posent les pieds du Mouz) et les calques qui passent devant lui.
##  - vue `bas` : rien ne passe devant ;
##  - vue `haut` : les marches au-dessus de la marche n (`devant[n - 1]`, de 1 à 7) ;
##  - vues `gauche` et `droite` : la rampe.

const DATA := "res://data/vue34/escalier.json"
const SPRITES := "res://assets/sprites/%s"

static var _data: Dictionary = {}


## Points de la ligne des marches, en coordonnées du monde : { "depart", "marches" (8), "arrivee" }.
## `stairs` : l'escalier posé (son sprite donne le repère de l'image).
static func step_line(stairs: SmartObject) -> Dictionary:
	var entry := _entry(stairs)
	if entry.is_empty():
		return {}
	var origin := stairs.position + stairs.sprite_rect_local().position
	var line: Dictionary = entry["ligne_marches"]
	var steps: Array[Vector2] = []
	for point in line["marches"]:
		steps.append(origin + Vector2(point[0], point[1]))
	return {"depart": origin + Vector2(line["depart"][0], line["depart"][1]), "marches": steps,
			"arrivee": origin + Vector2(line["arrivee"][0], line["arrivee"][1])}


## Vue de l'escalier : bas, haut, gauche ou droite.
static func view(stairs: SmartObject) -> StringName:
	return SmartObjectDefinition.VIEWS[posmod(stairs.placed.rotation, 4)]


## Calque qui passe devant un Mouz sur la marche `step` (1 à 8), ou null ; et s'il faut le retourner.
static func front_layer(stairs: SmartObject, step: int) -> Array:
	var entry := _entry(stairs)
	var front = entry.get("devant", [])
	var current := view(stairs)
	if front is String and front != "":
		return [MouzLayers.texture(SPRITES % front.get_slice(" ", 0)), current == &"droite"]
	if front is Array and step >= 1 and step <= front.size():
		return [MouzLayers.texture(SPRITES % front[step - 1]), false]
	return [null, false]


static func _entry(stairs: SmartObject) -> Dictionary:
	if _data.is_empty():
		var json: JSON = load(DATA)
		_data = json.data if json != null else {}
	var collections: Dictionary = _data.get("collections", {})
	var collection: Dictionary = collections.get(String(stairs.placed.get_collection()), collections.get("nature", {}))
	var current := view(stairs)
	if collection.has(String(current)):
		return collection[String(current)]
	return {}
