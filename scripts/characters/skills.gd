class_name Skills
extends RefCounted
## Les compétences des Mouz : leur liste et la courbe de progression.
## Une action fait progresser la compétence nommée dans son champ `skill` (ActionDefinition),
## au prorata du temps passé dessus.

## [id, nom, icône, couleur de la barre].
const LIST := [
	[&"cuisine", "Cuisine", "cuisiner", Color("#E07A3F")],
	[&"informatique", "Informatique", "surfer", Color("#4A7FD6")],
	[&"musique", "Musique", "musique", Color("#9B5CC4")],
	[&"art", "Art", "peindre", Color("#D4558A")],
	[&"jardinage", "Jardinage", "jardiner", Color("#4E9A57")],
	[&"culture", "Culture", "lire", Color("#B08A3E")],
	[&"forme", "Forme", "yoga", Color("#2FA3A3")],
	[&"charisme", "Charisme", "discuter", Color("#D9A21E")],
	[&"bricolage", "Bricolage", "construire", Color("#7A6A58")],
]
const MAX_LEVEL := 10
## Minutes de jeu pour passer du niveau 0 au niveau 1 ; chaque niveau suivant en demande
## `LEVEL_GROWTH` de plus (niveau 9 → 10 : environ 11 h 30 ; 66 h en tout).
const FIRST_LEVEL_MINUTES := 60.0
const LEVEL_GROWTH := 70.0
## On apprend plus vite de bonne humeur (humeur ≥ GOOD_MOOD), plus lentement grognon.
const GOOD_MOOD := 65.0
const BAD_MOOD := 35.0
const MOOD_FACTORS := {&"bonne": 1.5, &"normale": 1.0, &"mauvaise": 0.5}
## Les jeunes apprennent plus vite.
const AGE_FACTORS := {&"enfant": 1.3, &"ado": 1.2, &"adulte": 1.0, &"aine": 0.9}


static func ids() -> Array:
	return LIST.map(func(entry: Array) -> StringName: return entry[0])


static func display_name(id: StringName) -> String:
	for entry in LIST:
		if entry[0] == id:
			return entry[1]
	return String(id)


static func icon(id: StringName) -> Texture2D:
	for entry in LIST:
		if entry[0] == id:
			return load("res://assets/icons/ink/%s.svg" % entry[2])
	return null


static func color(id: StringName) -> Color:
	for entry in LIST:
		if entry[0] == id:
			return entry[3]
	return Palette.ACCENT


## Minutes de pratique pour passer du niveau `level` au suivant.
static func minutes_for_next(level: int) -> float:
	return FIRST_LEVEL_MINUTES + LEVEL_GROWTH * level


## Niveau atteint avec `minutes` de pratique au total.
static func level_for(minutes: float) -> int:
	var level := 0
	while level < MAX_LEVEL and minutes >= minutes_for_next(level):
		minutes -= minutes_for_next(level)
		level += 1
	return level


## Avancement (0 à 1) vers le niveau suivant.
static func progress_for(minutes: float) -> float:
	var level := 0
	while level < MAX_LEVEL and minutes >= minutes_for_next(level):
		minutes -= minutes_for_next(level)
		level += 1
	return 1.0 if level >= MAX_LEVEL else minutes / minutes_for_next(level)
