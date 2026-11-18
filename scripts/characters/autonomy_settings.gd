class_name AutonomySettings
extends Resource
## Équilibrage de l'autonomie (choix automatique des actions).
## Score d'une action = Σ (gain utile × urgence^exposant) − distance × pénalité.

## Délai entre deux réflexions quand la file est vide, en minutes de jeu.
@export var think_interval_minutes: float = 10.0
## Points retirés au score par case à parcourir.
@export var distance_penalty_per_cell: float = 0.5
## Plus l'exposant est grand, plus les besoins très bas sont prioritaires.
@export var urgency_exponent: float = 2.0
## En dessous de ce score, le personnage préfère ne rien faire.
@export var min_score: float = 5.0
