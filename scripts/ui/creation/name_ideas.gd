class_name NameIdeas
extends RefCounted
## Prénoms et noms de famille tirés au hasard (bouton dé).

const FIRST_NAMES := {
	&"femme": ["Léa", "Nina", "Chloé", "Inès", "Jade", "Louise", "Alice", "Rose", "Zoé", "Lina",
			"Manon", "Camille", "Sarah", "Emma", "Margot", "Anna", "Mila", "Elsa", "Juliette", "Agathe"],
	&"homme": ["Théo", "Samir", "Hugo", "Lucas", "Noé", "Louis", "Jules", "Malo", "Gabriel", "Arthur",
			"Adam", "Raphaël", "Tom", "Nathan", "Émile", "Paul", "Victor", "Yanis", "Léon", "Michel"],
}
const FAMILY_NAMES := ["Lambert", "Martin", "Moreau", "Girard", "Fontaine", "Rousseau", "Bonnet",
		"Mercier", "Chevalier", "Garnier", "Leroy", "Perrin", "Diallo", "Nguyen", "Benali", "Silva"]


static func first_name(sex: StringName, rng: RandomNumberGenerator, avoid: Array = []) -> String:
	var choices: Array = FIRST_NAMES.get(sex, FIRST_NAMES[&"femme"]).filter(
			func(n: String) -> bool: return not n in avoid)
	return choices[rng.randi_range(0, choices.size() - 1)]


static func family_name(rng: RandomNumberGenerator) -> String:
	return FAMILY_NAMES[rng.randi_range(0, FAMILY_NAMES.size() - 1)]
