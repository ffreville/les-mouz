class_name Catalog
extends RefCounted
## Charge les éléments achetables rangés dans data/catalog/ : il suffit d'y déposer un .tres.

const FLOORS := "res://data/catalog/floors"
const WALLS := "res://data/catalog/walls"
const OPENINGS := "res://data/catalog/openings"
const WALLPAPERS := "res://data/catalog/wallpapers"
const FENCES := "res://data/catalog/fences"
const ROOFS := "res://data/catalog/roofs"
const OBJECTS := "res://data/catalog/objects"
const COLLECTIONS := "res://data/catalog/collections"

## Catégories d'objets, dans l'ordre d'affichage : [identifiant, nom, icône].
const CATEGORIES := [
	[&"cuisine", "Cuisine"],
	[&"chambre", "Chambre"],
	[&"salon", "Salon"],
	[&"salle_de_bain", "Salle de bain"],
	[&"loisirs", "Loisirs"],
	[&"jardin", "Jardin"],
	[&"deco", "Déco"],
	[&"securite", "Sécurité"],
	[&"construire", "Construction"],
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


## L'élément d'un dossier qui porte cet identifiant, ou null.
static func find(folder: String, id: StringName) -> Resource:
	for item in load_folder(folder):
		if item.id == id:
			return item
	return null


## Les collections de styles, dans leur ordre d'affichage.
static func collections() -> Array:
	var items: Array = load_folder(COLLECTIONS).duplicate()
	items.sort_custom(func(a, b): return a.order < b.order)
	return items


## Vrai pour ce qu'on achète et revend : pas les flaques ni les bonshommes de neige, posés par le jeu.
static func is_sold(definition: SmartObjectDefinition) -> bool:
	for spec in CATEGORIES:
		if spec[0] == definition.category:
			return true
	return false


## Objets d'une catégorie.
static func objects_in(category: StringName) -> Array:
	return load_folder(OBJECTS).filter(func(o): return o.category == category)


static func _price(item: Resource) -> int:
	if item is CollectionDefinition:
		return item.order
	if item is FloorDefinition:
		return item.price_per_cell
	if item is RoofDefinition:
		return item.price_per_cell
	if item is WallStyleDefinition or item is WallpaperDefinition or item is FenceDefinition:
		return item.price_per_segment
	return item.price
