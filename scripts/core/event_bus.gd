extends Node
## Autoload « EventBus » : signaux globaux du jeu.
##
## Le cœur du jeu émet ces signaux sans savoir qui les écoute. Pour brancher
## une nouvelle mécanique (souvenirs, rumeurs…), il suffit de s'y connecter,
## par exemple : `EventBus.action_finished.connect(_on_action_finished)`.
##
## Les paramètres `character` sont des `Character`, `action` des `QueuedAction`.

# --- Actions -----------------------------------------------------------------

## Une action vient d'être ajoutée à la file d'un personnage.
@warning_ignore("unused_signal")
signal action_queued(character: Node, action: RefCounted)
## Le personnage commence réellement l'action (il est arrivé sur place).
@warning_ignore("unused_signal")
signal action_started(character: Node, action: RefCounted)
## L'action est allée jusqu'au bout.
@warning_ignore("unused_signal")
signal action_finished(character: Node, action: RefCounted)
## L'action a été annulée (par le joueur, ou parce qu'elle était impossible).
@warning_ignore("unused_signal")
signal action_cancelled(character: Node, action: RefCounted)

# --- Besoins -----------------------------------------------------------------

## La valeur d'un besoin a changé.
@warning_ignore("unused_signal")
signal need_changed(character: Node, need_id: StringName, value: float)
## Un besoin vient de passer sous son seuil critique.
@warning_ignore("unused_signal")
signal need_critical(character: Node, need_id: StringName, value: float)
## L'humeur générale d'un personnage a changé.
@warning_ignore("unused_signal")
signal mood_changed(character: Node, mood: float)

# --- Relations ---------------------------------------------------------------

## La relation entre deux personnages a changé (valeur entre -100 et 100).
@warning_ignore("unused_signal")
signal relationship_changed(a: Node, b: Node, value: float, delta: float)

# --- Terrain et argent -------------------------------------------------------

## Le terrain a été modifié (murs, sols, ouvertures ou objets).
@warning_ignore("unused_signal")
signal lot_changed
## Le solde a changé de `delta` (négatif pour une dépense).
@warning_ignore("unused_signal")
signal money_changed(funds: int, delta: int)
## Un élément du catalogue a été acheté (`item` : PlacedWall, PlacedFloor, PlacedOpening ou PlacedObject).
@warning_ignore("unused_signal")
signal item_bought(item: Resource, price: int)
## Un élément a été revendu ou démoli, pour `refund` Mz.
@warning_ignore("unused_signal")
signal item_sold(item: Resource, refund: int)

# --- Éditeur ------------------------------------------------------------------

## Un objet posé va être revendu ou déplacé : les actions qui le visent doivent s'arrêter.
@warning_ignore("unused_signal")
signal object_displaced(placed: Resource)
## Le joueur a choisi un objet dans le catalogue (mode Acheter), dans une collection.
@warning_ignore("unused_signal")
signal catalog_item_selected(definition: Resource, collection: StringName)
## Le placement en cours est terminé ou annulé (le catalogue désélectionne sa vignette).
@warning_ignore("unused_signal")
signal placement_ended
## L'interface a choisi un outil de construction (`option` : couleur de mur, sol, porte…).
@warning_ignore("unused_signal")
signal build_tool_selected(tool: StringName, option: Resource)
## Aperçu du coût près du pointeur (`cost` négatif = remboursement ; texte vide = masquer).
@warning_ignore("unused_signal")
signal cost_preview_changed(text: String, cost: int)

# --- Sélection et interface --------------------------------------------------

## Le joueur a sélectionné un autre personnage.
@warning_ignore("unused_signal")
signal character_selected(character: Node)
## Demande d'ouverture d'un menu contextuel.
## `options` : tableau de dictionnaires { "label": String, "callback": Callable }.
@warning_ignore("unused_signal")
signal context_menu_requested(title: String, options: Array, screen_position: Vector2)
## Petit message en bas de l'écran (« Pépin rentre du travail : +210 Mz »).
@warning_ignore("unused_signal")
signal notice(text: String)


# --- Travail ------------------------------------------------------------------

## Ouvrir les petites annonces pour ce Mouz ; `source` : &"telephone" ou &"ordinateur".
@warning_ignore("unused_signal")
signal job_board_requested(character: Node, source: StringName)
## Un Mouz rentre du travail et touche son salaire.
@warning_ignore("unused_signal")
signal salary_paid(character: Node, amount: int)
## Un Mouz gagne un niveau dans une compétence.
@warning_ignore("unused_signal")
signal skill_level_up(character: Node, skill: StringName, level: int)
## Un Mouz change de grade dans son métier (`up` : promotion, sinon rétrogradation).
@warning_ignore("unused_signal")
signal grade_changed(character: Node, grade: int, up: bool)


# --- Factures -----------------------------------------------------------------

## Une facture arrive.
@warning_ignore("unused_signal")
signal bill_received(amount: int)
## L'électricité est coupée (`cut`) ou rétablie.
@warning_ignore("unused_signal")
signal power_cut_changed(cut: bool)
