class_name JobDefinition
extends Resource
## Un métier proposé dans les petites annonces : horaires, jours, salaire, âge minimum,
## ce que la journée de travail coûte (ou rapporte) aux besoins, et sa carrière :
## des grades (intitulé, salaire) débloqués par le niveau dans la compétence du métier.

@export var id: StringName = &"metier"
@export var display_name: String = "Métier"
## Phrase de l'annonce.
@export_multiline var description: String = ""
@export var icon: Texture2D
## Salaire du premier grade, versé à chaque retour du travail (Mz).
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


@export_group("Carrière")
## Compétence qui fait monter en grade.
@export var skill: StringName = &""
## Intitulé de chaque grade, du premier au dernier.
@export var grades: Array[String] = []
## Salaire de chaque grade (Mz par jour).
@export var grade_salaries: Array[int] = []
## Niveau de compétence demandé pour chaque grade (0 pour le premier).
@export var grade_levels: Array[int] = []


func grade_count() -> int:
	return maxi(1, grades.size())


## Intitulé du grade `grade` (à partir de 1).
func title(grade: int) -> String:
	return grades[grade - 1] if grade >= 1 and grade <= grades.size() else display_name


func salary_for(grade: int) -> int:
	return grade_salaries[grade - 1] if grade >= 1 and grade <= grade_salaries.size() else salary


## Niveau de compétence demandé pour atteindre `grade`.
func required_level(grade: int) -> int:
	return grade_levels[grade - 1] if grade >= 1 and grade <= grade_levels.size() else 0


## « Lun – Ven · 9 h – 17 h ».
func schedule_text() -> String:
	return "%s · %d h – %d h" % [JobBoard.days_text(days), start_hour, end_hour]


func works_on(weekday: int) -> bool:
	return weekday in days
