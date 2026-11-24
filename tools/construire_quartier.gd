extends SceneTree
## Construit le quartier livré avec le jeu : les maisons (data/quartier/maisons/*.tres)
## et le quartier lui-même (data/quartier/quartier.tres).
##   godot --headless --script tools/construire_quartier.gd
## Les maisons sont décrites ici en coordonnées de cases (terrain 30 × 20, la rue en bas).
## Pour retoucher une maison à la main, on peut aussi ouvrir son .tres dans l'éditeur ;
## relancer cet outil écrase alors la retouche.

const HOUSES_DIR := "res://data/quartier/maisons/%s.tres"
const NEIGHBORHOOD := "res://data/quartier/quartier.tres"
const EMPTY_LOT := "res://data/quartier/terrain_libre.tres"
const H := Edges.HORIZONTAL
const V := Edges.VERTICAL


func _initialize() -> void:
	var houses := {
		&"la_bicoque": la_bicoque(),
		&"les_glycines": les_glycines(),
		&"villa_horizon": villa_horizon(),
		&"le_potager": le_potager(),
		&"l_atelier": l_atelier(),
	}
	for id in houses:
		var error := ResourceSaver.save(houses[id], HOUSES_DIR % id)
		print("%s : %s" % [id, error_string(error)])
	var empty := Lot.new()
	empty.default_floor = Catalog.find(Catalog.FLOORS, &"herbe")
	empty.spawn_cells = [Vector2i(13, 16), Vector2i(15, 16)]
	ResourceSaver.save(empty, EMPTY_LOT)
	empty = load(EMPTY_LOT)

	var neighborhood := NeighborhoodDefinition.new()
	neighborhood.display_name = "Quartier des Tilleuls"
	neighborhood.empty_lot = empty
	# Rangée du haut (gauche → droite), puis rangée du bas.
	var plots := [
		[&"lilas_1", "1 rue des Lilas", "La Bicoque", &"la_bicoque"],
		[&"lilas_3", "3 rue des Lilas", "Les Glycines", &"les_glycines"],
		[&"lilas_5", "5 rue des Lilas", "", &""],
		[&"lilas_7", "7 rue des Lilas", "Villa Horizon", &"villa_horizon"],
		[&"lilas_2", "2 rue des Lilas", "Le Potager", &"le_potager"],
		[&"lilas_4", "4 rue des Lilas", "", &""],
		[&"lilas_6", "6 rue des Lilas", "L'Atelier", &"l_atelier"],
		[&"lilas_8", "8 rue des Lilas", "", &""],
	]
	for entry in plots:
		var plot := PlotDefinition.new()
		plot.id = entry[0]
		plot.address = entry[1]
		plot.house_name = entry[2]
		if entry[3] != &"":
			plot.lot = load(HOUSES_DIR % entry[3])
		neighborhood.plots.append(plot)
	print("quartier : %s" % error_string(ResourceSaver.save(neighborhood, NEIGHBORHOOD)))
	quit()


## Petite maison : une grande pièce à vivre, une chambre, une salle de bain.
func la_bicoque() -> Lot:
	var b := HouseBuilder.new(&"sauge", &"nature")
	b.room(Rect2i(8, 4, 9, 10), &"parquet")
	b.room(Rect2i(17, 4, 5, 6), &"moquette")
	b.room(Rect2i(17, 10, 5, 4), &"faience")
	b.door(Vector3i(12, 14, H)).door(Vector3i(17, 7, V)).door(Vector3i(17, 12, V))
	b.window(Vector3i(9, 4, H), true).window(Vector3i(19, 4, H)).window(Vector3i(22, 11, V)).window(Vector3i(8, 9, V))
	# Cuisine en haut, salon en bas.
	b.put(&"cuisiniere", Vector2i(12, 4), 2).put(&"plan_travail", Vector2i(13, 4), 2).put(&"frigo", Vector2i(16, 4), 2)
	b.put(&"table", Vector2i(13, 8)).put(&"chaise", Vector2i(15, 8), 3).put(&"chaise", Vector2i(15, 9), 3)
	b.put(&"canape", Vector2i(9, 9), 2).put(&"tele", Vector2i(9, 13), 0).put(&"plante", Vector2i(16, 13))
	b.put(&"poubelle", Vector2i(8, 4), 2)
	# Chambre.
	b.put(&"lit", Vector2i(19, 4), 2).put(&"table_nuit", Vector2i(21, 4), 2).put(&"commode", Vector2i(20, 9), 0)
	# Salle de bain.
	b.put(&"lavabo", Vector2i(19, 10), 2).put(&"toilettes", Vector2i(21, 10), 3).put(&"douche", Vector2i(20, 12), 3)
	# Jardin.
	b.put(&"arbre", Vector2i(2, 14)).put(&"arbre", Vector2i(25, 3)).put(&"plante", Vector2i(10, 15))
	return b.spawn([Vector2i(12, 16), Vector2i(13, 16)]).build()


## Maison de famille : salon, cuisine, deux chambres (dont celle des enfants), salle de bain.
func les_glycines() -> Lot:
	var b := HouseBuilder.new(&"brique", &"retro")
	b.room(Rect2i(5, 3, 9, 7), &"parquet_fonce")
	b.room(Rect2i(14, 3, 11, 7), &"tomettes")
	b.room(Rect2i(5, 10, 7, 5), &"moquette")
	b.room(Rect2i(12, 10, 5, 5), &"faience")
	b.room(Rect2i(17, 10, 8, 5), &"moquette")
	b.door(Vector3i(5, 6, V), false).door(Vector3i(14, 6, V)).door(Vector3i(9, 10, H)).door(Vector3i(14, 10, H)).door(Vector3i(20, 10, H))
	b.window(Vector3i(7, 3, H), true).window(Vector3i(20, 3, H)).window(Vector3i(7, 15, H), true).window(Vector3i(20, 15, H))
	b.window(Vector3i(25, 6, V))
	# Salon.
	b.put(&"tele", Vector2i(8, 3), 2).put(&"canape", Vector2i(8, 7), 0).put(&"bibliotheque", Vector2i(5, 3), 1)
	b.put(&"fauteuil", Vector2i(12, 4), 3).put(&"lampe_pied", Vector2i(12, 3), 2).put(&"tapis", Vector2i(6, 5)).put(&"plante", Vector2i(13, 9))
	# Cuisine.
	b.put(&"frigo", Vector2i(14, 3), 2).put(&"plan_travail", Vector2i(15, 3), 2).put(&"cuisiniere", Vector2i(18, 3), 2)
	b.put(&"lave_vaisselle", Vector2i(19, 3), 2).put(&"poubelle", Vector2i(24, 3), 2)
	b.put(&"table", Vector2i(19, 6)).put(&"chaise", Vector2i(18, 6), 1).put(&"chaise", Vector2i(18, 7), 1)
	b.put(&"chaise", Vector2i(21, 6), 3).put(&"chaise", Vector2i(21, 7), 3)
	# Chambre des parents.
	b.put(&"lit", Vector2i(6, 10), 2).put(&"table_nuit", Vector2i(8, 10), 2).put(&"lampe_chevet", Vector2i(5, 10), 2)
	b.put(&"armoire", Vector2i(10, 14), 0)
	# Salle de bain.
	b.put(&"toilettes", Vector2i(12, 10), 2).put(&"lavabo", Vector2i(13, 10), 2).put(&"baignoire", Vector2i(12, 13), 0)
	b.put(&"machine_laver", Vector2i(16, 10), 2).put(&"panier_linge", Vector2i(16, 14), 3)
	# Chambre des enfants.
	b.put(&"lit_simple", Vector2i(17, 10), 2).put(&"table_nuit", Vector2i(18, 10), 2).put(&"lit_simple", Vector2i(24, 10), 2)
	b.put(&"bureau", Vector2i(21, 14), 0).put(&"console_jeux", Vector2i(17, 14), 0)
	# Jardin.
	b.put(&"arbre", Vector2i(1, 1)).put(&"balancoire", Vector2i(2, 16)).put(&"arbre", Vector2i(26, 15)).put(&"plante", Vector2i(3, 4))
	return b.spawn([Vector2i(3, 7), Vector2i(3, 8)]).build()


## Maison moderne : grande pièce ouverte (cuisine et salon), bureau, chambre, entrée, salle de bain.
func villa_horizon() -> Lot:
	var b := HouseBuilder.new(&"ardoise", &"moderne")
	b.room(Rect2i(6, 3, 12, 7), &"carrelage")
	b.room(Rect2i(18, 3, 6, 4), &"parquet")
	b.room(Rect2i(18, 7, 6, 7), &"moquette")
	b.room(Rect2i(6, 10, 6, 4), &"faience")
	b.room(Rect2i(12, 10, 6, 4), &"lino")
	b.door(Vector3i(14, 14, H)).door(Vector3i(14, 10, H)).door(Vector3i(12, 11, V)).door(Vector3i(18, 5, V)).door(Vector3i(18, 11, V))
	b.window(Vector3i(8, 3, H), true).window(Vector3i(14, 3, H), true).window(Vector3i(20, 3, H)).window(Vector3i(24, 10, V))
	b.window(Vector3i(6, 6, V))
	# Cuisine.
	b.put(&"frigo", Vector2i(6, 3), 2).put(&"plan_travail", Vector2i(7, 3), 2).put(&"cuisiniere", Vector2i(10, 3), 2)
	b.put(&"machine_cafe", Vector2i(11, 3), 2).put(&"micro_ondes", Vector2i(12, 3), 2)
	b.put(&"table", Vector2i(8, 6)).put(&"chaise", Vector2i(7, 6), 1).put(&"chaise", Vector2i(10, 6), 3)
	# Salon.
	b.put(&"tele", Vector2i(14, 3), 2).put(&"canape", Vector2i(14, 7), 0).put(&"lampe_pied", Vector2i(17, 3), 2)
	b.put(&"chaine_hifi", Vector2i(13, 3), 2)
	# Bureau.
	b.put(&"ordinateur", Vector2i(20, 3), 2).put(&"plante", Vector2i(23, 3)).put(&"bibliotheque", Vector2i(23, 4), 3)
	# Chambre.
	b.put(&"lit", Vector2i(20, 7), 2).put(&"table_nuit", Vector2i(22, 7), 2).put(&"lampe_chevet", Vector2i(19, 7), 2)
	b.put(&"armoire", Vector2i(20, 13), 0)
	# Salle de bain.
	b.put(&"douche", Vector2i(6, 10), 1).put(&"toilettes", Vector2i(8, 10), 2).put(&"lavabo", Vector2i(9, 10), 2)
	b.put(&"machine_laver", Vector2i(11, 13), 3)
	# Entrée.
	b.put(&"plante", Vector2i(12, 13)).put(&"horloge", Vector2i(17, 13), 3)
	# Jardin.
	b.put(&"telescope", Vector2i(3, 15)).put(&"arbre", Vector2i(26, 15)).put(&"tapis_yoga", Vector2i(26, 4))
	return b.spawn([Vector2i(14, 16), Vector2i(15, 16)]).build()


## Petite maison et grand jardin : potagers, barbecue, salon de jardin, hamac.
func le_potager() -> Lot:
	var b := HouseBuilder.new(&"sauge", &"nature")
	b.room(Rect2i(3, 3, 8, 9), &"parquet")
	b.room(Rect2i(11, 3, 4, 5), &"moquette")
	b.room(Rect2i(11, 8, 4, 4), &"faience")
	b.door(Vector3i(6, 12, H)).door(Vector3i(11, 5, V)).door(Vector3i(11, 9, V))
	b.window(Vector3i(4, 3, H), true).window(Vector3i(15, 5, V)).window(Vector3i(12, 12, H)).window(Vector3i(3, 6, V))
	# Pièce à vivre.
	b.put(&"cuisiniere", Vector2i(6, 3), 2).put(&"plan_travail", Vector2i(7, 3), 2).put(&"frigo", Vector2i(10, 3), 2)
	b.put(&"table", Vector2i(4, 6)).put(&"chaise", Vector2i(6, 6), 3).put(&"chaise", Vector2i(6, 7), 3)
	b.put(&"cheminee", Vector2i(3, 9), 1).put(&"fauteuil", Vector2i(5, 9), 3).put(&"bibliotheque", Vector2i(10, 6), 3)
	# Chambre.
	b.put(&"lit", Vector2i(12, 3), 2).put(&"table_nuit", Vector2i(14, 3), 2)
	# Salle de bain.
	b.put(&"lavabo", Vector2i(12, 8), 2).put(&"toilettes", Vector2i(14, 8), 3).put(&"douche", Vector2i(13, 10), 3)
	# Jardin.
	b.put(&"potager", Vector2i(18, 3)).put(&"potager", Vector2i(21, 3)).put(&"potager", Vector2i(24, 3))
	b.put(&"barbecue", Vector2i(18, 9), 0).put(&"salon_jardin", Vector2i(21, 8)).put(&"hamac", Vector2i(18, 14), 0)
	b.put(&"arbre", Vector2i(26, 11)).put(&"arbre", Vector2i(1, 15)).put(&"poubelle", Vector2i(8, 13))
	return b.spawn([Vector2i(6, 15), Vector2i(7, 15)]).build()


## Maison d'artistes : atelier avec piano et chevalet, cuisine, chambre, grande salle de bain.
func l_atelier() -> Lot:
	var b := HouseBuilder.new(&"prune", &"retro")
	b.room(Rect2i(7, 4, 10, 6), &"parquet")
	b.room(Rect2i(17, 4, 6, 6), &"tomettes")
	b.room(Rect2i(7, 10, 8, 5), &"moquette")
	b.room(Rect2i(15, 10, 8, 5), &"faience")
	b.door(Vector3i(7, 7, V), false).door(Vector3i(17, 7, V)).door(Vector3i(10, 10, H)).door(Vector3i(19, 10, H))
	b.window(Vector3i(9, 4, H), true).window(Vector3i(13, 4, H), true).window(Vector3i(19, 4, H))
	b.window(Vector3i(9, 15, H), true).window(Vector3i(19, 15, H))
	# Atelier et salon.
	b.put(&"piano", Vector2i(7, 4), 2).put(&"chevalet", Vector2i(10, 4), 2).put(&"tele", Vector2i(12, 4), 2)
	b.put(&"canape", Vector2i(12, 7), 0).put(&"lampe_pied", Vector2i(16, 4), 2).put(&"plante", Vector2i(16, 9))
	# Cuisine.
	b.put(&"cuisiniere", Vector2i(18, 4), 2).put(&"plan_travail", Vector2i(19, 4), 2).put(&"frigo", Vector2i(22, 4), 2)
	b.put(&"table", Vector2i(19, 6)).put(&"chaise", Vector2i(18, 6), 1).put(&"chaise", Vector2i(21, 6), 3)
	b.put(&"poubelle", Vector2i(22, 9), 3)
	# Chambre.
	b.put(&"armoire", Vector2i(7, 10), 1).put(&"lit", Vector2i(12, 10), 2).put(&"table_nuit", Vector2i(14, 10), 2)
	b.put(&"coiffeuse", Vector2i(8, 14), 0)
	# Salle de bain.
	b.put(&"baignoire", Vector2i(15, 13), 0).put(&"lavabo", Vector2i(17, 10), 2).put(&"toilettes", Vector2i(22, 10), 3)
	b.put(&"machine_laver", Vector2i(22, 14), 3)
	# Jardin.
	b.put(&"arbre", Vector2i(2, 2)).put(&"plante", Vector2i(5, 5)).put(&"arbre", Vector2i(25, 15)).put(&"chevalet", Vector2i(26, 6), 3)
	return b.spawn([Vector2i(4, 8), Vector2i(4, 9)]).build()
