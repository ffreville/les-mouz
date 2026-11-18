class_name NeedDefinition
extends Resource
## Définition d'un besoin (Faim, Énergie…) et de son équilibrage.
## Les valeurs vont de 0 (vide) à 100 (comblé).

## Identifiant utilisé par les actions pour désigner ce besoin (ex. &"faim").
@export var id: StringName = &"besoin"
@export var display_name: String = "Besoin"
@export var color: Color = Color(0.4, 0.7, 0.4)
## Points perdus par heure de jeu.
@export var decay_per_hour: float = 5.0
## Poids de ce besoin dans le calcul de l'humeur générale.
@export var mood_weight: float = 1.0
## En dessous de ce seuil, le besoin est critique (signal EventBus.need_critical).
@export_range(0, 100) var critical_threshold: float = 20.0
## Valeur au début de la partie.
@export_range(0, 100) var start_value: float = 75.0
