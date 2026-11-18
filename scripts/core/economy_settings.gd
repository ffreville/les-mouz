class_name EconomySettings
extends Resource
## Équilibrage de l'argent du foyer.

## Budget au début d'une partie, en Mz.
@export var start_funds: int = 20000
## Part du prix rendue quand on revend le jour de l'achat.
@export_range(0.0, 1.0) var refund_same_day: float = 1.0
## Part du prix rendue les jours suivants.
@export_range(0.0, 1.0) var refund_later: float = 0.75
