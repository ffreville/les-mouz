class_name Catalog
extends RefCounted
## Charge les éléments achetables rangés dans data/catalog/ : il suffit d'y déposer un .tres.

const FLOORS := "res://data/catalog/floors"
const WALLS := "res://data/catalog/walls"
const OPENINGS := "res://data/catalog/openings"
const OBJECTS := "res://data/catalog/objects"

## Catégories d'objets, dans l'ordre d'affichage : [identifiant, nom, icône].
const CATEGORIES := [
	[&"cuisine", "Cuisine"],
	[&"chambre", "Chambre"],
	[&"salon", "Salon"],
	[&"salle_de_bain", "Salle de bain"],
	[&"deco", "Déco"],
]

static var _cache: Dictionary[String, Array] = {}


## Toutes les Resources d'un dossier du catalogue, triées par prix croissant.
static func load_folder(folder: String) -> Array:
	if _cache.has(folder):
		return _cache[folder]
	var items: Array = []
	for file in ResourceLoader.list_directory(folder):
		if file.ends_with(".tres"):
			items.append(load(folder.path_join(file)))
	items.sort_custom(func(a, b): return _price(a) < _price(b))
	_cache[folder] = items
	return items


## Objets d'une catégorie.
static func objects_in(category: StringName) -> Array:
	return load_folder(OBJECTS).filter(func(o): return o.category == category)


static func _price(item: Resource) -> int:
	if item is FloorDefinition:
		return item.price_per_cell
	if item is WallStyleDefinition:
		return item.price_per_segment
	return item.price
