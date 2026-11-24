class_name ActionDefinition
extends Resource
## Une action proposée par un objet (ou entre personnages) : durée et effets.
## Les gains sont des totaux, répartis régulièrement sur toute la durée.

@export var id: StringName = &"action"
## Texte affiché dans les menus et la file d'actions.
@export var display_name: String = "Action"
## Icône 24 × 24 affichée dans le menu, la file d'actions et la bulle au-dessus du personnage.
@export var icon: Texture2D
## Durée en minutes de jeu.
@export var duration_minutes: float = 30.0
## Points gagnés sur la durée totale, par identifiant de besoin (ex. &"faim": 60).
@export var need_gains: Dictionary[StringName, float] = {}
## Variation de la relation (actions sociales uniquement), sur la durée totale.
@export var relationship_gain: float = 0.0

# --- Activités partagées -----------------------------------------------------------

## Gains supplémentaires quand un autre Mouz utilise le même objet en même temps
## (échecs, apéro, repas à table…), sur la durée totale.
@export var shared_need_gains: Dictionary[StringName, float] = {}
## Relation gagnée avec chaque Mouz qui partage l'objet, sur la durée totale.
@export var shared_relationship_gain: float = 0.0

# --- Objet voisin -------------------------------------------------------------------

## Identifiant d'un objet qui doit se trouver à proximité (ex. &"tele" pour le canapé).
## Pendant l'action, cet objet passe « en marche » (la télé s'allume).
@export var nearby_object_id: StringName = &""
## Distance maximale, en cases, entre les deux objets.
@export var nearby_radius: int = 6

# --- Compétence ----------------------------------------------------------------------

## Compétence que l'action fait progresser (&"" : aucune). Voir `Skills.LIST`.
@export var skill: StringName = &""

# --- Revenu ------------------------------------------------------------------------

## Ce que rapporte l'action finie (tableau vendu, mission rendue…) : `earning_base`, plus
## `earning_per_level` par niveau dans sa compétence. 0 : l'action ne rapporte rien.
## Interrompue après au moins MIN_PAID_RATIO de sa durée, elle rapporte au prorata.
@export var earning_base: int = 0
@export var earning_per_level: int = 0
## Message de la recette (« %s vend un tableau »), %s étant le nom du Mouz.
@export var earning_text: String = ""

const MIN_PAID_RATIO := 0.25

# --- Autonomie ------------------------------------------------------------------------

## Faux : les Mouz ne la choisissent jamais d'eux-mêmes (travail à la maison).
@export var autonomous: bool = true

# --- Interrupteur -------------------------------------------------------------------

enum Switch { NONE, TURN_ON, TURN_OFF }
## Allumer ou éteindre l'objet (lampes) à la fin de l'action.
@export var switch: Switch = Switch.NONE


func earns() -> bool:
	return earning_base > 0 or earning_per_level > 0


## Recette de l'action finie, au niveau `level` de sa compétence.
func earning_for(level: int) -> int:
	return earning_base + earning_per_level * level
