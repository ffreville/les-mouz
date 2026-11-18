# Les Mouz

Petit jeu de simulation de vie en 2D vue de dessus, inspiré des Sims, fait avec **Godot 4.7** en GDScript.

Deux Mouz, Pépin et Myrtille, arrivent sur un terrain vide avec 20 000 Mz. Tu leur construis une maison (murs, portes, fenêtres, sols), tu achètes et places les meubles, puis tu les regardes vivre. Ils ont des besoins, utilisent des objets « intelligents », discutent entre eux et peuvent agir seuls.

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

## La partie

- Une **nouvelle partie** démarre sur un terrain vide de 30 × 20 cases, en mode Construire, avec le budget de départ.
- La partie est **sauvegardée automatiquement** dans `user://partie.tres` : peu après chaque modification du terrain, au retour en mode Vivre, toutes les 2 minutes et à la fermeture du jeu. Elle contient le terrain, l'argent et l'heure. Les besoins et les relations repartent de zéro au chargement.
- **Recommencer** : clic sur le logo « Les Mouz », puis « Nouvelle partie… » (ou Ctrl+N).

Sur macOS, `user://` correspond à `~/Library/Application Support/Godot/app_userdata/Les Mouz/`.

## Commandes

### Partout

| Touche | Effet |
|---|---|
| **F1** / **F2** / **F3** (ou les onglets en haut) | Modes Vivre / Construire / Acheter |
| Flèches, ZQSD, bouton du milieu | Faire défiler la vue |
| Molette | Zoomer |
| Ctrl+N | Nouvelle partie |

### Vivre

| Action | Effet |
|---|---|
| Clic sur le sol | Ajoute « Aller ici » à la file du Mouz sélectionné |
| Clic sur un objet | Menu des actions de l'objet ; l'action choisie s'ajoute à la file |
| Clic sur l'autre Mouz | Menu : « Discuter » ou « Contrôler » |
| Clic sur ✕ dans la file | Annule l'action |
| Boutons Pépin / Myrtille, ou **Tab** | Change de Mouz |
| Bouton « Autonomie » | Active ou coupe l'autonomie du Mouz sélectionné |
| Pause / x1 / x2 / x3, ou **Espace** et **1** à **3** | Vitesse du jeu |

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
  sprites/             Objets, portes, fenêtres et Mouz vus de dessus (SVG, 32 px par case)
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
  characters/          Fiches des Mouz (Pépin, Myrtille)
  lots/                Terrains : terrain_vide (nouvelle partie), maison_demo (exemple)
  settings/            Horloge, autonomie, économie
scenes/                main.tscn, personnage, objet, HUD
scripts/
  core/                Autoloads (GameClock, EventBus, Wallet, GameMode), monde, rendu, navigation,
                       caméra, catalogue, sauvegarde
  lot/                 Terrain : arêtes, murs, sols, ouvertures, objets posés, définitions du catalogue
  editor/              Modes Construire et Acheter : éditeur de terrain, contrôleurs, grille
  needs/               Définition d'un besoin et composant « besoins » d'un personnage
  objects/             Définitions d'action et d'objet, objet posé dans le monde
  characters/          Personnage, déplacement, file d'actions, autonomie, relations
  ui/                  Autoload Palette, thème, et tous les panneaux du HUD
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

## Ajouter un objet au catalogue

Exemple : un piano avec l'action « Jouer du piano ». Tout se fait dans l'inspecteur de l'éditeur, sans code.

1. **L'action** : dans le dock *Système de fichiers*, clic droit sur `data/actions/`, puis *Créer nouveau… → Ressource…* et choisir `ActionDefinition`. Enregistrer sous `jouer_piano.tres`, puis remplir :
   - `display_name` : « Jouer du piano » ;
   - `icon` : une icône 24 × 24 de `assets/icons/ink/` ;
   - `duration_minutes` : `45` ;
   - `need_gains` : ajouter `plaisir` → `40`. Les clés sont les `id` des besoins.
2. **L'objet** : dans `data/catalog/objects/`, créer une Resource `SmartObjectDefinition` (`piano.tres`) et renseigner :
   - `id` (unique), `display_name`, `price` et `category` (`cuisine`, `chambre`, `salon`, `salle_de_bain` ou `deco`) ;
   - `sprite` : un SVG de `assets/sprites/` à la taille de l'objet (32 px par case), dessiné tourné vers le haut. Sans image, un rectangle de `color` est dessiné ;
   - `size` (en cases), `capacity`, et `jouer_piano.tres` dans `actions`.

C'est tout : le catalogue charge automatiquement tous les `.tres` de `data/catalog/`. L'objet apparaît dans sa catégorie, s'achète, se pose, ouvre son menu au clic et compte pour l'autonomie. Un objet sans action est décoratif : il bloque le passage mais n'ouvre pas de menu. Mets `blocks_movement` à faux pour un objet au sol qu'on peut traverser.

**Ajouter un revêtement de sol** : une `FloorDefinition` dans `data/catalog/floors/` avec une tuile 32 × 32 raccordable (`texture`) et un `price_per_cell`.

**Ajouter une couleur de mur** : une `WallStyleDefinition` dans `data/catalog/walls/` (`color`, `price_per_segment`).

**Ajouter une porte ou une fenêtre** : une `OpeningDefinition` dans `data/catalog/openings/`. Renseigne `kind` (porte ou fenêtre ; seules les portes laissent passer), `width_segments`, `price`, et un `sprite` dessiné pour un mur horizontal avec la pièce en dessous : 32 × 40 pour une porte (8 px de seuil, puis le battant), largeur × 8 pour une fenêtre.

**Ajouter une action à un objet existant** : créer l'`ActionDefinition`, puis l'ajouter au tableau `actions` de l'objet.

**Ajouter une action sociale** (par exemple « Plaisanter ») : créer une `ActionDefinition` avec un `relationship_gain`, puis l'ajouter à `social_actions` sur le nœud `World` de `scenes/main.tscn`.

**Ajouter un besoin** : créer une `NeedDefinition` dans `data/needs/` avec un `id` unique, une `color`, une `background_color` et une `icon`, puis l'ajouter au tableau `needs` des fiches de `data/characters/`. Le HUD l'affichera tout seul.

**Ajouter un personnage** : dupliquer `data/characters/myrtille.tres` (nom, `sprite`, `color`), ajouter la copie à `character_profiles` sur le nœud `World`, et une case de départ dans `spawn_cells` de `data/lots/terrain_vide.tres`.

**Partir de la maison de démo** : sur le nœud `World` de `scenes/main.tscn`, mettre `starting_lot` sur `data/lots/maison_demo.tres`, puis lancer une nouvelle partie.

## Où modifier l'équilibrage

| Quoi | Où |
|---|---|
| Budget de départ, part rendue à la revente (même jour / ensuite) | `data/settings/economy_settings.tres` |
| Prix des objets, sols, murs, portes et fenêtres | `data/catalog/**/*.tres` (`price`, `price_per_cell`, `price_per_segment`) |
| Taille du terrain, cases de départ | `data/lots/terrain_vide.tres` (`size`, `spawn_cells`) |
| Vitesse de baisse d'un besoin, poids dans l'humeur, seuil critique, valeur de départ | `data/needs/*.tres` (`decay_per_hour`, `mood_weight`, `critical_threshold`, `start_value`) |
| Durée et gains d'une action | `data/actions/*.tres` (`duration_minutes`, `need_gains`, `relationship_gain`) |
| Nombre d'utilisateurs simultanés d'un objet | `data/catalog/objects/*.tres` (`capacity`) |
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

## Limites connues

- Les Mouz peuvent se traverser : ils ne bloquent pas la navigation.
- Deux Mouz peuvent viser le même objet. Le premier arrivé le réserve, et l'action du second est annulée ; son autonomie choisit alors autre chose.
- La sauvegarde garde le terrain, l'argent et l'heure, mais pas les besoins, les relations ni la position des Mouz.
- Il n'y a pas encore de revenus ni de dépenses régulières : l'argent ne bouge qu'en construisant et en achetant.

## Crédits

Polices [Baloo 2](https://fonts.google.com/specimen/Baloo+2) et [Nunito](https://fonts.google.com/specimen/Nunito), sous licence SIL Open Font License 1.1 (textes de licence dans `assets/fonts/`).
