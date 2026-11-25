class_name Neighborhood
extends RefCounted
## Le quartier d'une partie, sous forme de données de sauvegarde (JSON) :
##   { "name": String, "plots": [ emplacement… ] }
## Un emplacement :
##   { "id", "address", "house_name", "price" (prix d'achat), "lot" (LotSerializer),
##     "household" ({} si personne n'y vit) }
## Un foyer (« household ») :
##   { "family" (Family.to_dict), "funds", "moved_in_day",
##     et, une fois joué : "characters", "bills", "selected", "camera" (voir WorldSerializer) }
## Chaque famille a son argent ; l'heure est commune à tout le quartier.

const DEFINITION := "res://data/quartier/quartier.tres"
const ECONOMY := "res://data/settings/economy_settings.tres"
## Prix d'une maison livrée : cette part de ce qu'ont coûté ses murs, sols, ouvertures et objets,
## arrondie à PRICE_STEP.
const PRICE_RATIO := 0.7
const PRICE_STEP := 500
## Compositions des familles tirées au hasard : âges, et lien de chaque membre avec le précédent.
const COMPOSITIONS := [
	[[&"adulte"]],
	[[&"adulte"], [&"adulte", &"couple"]],
	[[&"adulte"], [&"adulte", &"couple"], [&"enfant", &"enfant"]],
	[[&"adulte"], [&"adulte", &"couple"], [&"ado", &"enfant"], [&"enfant", &"fratrie"]],
	[[&"adulte"], [&"ado", &"enfant"]],
	[[&"aine"], [&"adulte", &"enfant"]],
	[[&"adulte"], [&"adulte", &"colocs"]],
	[[&"aine"], [&"aine", &"couple"]],
]


## Un nouveau quartier, d'après sa définition. Avec `families`, des familles tirées au hasard
## emménagent dans autant de maisons (voir NeighborhoodDefinition.starting_families).
static func create(rng: RandomNumberGenerator, families := true) -> Dictionary:
	var definition: NeighborhoodDefinition = load(DEFINITION)
	var plots: Array = []
	for plot_definition in definition.plots:
		var lot: Lot = plot_definition.lot if plot_definition.lot != null else definition.empty_lot
		plots.append({
			"id": String(plot_definition.id),
			"address": plot_definition.address,
			"house_name": plot_definition.house_name,
			"price": price_of(lot),
			"lot": LotSerializer.to_data(lot),
			"household": {},
		})
	var data := {"name": definition.display_name, "plots": plots}
	if families:
		var houses: Array = plots.filter(func(plot: Dictionary) -> bool: return plot["house_name"] != "")
		houses.shuffle()
		var taken_names: Array = []
		var taken_families: Array = []
		for i in mini(definition.starting_families, houses.size()):
			var family := random_family(rng, taken_names, taken_families)
			var plot: Dictionary = houses[i]
			# Une famille déjà installée a payé sa maison et garde de quoi voir venir.
			var funds := maxi(start_funds() - int(plot["price"]), 2000) + rng.randi_range(0, 20) * 100
			plot["household"] = {"family": family.to_dict(), "funds": funds, "moved_in_day": 0}
	return data


## Budget d'une famille qui arrive dans le quartier.
static func start_funds() -> int:
	return (load(ECONOMY) as EconomySettings).start_funds


## L'emplacement `id` du quartier ({} s'il n'existe pas).
static func plot(data: Dictionary, id: String) -> Dictionary:
	for entry in data.get("plots", []):
		if entry["id"] == id:
			return entry
	return {}


static func has_household(plot_data: Dictionary) -> bool:
	return not plot_data.get("household", {}).is_empty()


## Nombre de familles installées.
static func household_count(data: Dictionary) -> int:
	return data.get("plots", []).filter(has_household).size()


## Ce qu'ont coûté les murs, sols, ouvertures et objets d'un terrain.
static func lot_value(lot: Lot) -> int:
	var total := 0
	for wall in lot.walls.values():
		total += wall.price
	for floor_piece in lot.floors.values():
		total += floor_piece.price
	for opening in lot.openings:
		total += opening.price
	for paper in lot.wallpapers.values():
		total += paper.price
	for fence in lot.fences.values():
		total += fence.price
	for placed in lot.objects:
		total += placed.price
	return total


## Prix d'achat d'un terrain (0 pour un terrain nu).
static func price_of(lot: Lot) -> int:
	return int(round(lot_value(lot) * PRICE_RATIO / PRICE_STEP)) * PRICE_STEP


## Une famille tirée au hasard, avec un nom et des prénoms pas encore pris dans le quartier.
static func random_family(rng: RandomNumberGenerator, taken_names: Array = [], taken_families: Array = []) -> Family:
	var family := Family.new()
	var names: Array = NameIdeas.FAMILY_NAMES.filter(func(n: String) -> bool: return not n in taken_families)
	family.family_name = names[rng.randi_range(0, names.size() - 1)] if not names.is_empty() else NameIdeas.family_name(rng)
	taken_families.append(family.family_name)
	var composition: Array = COMPOSITIONS[rng.randi_range(0, COMPOSITIONS.size() - 1)]
	var previous := {}
	for entry in composition:
		var look := MouzAppearance.new()
		look.age = entry[0]
		look.sex = &"femme" if rng.randf() < 0.5 else &"homme"
		# Un couple est mixte une fois sur deux… et pas toujours.
		if entry.size() > 1 and entry[1] == &"couple" and rng.randf() < 0.8:
			look.sex = &"homme" if previous["appearance"].sex == &"femme" else &"femme"
		look.randomize_look(rng)
		var first_name := NameIdeas.first_name(look.sex, rng, taken_names)
		taken_names.append(first_name)
		var member := family.add_member(first_name, look)
		if entry.size() > 1 and not previous.is_empty():
			# Le lien se lit « le précédent est … du nouveau » : un parent puis son enfant.
			family.set_link(previous["id"], member["id"], _link_from_previous(entry[1]))
		previous = member
	return family


## Dans COMPOSITIONS, le lien dit ce qu'est le nouveau membre pour le précédent (« enfant ») ;
## Family.set_link(a, b, kind) dit ce qu'est `a` pour `b`.
static func _link_from_previous(kind: StringName) -> StringName:
	match kind:
		&"enfant":
			return &"parent"
		&"parent":
			return &"enfant"
	return kind
