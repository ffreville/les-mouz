class_name NeighborhoodDefinition
extends Resource
## Le quartier livré avec le jeu : ses emplacements, dans l'ordre de la carte
## (deux rangées de part et d'autre de la rue : la première moitié en haut, l'autre en bas).

@export var display_name: String = "Quartier"
@export var plots: Array[PlotDefinition] = []
## Terrain des emplacements libres (herbe seule).
@export var empty_lot: Lot
## Nombre de familles tirées au hasard et installées dans des maisons à la création.
@export var starting_families: int = 3
