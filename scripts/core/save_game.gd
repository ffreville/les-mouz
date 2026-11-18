class_name SaveGame
extends Resource
## Contenu d'une sauvegarde : le terrain, l'argent et l'heure de jeu.
## Enregistrée dans user://partie.tres (voir SaveSystem).

@export var lot: Lot
@export var funds: int = 0
@export var total_minutes: float = 0.0
