# Les Mouz

Petit jeu de simulation de vie en 2D vue de dessus, inspiré des Sims, fait avec **Godot 4.7** en GDScript.

Tu crées ta famille de Mouz (1 à 4 humains : prénoms, âge, apparence, liens), tu choisis un terrain vide ou une maison meublée, puis tu leur construis une maison (murs, portes, fenêtres, sols), tu achètes et places les meubles et tu les regardes vivre. Ils ont des besoins, utilisent des objets « intelligents », discutent entre eux et peuvent agir seuls.

Les graphismes suivent la direction artistique « Maison de poche » décrite dans [design/README.md](design/README.md) : aplats doux, contour encre, interface couleur papier.

## Lancer le projet

1. Installer Godot 4.7 (ou plus récent) :

   ```bash
   brew install --cask godot
   ```

2. Ouvrir le projet dans l'éditeur, puis appuyer sur **F5** :

   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --editor --path .
   ```

   Pour lancer directement le jeu, sans l'éditeur :

   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --path .
   ```

À la première ouverture, Godot crée le dossier `.godot/` (cache, ignoré par git). Si tu ajoutes un script avec un nouveau `class_name` en dehors de l'éditeur, ouvre l'éditeur une fois (ou lance `Godot --headless --path . --import`) pour qu'il soit reconnu.

## Les parties et les sauvegardes

Le jeu s'ouvre sur un **écran d'accueil** : la maison de la dernière partie en fond (ou un petit jardin où se promènent des Mouz s'il n'y en a pas), et les portraits de sa famille.

- **Continuer** reprend la dernière partie enregistrée ;
- **Nouvelle partie** ouvre la création, en deux étapes :
  1. **La famille** : nom de famille, 1 à 4 membres. Pour chacun : prénom (le dé en tire un), homme ou femme, âge (enfant, ado, adulte, aîné), peau, coupe et couleur des cheveux, tenue et sa couleur, ou « Apparence au hasard ». Entre deux cartes, une pastille fixe leur **lien** (couple, parent, enfant, frères et sœurs, colocs), qui donne leur relation de départ. Il faut au moins un adulte ou un aîné, et un prénom à chacun.
  2. **Le terrain** : la Prairie des Tilleuls (vide, gratuite), la Rue des Lilas ou le Clos Rétro (maisons meublées, payées sur le budget de départ). On y nomme la partie. Sur un terrain vide, la partie commence en mode Construire ;
- **Charger une partie** affiche toutes les parties : vignette du terrain, nom, jour, heure, argent, nombre d'objets et date. On peut y **renommer** ou **supprimer** une partie directement sur sa carte. Une partie dont le fichier ne se lit plus est marquée **Abîmée** : on peut **restaurer sa copie de secours** (la version précédente, gardée à chaque sauvegarde) ou la supprimer ;
- **Quitter**.

En jeu, **Échap** (ou un clic sur le logo « Les Mouz ») ouvre le **menu** et arrête le temps : Reprendre, Sauvegarder, Sauvegarder sous… (une copie avec un autre nom, qui devient la partie en cours), Charger une partie…, Menu principal, Quitter le jeu. **Ctrl+S** sauvegarde à tout moment. Un message en bas de l'écran confirme chaque sauvegarde ; en cas d'échec, il reste 6 secondes et propose « Réessayer ».

La partie en cours est aussi **sauvegardée automatiquement** : peu après chaque modification du terrain, au retour en mode Vivre, toutes les 2 minutes, avant d'en charger une autre et à la fermeture du jeu.

Une sauvegarde contient tout l'état de la partie : le terrain, l'argent, l'heure et la vitesse, la famille (prénoms, apparences, liens), la position, les besoins, les relations et l'autonomie de chaque Mouz, le Mouz sélectionné et la caméra. Les parties d'avant les humains (format 2) retrouvent Pépin et Myrtille, devenus humains.

### Où sont les fichiers

Chaque partie est un dossier de `user://saves/` (sur macOS : `~/Library/Application Support/Godot/app_userdata/Les Mouz/saves/`) :

| Fichier | Contenu |
|---|---|
| `data.json` | L'état de la partie, en JSON lisible, avec ses informations sous `"meta"` (nom, date, jour, argent) |
| `data.json.bak` | La version précédente, utilisée automatiquement si `data.json` est abîmé |
| `vignette.png` | L'image du terrain pour l'écran Charger |

L'écriture passe par un fichier temporaire : une coupure en pleine sauvegarde ne détruit jamais la dernière version valide. Les sauvegardes ne contiennent ni ressource ni script Godot, seulement des données : un fichier venu d'ailleurs ne peut pas exécuter de code.

L'ancienne sauvegarde unique (`user://partie.tres`) est convertie automatiquement en une partie « Ma maison » au premier lancement, puis renommée `partie.tres.ancien`.

### Faire évoluer le format

Le format est décrit dans `scripts/save/world_serializer.gd` (état de la partie) et `scripts/save/lot_serializer.gd` (terrain). Les éléments du catalogue y sont désignés par leur `id` : on peut déplacer ou renommer les fichiers `.tres` sans casser les sauvegardes, mais **il ne faut pas changer l'`id` d'un élément existant**. Un `id` inconnu (élément retiré du catalogue) est ignoré au chargement.

Le format est en version 2 : la version 1 n'avait pas de styles, et six objets y étaient dessinés face avant en bas. La migration leur donne le style Nature et les retourne d'un demi-tour, pour qu'ils gardent leur aspect.

Pour changer le format : augmenter `WorldSerializer.FORMAT_VERSION`, puis compléter `WorldSerializer.migrate()` pour mettre à jour les anciennes sauvegardes (par exemple, ajouter une valeur par défaut à une nouvelle clé). Une sauvegarde d'un format plus récent que le jeu est refusée plutôt que mal lue.

## Commandes

### Partout

| Touche | Effet |
|---|---|
| **F1** / **F2** / **F3** (ou les onglets en haut) | Modes Vivre / Construire / Acheter |
| Flèches, ZQSD, bouton du milieu | Faire défiler la vue |
| Molette | Zoomer |
| Échap | Menu du jeu (ou annule le tracé / lâche l'objet en cours) |
| Ctrl+S | Sauvegarder |

### Vivre

| Action | Effet |
|---|---|
| Clic sur le sol | Ajoute « Aller ici » à la file du Mouz sélectionné (remplace le déplacement déjà prévu) |
| Clic sur un objet | Menu des actions de l'objet ; l'action choisie s'ajoute à la file |
| Clic sur l'autre Mouz | Menu : « Discuter » ou « Contrôler » |
| Clic sur ✕ dans la file | Annule l'action |
| Boutons Pépin / Myrtille, ou **Tab** | Change de Mouz |
| Bouton « Autonomie » | Active ou coupe l'autonomie du Mouz sélectionné |
| Pause / x1 / x2 / x3, ou **Espace** et **1** à **3** | Vitesse du jeu |
| **V** | Hauteur des murs : coupés (par défaut), baissés, pleins |

Un ordre du joueur remplace toujours les actions choisies par l'autonomie.

### Construire (le temps est en pause)

| Outil | Geste |
|---|---|
| Mur | Glisser le long de la grille : un mur droit, payé par segment |
| Démolir | Glisser sur des murs : ils sont revendus, avec leurs portes et fenêtres |
| Porte, Fenêtre | Clic sur un mur. Le battant s'ouvre du côté du pointeur ; **R** inverse la charnière |
| Sol | Glisser pour peindre un rectangle ; l'ancien revêtement est revendu |
| Gomme | Glisser pour remettre de l'herbe (revêtement revendu) |
| Déplacer | Clic sur un objet pour le reprendre, puis le reposer |
| Annuler (ou Ctrl+Z) | Annule la dernière opération, argent compris |

Échap ou clic droit annule le geste en cours. L'étiquette près du pointeur affiche le coût, et ce qui manque si l'argent ne suffit pas.

### Acheter (le temps est en pause)

| Action | Effet |
|---|---|
| Clic sur une vignette du catalogue | L'objet suit la souris ; clic pour l'acheter et le poser |
| **R** | Tourne l'objet d'un quart de tour |
| Clic sur un objet posé | « Déplacer » ou « Revendre » |
| **Suppr** pendant un déplacement | Revend l'objet |
| Échap ou clic droit | Lâche l'objet |

Un objet est refusé, avec la raison affichée, s'il sort du terrain, chevauche un autre meuble, est traversé par un mur, recouvre un Mouz ou n'a aucune case libre pour être utilisé. Un tapis peut passer sous les meubles.

**Revente** : prix plein le jour de l'achat, 75 % ensuite. Ça vaut pour les objets, les murs, les portes, les fenêtres et les sols.

## Organisation

```
assets/
  sprites/             Objets : vue de dessus (`<id>_<collection>.svg`) et vue trois quarts
                       (`<id>_<collection>_<vue>.svg`)
  murs/                Murs en vue trois quarts : segments et poteaux, pleins et baissés
  ouvertures/          Portes (fermées, ouvertes) et fenêtres en vue trois quarts
  personnages/         Calques des humains (corps, tête, cheveux, ombre) en 3 vues et portraits de face
  terrains/            Vignettes des terrains proposés à l'emménagement
  floors/              Tuiles de sol 32 × 32 raccordables
  icons/ink/           Icônes 24 × 24 couleur encre
  icons/white/         Mêmes icônes en blanc, teintées par le thème (boutons)
  fonts/               Baloo 2 (titres) et Nunito (interface), polices variables
design/                Livrables de Claude Design (référence, ignoré par Godot)
data/                  Resources (.tres) : tout le contenu et l'équilibrage
  catalog/objects/     Objets achetables (prix, catégorie, taille, actions)
  catalog/floors/      Revêtements de sol (prix par case)
  catalog/walls/       Couleurs de mur (prix par segment)
  catalog/openings/    Portes et fenêtres (prix)
  actions/             Actions (Manger, Dormir, Discuter…)
  needs/               Besoins (Faim, Énergie…)
  characters/          Modèle de fiche (besoins, vitesse) ; Pépin et Myrtille pour les tests et
                       les anciennes parties
  lots/                Terrains : terrain_vide, maison_demo, maison_retro
  lots/offres/         Terrains proposés à l'emménagement (nom, terrain, prix, vignette)
  settings/            Horloge, autonomie, économie
scenes/                title.tscn (accueil, scène de démarrage), new_game.tscn (création de la famille et
                       choix du terrain), main.tscn (le jeu), personnage, objet, HUD
scripts/
  core/                Autoloads (GameClock, EventBus, Wallet, GameMode), monde, rendu, navigation,
                       caméra, catalogue, sauvegarde
  lot/                 Terrain : arêtes, murs, sols, ouvertures, objets posés, définitions du catalogue
  editor/              Modes Construire et Acheter : éditeur de terrain, contrôleurs, grille
  needs/               Définition d'un besoin et composant « besoins » d'un personnage
  objects/             Définitions d'action et d'objet, objet posé dans le monde
  characters/          Personnage, déplacement, file d'actions, autonomie, relations, famille,
                       apparence (calques à teinter) et corps dessiné en jeu
  save/                Autoload SaveManager, format JSON (terrain, partie), vignettes
  ui/                  Autoload Palette, thème, panneaux du HUD, portraits, écran d'accueil, menu en jeu
  ui/creation/         Écran de création : colonne de la famille, aperçu, éditeur, choix du terrain
```

Principes à retenir :

- **Le temps** passe uniquement par l'autoload `GameClock`. Les scripts écoutent `GameClock.ticked(minutes)` ou multiplient leur delta par `GameClock.time_scale`. La pause et les vitesses s'appliquent donc à tout le jeu.
- **L'argent** passe uniquement par l'autoload `Wallet` (`pay`, `receive`, `resale_value`). Chaque élément posé (`Purchase`) retient son prix et son jour d'achat.
- **Le terrain** (`Lot`) est une grille de cases. Les murs sont posés sur les **arêtes** entre deux cases : une arête est un `Vector3i(x, y, orientation)` (voir `scripts/lot/edges.gd`). Les portes et fenêtres occupent un ou plusieurs segments de mur.
- **Toute modification** du terrain passe par `LotEditor` (`scripts/editor/lot_editor.gd`), qui paie ou rembourse, garde l'historique pour « Annuler », puis émet `EventBus.lot_changed`. Le monde redessine alors le terrain, synchronise les objets et recalcule la navigation.
- **La navigation** utilise `AStar2D` : une case libre = un point, deux cases voisines sont reliées s'il n'y a pas de mur (ou si une porte) entre elles. Les meubles rendent leurs cases inaccessibles, sauf ceux marqués `blocks_movement = false` (le tapis).
- **Un personnage** (`scenes/characters/character.tscn`) assemble des composants : `Mover` (déplacement), `Needs` (besoins), `Queue` (file d'actions), `Brain` (autonomie) et `Relationships` (relations).
- **Une action** suit ce cycle dans la file : en attente → déplacement → en cours → terminée. Les gains de besoins sont répartis sur toute la durée de l'action.
- **Les couleurs** de l'interface viennent de l'autoload `Palette`, et le thème Godot est construit par `HudTheme`.

## Le catalogue : 50 objets en trois styles

Le catalogue compte **50 objets** répartis en 7 catégories : Cuisine, Chambre, Salon, Salle de bain, Loisirs, Jardin et Déco. Chaque objet existe dans trois **collections** de style :

| Collection | Clé | Idée |
|---|---|---|
| Nature | `nature` | Bois clair, sauge et lin, formes douces |
| Rétro | `retro` | Teck, moutarde, brique ; formes très arrondies, pieds compas |
| Moderne | `moderne` | Blanc, ardoise, métal ; lignes nettes |

Un style ne change que l'apparence : même taille, même face avant, mêmes interactions. Dans le catalogue, chaque objet a **une vignette par style** (sa pastille et son nom sous le prix) ; le **filtre** Toutes les montre toutes, Nature / Rétro / Moderne n'en garde qu'une par objet. Un clic sur un objet posé propose aussi de **changer de style** : gratuit le jour de l'achat, puis 25 % du prix (une revente à 75 % suivie d'un rachat au prix plein).

Quelques objets ont un **état « en marche »** : ils changent d'image quand on s'en sert (cuisinière, cheminée, douche, ordinateur…). Les lampes s'allument et s'éteignent, et restent dans cet état. La télé s'allume quand un Mouz la regarde depuis le canapé.

### Ce que les interactions savent faire

Une `ActionDefinition` (dans `data/actions/`) décrit une interaction :

| Champ | Effet |
|---|---|
| `display_name`, `icon`, `duration_minutes` | Nom, icône 24 × 24 et durée en minutes de jeu |
| `need_gains` | Points gagnés par besoin sur toute la durée (négatif pour une perte, par exemple l'énergie en dansant) |
| `shared_need_gains`, `shared_relationship_gain` | **Activité partagée** : gains en plus quand un autre Mouz utilise le même objet en même temps (échecs, apéro, repas à table, jeux vidéo…). L'autonomie aime rejoindre quelqu'un qui joue déjà |
| `nearby_object_id`, `nearby_radius` | **Objet voisin requis** : l'action n'est possible que si cet objet est à moins de `nearby_radius` cases (le canapé a besoin d'une télé), et elle le fait fonctionner pendant qu'elle dure |
| `switch` | **Interrupteur** : allume ou éteint l'objet à la fin de l'action (lampes) |
| `relationship_gain` | Pour les actions entre deux Mouz (Discuter) |

L'équilibrage des 57 interactions (durées et gains) est un premier jet, à ajuster dans les `.tres`.

## Ajouter un objet au catalogue

Exemple : une harpe avec l'action « Jouer de la harpe ». Tout se fait dans l'inspecteur de l'éditeur, sans code.

1. **Les images** : un SVG par collection dans `assets/sprites/`, nommé `harpe_nature.svg`, `harpe_retro.svg`, `harpe_moderne.svg`. Taille exacte de l'objet (32 px par case), face avant (le côté où le Mouz se place) **en haut**, dos en bas. Facultatif : `harpe_<collection>_actif.svg` pour l'état « en marche ».
   Pour la **vue trois quarts**, ajouter les vues `harpe_<collection>_<vue>.svg` avec `<vue>` = `bas`, `haut`, `gauche` et `droite` (côté vers lequel regarde la face avant). Largeur = emprise × 32 px, hauteur = profondeur × 32 + hauteur de l'objet ; le bas de l'image est le bas de l'emprise. Sans fichier `droite`, le jeu retourne la vue `gauche`. Ces fichiers sont trouvés par leur nom, il n'y a rien à déclarer dans la `.tres`. Tant qu'un objet n'a pas ses vues, il est dessiné à plat avec son image vue de dessus.
2. **L'action** : dans le dock *Système de fichiers*, clic droit sur `data/actions/`, puis *Créer nouveau… → Ressource…* et choisir `ActionDefinition`. Enregistrer sous `jouer_harpe.tres`, puis remplir `id`, `display_name`, `icon` (une icône de `assets/icons/ink/`), `duration_minutes` et `need_gains` (par exemple `plaisir` → `40`). Les clés sont les `id` des besoins.
3. **L'objet** : dans `data/catalog/objects/`, créer une Resource `SmartObjectDefinition` (`harpe.tres`) et renseigner :
   - `id` (unique, à ne plus changer ensuite : les sauvegardes s'en servent), `display_name`, `price` et `category` (`cuisine`, `chambre`, `salon`, `salle_de_bain`, `loisirs`, `jardin` ou `deco`) ;
   - `sprites` : une entrée par collection (`nature`, `retro`, `moderne`) vers les SVG ; `active_sprites` de même si l'objet a un état « en marche » ;
   - `size` (en cases), `capacity` (combien de Mouz à la fois), et `jouer_harpe.tres` dans `actions`.

C'est tout : le catalogue charge automatiquement tous les `.tres` de `data/catalog/`. L'objet apparaît dans sa catégorie, une vignette par style, s'achète, se pose, ouvre son menu au clic et compte pour l'autonomie. Un objet sans action est décoratif. Mets `blocks_movement` à faux pour un objet au sol qu'on peut traverser : on s'en sert alors en se tenant dessus (tapis de yoga).

**Ajouter une collection** : une `CollectionDefinition` dans `data/catalog/collections/` (`id`, `display_name`, `color` de la pastille, `icon`, `order`), puis les sprites `<objet>_<id>.svg` des objets concernés. Un objet sans sprite dans une collection ne la propose simplement pas.

**Ajouter un revêtement de sol** : une `FloorDefinition` dans `data/catalog/floors/` avec une tuile 32 × 32 raccordable (`texture`) et un `price_per_cell`.

**Ajouter une couleur de mur** : une `WallStyleDefinition` dans `data/catalog/walls/` (`color`, `price_per_segment`).

**Ajouter une porte ou une fenêtre** : une `OpeningDefinition` dans `data/catalog/openings/`. Renseigne `kind` (porte ou fenêtre ; seules les portes laissent passer), `width_segments`, `price`, et un `sprite` dessiné pour un mur horizontal avec la pièce en dessous : 32 × 40 pour une porte (8 px de seuil, puis le battant), largeur × 8 pour une fenêtre.

**Ajouter une action à un objet existant** : créer l'`ActionDefinition`, puis l'ajouter au tableau `actions` de l'objet.

**Ajouter une action sociale** (par exemple « Plaisanter ») : créer une `ActionDefinition` avec un `relationship_gain`, puis l'ajouter à `social_actions` sur le nœud `World` de `scenes/main.tscn`.

**Ajouter un besoin** : créer une `NeedDefinition` dans `data/needs/` avec un `id` unique, une `color`, une `background_color` et une `icon`, puis l'ajouter au tableau `needs` des fiches de `data/characters/`. Le HUD l'affichera tout seul.

**Ajouter un personnage** : dupliquer `data/characters/myrtille.tres` (nom, `sprite`, `color`), ajouter la copie à `character_profiles` sur le nœud `World`, et une case de départ dans `spawn_cells` de `data/lots/terrain_vide.tres`.

**Partir de la maison de démo** : sur le nœud `World` de `scenes/main.tscn`, mettre `starting_lot` sur `data/lots/maison_demo.tres`, puis lancer une nouvelle partie depuis l'écran d'accueil.

**Lancer directement le jeu sans l'accueil** : ouvrir `scenes/main.tscn` dans l'éditeur et appuyer sur F6. La partie n'a alors pas d'emplacement : « Sauvegarder » en crée un, nommé « Ma partie ».

## Où modifier l'équilibrage

| Quoi | Où |
|---|---|
| Budget de départ, part rendue à la revente (même jour / ensuite) | `data/settings/economy_settings.tres` |
| Prix des objets, sols, murs, portes et fenêtres | `data/catalog/**/*.tres` (`price`, `price_per_cell`, `price_per_segment`) |
| Taille du terrain, cases de départ | `data/lots/*.tres` (`size`, `spawn_cells`) |
| Terrains proposés et leur prix | `data/lots/offres/*.tres` (`lot`, `price`, `order`) |
| Relation de départ selon le lien de famille | `Family.LINK_START` (`scripts/characters/family.gd`) |
| Prénoms et noms tirés au dé | `scripts/ui/creation/name_ideas.gd` |
| Vitesse de baisse d'un besoin, poids dans l'humeur, seuil critique, valeur de départ | `data/needs/*.tres` (`decay_per_hour`, `mood_weight`, `critical_threshold`, `start_value`) |
| Durée et gains d'une action | `data/actions/*.tres` (`duration_minutes`, `need_gains`, `relationship_gain`) |
| Nombre d'utilisateurs simultanés d'un objet | `data/catalog/objects/*.tres` (`capacity`) |
| Bonus des activités partagées, distance d'un objet voisin | `data/actions/*.tres` (`shared_need_gains`, `shared_relationship_gain`, `nearby_radius`) |
| Coût d'un changement de style | `LotEditor.restyle_cost()` (prix − valeur de revente) |
| Rythme du temps, heure de départ, multiplicateurs de vitesse | `data/settings/clock_settings.tres` |
| Autonomie : fréquence de réflexion, poids de la distance, priorité des besoins bas, score minimal | `data/settings/autonomy_settings.tres` |
| Vitesse de marche, autonomie par défaut | `data/characters/*.tres` (`walk_speed`, `autonomy_enabled`) |
| Défilement et zoom de la caméra | nœud `World/Camera` de `scenes/main.tscn` (variables exportées) |

L'autonomie calcule, pour chaque action possible :

```
score = Σ min(gain, 100 − valeur du besoin) × urgence^urgency_exponent − distance × distance_penalty_per_cell
urgence = 1 − valeur / 100
```

Le Mouz choisit l'action qui a le meilleur score, si ce score dépasse `min_score`. Il ne va pas déranger un Mouz occupé ; un ordre du joueur, lui, interrompt l'autre Mouz.

## Brancher ses propres mécaniques : l'EventBus

L'autoload `EventBus` (`scripts/core/event_bus.gd`) émet les événements du jeu. On peut s'y connecter de n'importe où, sans modifier le cœur du jeu :

| Signal | Quand |
|---|---|
| `action_queued(character, action)` | Une action est ajoutée à une file |
| `action_started(character, action)` | Le Mouz commence l'action sur place |
| `action_finished(character, action)` | L'action est allée jusqu'au bout |
| `action_cancelled(character, action)` | L'action a été annulée ou était impossible |
| `need_changed(character, need_id, value)` | Un besoin a changé |
| `need_critical(character, need_id, value)` | Un besoin passe sous son seuil critique |
| `mood_changed(character, mood)` | L'humeur a changé |
| `relationship_changed(a, b, value, delta)` | Une relation a changé |
| `money_changed(funds, delta)` | Le solde a changé |
| `item_bought(item, price)` | Un mur, sol, porte, fenêtre ou objet a été acheté |
| `item_sold(item, refund)` | Un élément a été revendu ou démoli |
| `lot_changed` | Le terrain a été modifié |
| `object_displaced(placed)` | Un objet va être déplacé ou revendu |
| `character_selected(character)` | Le joueur change de Mouz |

`action` est un `QueuedAction`. On y trouve `definition` (l'`ActionDefinition`), `target_object`, `target_character`, `is_autonomous` et `get_label()`. `item` est un `PlacedWall`, `PlacedFloor`, `PlacedOpening` ou `PlacedObject`.

Exemple : un journal des dépenses, à ajouter comme nœud dans `main.tscn` :

```gdscript
extends Node

func _ready() -> void:
	EventBus.item_bought.connect(_on_item_bought)

func _on_item_bought(item: Resource, price: int) -> void:
	print("%s : achat de %s pour %s" % [GameClock.format_time(), item.get_class(), Palette.format_mz(price)])
```

Le gestionnaire de sauvegardes a aussi ses signaux : `SaveManager.saved(slot_id)` après chaque enregistrement, et `SaveManager.slots_changed` quand la liste des parties change.

## La vue trois quarts

Le jeu passe progressivement en vue trois quarts (brief n° 6, livré par lots ; règles complètes dans `design/README.md`). La grille reste carrée, les objets montent vers le haut de l'écran.

- **Ordre d'affichage** : `World`, `Objects`, `Characters` et `WallView` ont `y_sort_enabled`. Chaque nœud est posé à son point de tri : le bas de l'emprise pour un objet, les pieds pour un personnage, le pied du mur pour un morceau de mur. Ce qui est plus bas à l'écran passe devant.
- **Murs** (`WallView`) : un Sprite2D par segment, par poteau (forme choisie selon les murs qui partent du nœud) et par ouverture. En murs coupés, un mur horizontal qui cache une pièce est baissé ; les murs verticaux restent pleins. En Construire et Acheter, tout est baissé. Les portes s'ouvrent quand un Mouz est sur l'une des cases qu'elles séparent.
- **Clics** : `World.get_object_at_point` cherche l'image de l'objet (hauteur comprise), celle de devant en premier.
- **Lot 1 livré** : murs, portes, fenêtres, 7 objets témoins en Nature (canapé, télé, lit, frigo, table, chaise, plante). Les autres objets restent vus de dessus en attendant leur lot.
- **Lot 2 livré** : les humains. `MouzAppearance` liste les calques à superposer (ombre, cheveux arrière, pantalon, peau, tenue, contours, tête, cheveux), blancs dans les SVG et teintés par `modulate`. `MouzBody` les dessine en jeu (32 × 64, pieds à 48 px du haut ; `droite` = `gauche` retourné ; tête et cheveux remontent d'1 px en marchant), `MouzPortrait` dessine le portrait de face dans l'interface. Les calques sont importés à l'échelle 2 (portraits à l'échelle 4) pour rester nets.
- **Lot 3 livré** : la cuisine complète dans les trois collections (frigo, cuisinière, évier, plan de travail, table, chaise, micro-ondes, machine à café, lave-vaisselle, poubelle). Cuisinière, micro-ondes, machine à café et lave-vaisselle ont des vues « en marche » (`_actif`). L'évier et le plan de travail, asymétriques, ont leur propre vue `droite`. Micro-ondes et machine à café sont dessinés posés sur un petit meuble bas.
- **Lots 4 et 5 livrés** : chambre, salle de bain, salon et déco dans les trois collections. Vues « en marche » : lampes, douche, machine à laver, télé, cheminée, chaîne hi-fi. Le tapis n'a que deux vues (`bas` et `gauche`) : de dos, le jeu reprend la vue `bas`, et de droite la vue `gauche` retournée. Il reste dessiné sous tout le reste. Seuls les loisirs et le jardin (lot 6) restent vus de dessus.

## Limites connues

- Les Mouz peuvent se traverser : ils ne bloquent pas la navigation.
- Deux Mouz peuvent viser le même objet. Le premier arrivé le réserve, et l'action du second est annulée ; son autonomie choisit alors autre chose.
- La file d'actions des Mouz n'est pas sauvegardée : au chargement, ils repartent les mains vides (l'autonomie reprend vite la main).
- Il n'y a pas encore de revenus ni de dépenses régulières : l'argent ne bouge qu'en construisant et en achetant.

## Crédits

Polices [Baloo 2](https://fonts.google.com/specimen/Baloo+2) et [Nunito](https://fonts.google.com/specimen/Nunito), sous licence SIL Open Font License 1.1 (textes de licence dans `assets/fonts/`).
