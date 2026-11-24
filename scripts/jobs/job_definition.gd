class_name JobDefinition
extends Resource
## Un métier proposé dans les petites annonces : horaires, jours, salaire, âge minimum,
## et ce que la journée de travail coûte (ou rapporte) aux besoins.

@export var id: StringName = &"metier"
@export var display_name: String = "Métier"
## Phrase de l'annonce.
@export_multiline var description: String = ""
@export var icon: Texture2D
## Salaire versé à chaque retour du travail (Mz).
@export var salary: int = 150
## Heures de début et de fin (heures pleines, dans la même journée).
@export_range(0, 23) var start_hour: int = 9
@export_range(1, 24) var end_hour: int = 17
## Jours travaillés : 0 = lundi … 6 = dimanche.
@export var days: Array[int] = [0, 1, 2, 3, 4]
## Âge minimum : &"ado" (petit boulot) ou &"adulte".
@export var min_age: StringName = &"adulte"
## Effet d'une journée de travail sur les besoins, appliqué au retour.
@export var need_changes: Dictionary[StringName, float] = {&"energie": -25.0, &"plaisir": -10.0}


## « Lun – Ven · 9 h – 17 h ».
func schedule_text() -> String:
	return "%s · %d h – %d h" % [JobBoard.days_text(days), start_hour, end_hour]


func works_on(weekday: int) -> bool:
	return weekday in days
