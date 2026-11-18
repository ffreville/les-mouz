class_name SaveGame
extends Resource
## Ancien format de sauvegarde (user://partie.tres), lu une seule fois par SaveManager
## pour le convertir au format JSON. Ne plus l'utiliser pour enregistrer.
## Ce fichier doit rester à cet emplacement : les anciennes sauvegardes y font référence.

@export var lot: Lot
@export var funds: int = 0
@export var total_minutes: float = 0.0
