class_name JobBoard
extends RefCounted
## Les petites annonces : chaque jour, une sélection de métiers tirée au sort (la même toute
## la journée). Le téléphone en montre moins que l'ordinateur.

const FOLDER := "res://data/jobs/"
const DAY_NAMES: Array[String] = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
const SHORT_DAYS: Array[String] = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
## Nombre d'annonces selon l'endroit où on les lit.
const OFFERS := {&"telephone": 3, &"ordinateur": 5}

static var _all: Array = []


## Tous les métiers, du mieux payé au moins bien payé.
static func all() -> Array:
	if _all.is_empty():
		for file in DirAccess.get_files_at(FOLDER):
			if file.ends_with(".tres") or file.ends_with(".tres.remap"):
				_all.append(load(FOLDER + file.trim_suffix(".remap")))
		_all.sort_custom(func(a, b): return a.salary > b.salary)
	return _all


static func find(id: StringName) -> JobDefinition:
	for job in all():
		if job.id == id:
			return job
	return null


## Annonces du jour `day`, lues sur `source` (&"telephone" ou &"ordinateur").
## Les annonces du téléphone sont les premières de celles de l'ordinateur.
static func offers(day: int, source: StringName) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("annonces-%d" % day)
	var shuffled := all().duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = swap
	return shuffled.slice(0, OFFERS.get(source, 3))


## Pourquoi ce Mouz ne peut pas prendre ce métier ("" s'il le peut).
static func problem(job: JobDefinition, age: StringName) -> String:
	if age == &"enfant":
		return "Trop jeune pour travailler"
	if job.min_age == &"adulte" and age == &"ado":
		return "Réservé aux adultes"
	return ""


## Jour de la semaine (0 = lundi) du jour de jeu `day` (le jour 1 est un lundi).
static func weekday(day: int) -> int:
	return posmod(day - 1, 7)


## « Lun – Ven », « Mer – Sam », ou la liste des jours s'ils ne se suivent pas.
static func days_text(days: Array[int]) -> String:
	var sorted := days.duplicate()
	sorted.sort()
	if sorted.is_empty():
		return ""
	if sorted.size() == 1:
		return SHORT_DAYS[sorted[0]]
	if sorted[-1] - sorted[0] == sorted.size() - 1:
		return "%s – %s" % [SHORT_DAYS[sorted[0]], SHORT_DAYS[sorted[-1]]]
	return ", ".join(sorted.map(func(d: int) -> String: return SHORT_DAYS[d]))
