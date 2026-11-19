class_name SeatPlaces
extends RefCounted
## Places des objets où l'on s'installe (chaise, lit, canapé…), livrées par Claude Design
## dans `data/vue34/places.json` : pour chaque objet, collection et vue, une entrée par place.
##  - assis, tailleur, genoux : `decalage` du coin haut-gauche de l'image 32 × 64 du Mouz,
##    par âge, depuis le coin haut-gauche du sprite de l'objet ;
##  - allonge : `tete` (où poser le centre de la tête, dans le sprite), `rotation` et `pivot`.
## `devant` nomme le calque de l'objet qui passe devant le Mouz (`miroir_de` : à retourner).

const DATA := "res://data/vue34/places.json"
const SPRITES := "res://assets/sprites/%s"

static var _data: Dictionary = {}


## Place n° `index` (à partir de 0) de l'objet dans cette collection et cette vue ({} si aucune).
static func find(object_id: StringName, collection: StringName, view: StringName, index: int) -> Dictionary:
	var places: Array = _places().get(String(object_id), {}).get(String(collection), {}).get(String(view), [])
	return places[index] if index >= 0 and index < places.size() else {}


## De combien la tête et les cheveux descendent dans cette pose.
static func head_drop(pose: String, age: StringName) -> float:
	return float(_load().get("tete_dy", {}).get(pose, {}).get(String(age), 0.0))


## Calque de premier plan de la place (null s'il n'y en a pas).
static func front_texture(place: Dictionary) -> Texture2D:
	var file = place.get("devant")
	if file == null or String(file) == "":
		return null
	return MouzLayers.texture(SPRITES % file)


static func _places() -> Dictionary:
	return _load().get("places", {})


static func _load() -> Dictionary:
	if _data.is_empty():
		var json: JSON = load(DATA)
		_data = json.data if json != null else {}
	return _data
