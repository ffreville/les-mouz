class_name ClockSettings
extends Resource
## Réglages de l'horloge de jeu (équilibrage du rythme du temps).

## Minutes de jeu qui s'écoulent pendant une seconde réelle, à la vitesse x1.
@export var game_minutes_per_second: float = 4.0
## Jour de départ de la partie.
@export var start_day: int = 1
## Heure de départ de la partie.
@export_range(0, 23) var start_hour: int = 8
## Multiplicateur de chaque vitesse. Index 0 = pause, puis x1, x2, x3.
@export var speed_multipliers: Array[float] = [0.0, 1.0, 2.0, 3.0]
## Texte des boutons de vitesse, dans le même ordre que `speed_multipliers`.
@export var speed_labels: Array[String] = ["Pause", "x1", "x2", "x3"]
