class_name PlotDefinition
extends Resource
## Un emplacement du quartier : son adresse et la maison livrée dessus (aucune : terrain libre).

## Identifiant unique dans le quartier (sert à la sauvegarde). Ne pas le changer une fois publié.
@export var id: StringName = &"emplacement"
## Adresse affichée (« 3 rue des Lilas »).
@export var address: String = "Emplacement"
## Nom de la maison (« Les Glycines »), vide pour un terrain libre.
@export var house_name: String = ""
## Maison déjà construite et meublée, ou null pour un terrain libre (`NeighborhoodDefinition.empty_lot`).
@export var lot: Lot
