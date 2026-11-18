class_name SmartObjectDefinition
extends Resource
## Un type d'objet « intelligent » : son apparence (par collection) et les actions qu'il propose.

## Identifiant unique (sert à la sauvegarde et au catalogue). Ne pas le changer une fois publié.
@export var id: StringName = &"objet"
@export var display_name: String = "Objet"
## Image vue de dessus par collection (&"nature", &"retro", &"moderne"), face avant en haut,
## à la taille de l'objet (32 px par case).
@export var sprites: Dictionary[StringName, Texture2D] = {}
## Image « en marche » par collection (télé allumée, feu dans la cheminée…), facultative.
@export var active_sprites: Dictionary[StringName, Texture2D] = {}
## Couleur du rectangle dessiné si aucune image n'est fournie.
@export var color: Color = Color(0.6, 0.5, 0.4)
## Taille en cases.
@export var size: Vector2i = Vector2i.ONE
## Faux pour un objet au sol qu'on peut traverser (tapis…). On l'utilise en se tenant dessus.
@export var blocks_movement: bool = true
## Actions proposées. Un objet sans action est purement décoratif.
@export var actions: Array[ActionDefinition] = []
## Nombre de personnages pouvant l'utiliser en même temps.
@export var capacity: int = 1
## Prix d'achat en Mz.
@export var price: int = 100
## Catégorie du catalogue : cuisine, chambre, salon, salle_de_bain, loisirs, jardin ou deco.
@export var category: StringName = &"deco"


## Collections disponibles, dans l'ordre des sprites.
func collections() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(sprites.keys())
	return result


## Collection utilisée par défaut (la première disponible).
func default_collection() -> StringName:
	return sprites.keys()[0] if not sprites.is_empty() else &""


## Image à afficher pour une collection, en marche ou non (repli sur la collection par défaut).
func get_sprite(collection: StringName, active := false) -> Texture2D:
	if active and active_sprites.has(collection):
		return active_sprites[collection]
	if sprites.has(collection):
		return sprites[collection]
	return sprites.get(default_collection())


func has_active_sprite() -> bool:
	return not active_sprites.is_empty()
