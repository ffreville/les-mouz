# Les Mouz

Petit jeu de simulation de vie en 2D vue de dessus, inspiré des Sims, fait avec **Godot 4.7** en GDScript.
Deux Mouz (Pépin et Myrtille) vivent dans une maison de quatre pièces. Ils ont des besoins, utilisent des objets « intelligents », discutent entre eux et peuvent agir seuls.

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

À la première ouverture, Godot crée le dossier `.godot/` (cache, ignoré par git). Si vous ajoutez un script avec un nouveau `class_name` en dehors de l'éditeur, ouvrez l'éditeur une fois (ou lancez `Godot --headless --path . --import`) pour qu'il soit reconnu.

## Commandes

| Action | Effet |
|---|---|
| Clic sur le sol | Ajoute « Aller ici » à la file du personnage sélectionné |
| Clic sur un objet | Menu des actions de l'objet ; l'action choisie s'ajoute à la file |
| Clic sur l'autre personnage | Menu : « Discuter » ou « Contrôler » |
| Clic sur ✕ dans la file | Annule l'action |
| Boutons Pépin / Myrtille en haut, ou **Tab** | Change de personnage |
| Bouton « Autonomie » | Active ou coupe l'autonomie du personnage sélectionné |
| Pause / x1 / x2 / x3, ou **Espace** et **1** à **3** | Vitesse du jeu |

Un ordre du joueur remplace toujours les actions choisies par l'autonomie.

## Organisation

```
assets/
  sprites/             Objets et Mouz vus de dessus (SVG, 32 px par case)
  icons/ink/           Icônes 24 × 24 couleur encre (besoins, actions)
  icons/white/         Mêmes icônes en blanc, teintées par le thème (boutons)
  fonts/               Baloo 2 (titres) et Nunito (interface), polices variables
design/                Livrable de Claude Design (référence, ignoré par Godot)
data/                  Resources (.tres) : tout le contenu et l'équilibrage
  actions/             Actions (Manger, Dormir, Discuter…)
  objects/             Objets intelligents (Frigo, Lit…)
  needs/               Besoins (Faim, Énergie…)
  characters/          Fiches des Mouz (Pépin, Myrtille)
  house/               Plan de la maison (pièces, murs, portes, meubles)
  settings/            Réglages de l'horloge et de l'autonomie
scenes/                main.tscn, personnage, objet, HUD
scripts/
  core/                Autoloads GameClock et EventBus, monde, sols, murs, navigation, clics
  needs/               Définition d'un besoin et composant « besoins » d'un personnage
  objects/             Définitions d'action et d'objet, objet posé dans la maison
  characters/          Personnage, déplacement, file d'actions, autonomie, relations
  ui/                  Autoload Palette, thème du HUD, horloge, barres, file d'actions, menu, relations
```

Principes à retenir :

- **Le temps** passe uniquement par l'autoload `GameClock`. Les scripts écoutent `GameClock.ticked(minutes)` ou multiplient leur delta par `GameClock.time_scale`. La pause et les vitesses s'appliquent donc à tout le jeu.
- **Un personnage** (`scenes/characters/character.tscn`) assemble des composants : `Mover` (déplacement sur la grille), `Needs` (besoins), `Queue` (file d'actions), `Brain` (autonomie) et `Relationships` (relations).
- **La maison** est une grille de 20 × 16 cases. Les murs ne sont pas décrits : il y en a un entre deux cases de pièces différentes, sauf si l'une des deux est une porte (`doors` dans le plan).
- **La navigation** utilise `AStar2D` : une case libre = un point, deux cases voisines sont reliées s'il n'y a pas de mur entre elles. Les meubles rendent leurs cases inaccessibles, sauf les objets marqués `blocks_movement = false` (le tapis).
- **Les couleurs** de l'interface viennent de l'autoload `Palette` (`scripts/ui/palette.gd`), et le thème Godot est construit par `HudTheme`. Les couleurs propres à un besoin, un objet ou un Mouz sont dans leurs Resources.
- **Une action** suit ce cycle dans la file : en attente → déplacement → en cours → terminée. Les gains de besoins sont répartis sur toute la durée de l'action.

## Ajouter un nouvel objet

Exemple : une baignoire avec l'action « Prendre un bain ». Tout se fait dans l'inspecteur de l'éditeur, sans code.

1. **L'action** : dans le dock *Système de fichiers*, clic droit sur `data/actions/`, puis *Créer nouveau… → Ressource…* et choisir `ActionDefinition`. Enregistrer sous `prendre_bain.tres`, puis remplir :
   - `display_name` : « Prendre un bain » ;
   - `icon` : une icône 24 × 24 de `assets/icons/ink/` ;
   - `duration_minutes` : `45` ;
   - `need_gains` : ajouter `hygiene` → `90` et `plaisir` → `15`. Les clés sont les `id` des besoins, en StringName.
2. **L'objet** : dans `data/objects/`, créer une Resource `SmartObjectDefinition` (`baignoire.tres`). Renseigner `display_name`, `sprite` (un SVG de `assets/sprites/` à la taille de l'objet, 32 px par case ; sans image, un rectangle de `color` est dessiné), `size` (en cases), `capacity`, et ajouter `prendre_bain.tres` dans `actions`. Un objet sans action est décoratif : il bloque le passage mais n'ouvre pas de menu.
3. **Le placer** : ouvrir `data/house/house_layout.tres` et, dans `objects`, ajouter un élément `ObjectPlacement`. Lui donner la `definition` `baignoire.tres` et une `cell` (coin haut-gauche, en cases).
   La grille fait 20 × 16 cases. Les pièces sont décrites dans `rooms`, et il faut laisser au moins une case libre à côté de l'objet, du même côté du mur.

L'objet est alors dessiné, bloque le passage, ouvre son menu au clic et sera pris en compte par l'autonomie.

**Ajouter une action à un objet existant** : créer l'`ActionDefinition` comme à l'étape 1, puis l'ajouter au tableau `actions` de l'objet.

**Ajouter une action sociale** (par exemple « Plaisanter ») : créer une `ActionDefinition` avec un `relationship_gain`, puis l'ajouter à `social_actions` sur le nœud `World` de `scenes/main.tscn`.

**Ajouter un besoin** : créer une `NeedDefinition` dans `data/needs/` avec un `id` unique, une `color`, une `background_color` et une `icon`, puis l'ajouter au tableau `needs` des fiches de `data/characters/`. Le HUD l'affichera tout seul.

**Ajouter un personnage** : dupliquer `data/characters/myrtille.tres` (nom, `sprite`, `color`), ajouter la copie à `character_profiles` sur le nœud `World`, et ajouter une case de départ dans `character_spawns` du plan de la maison.

**Modifier la maison** : dans `data/house/house_layout.tres`, changer les rectangles des `rooms` (avec leur sol : `floor_color`, `pattern`, `pattern_color`) et les cases de `doors`. Les murs suivent automatiquement.

## Où modifier l'équilibrage

| Quoi | Où |
|---|---|
| Vitesse de baisse d'un besoin, poids dans l'humeur, seuil critique, valeur de départ | `data/needs/*.tres` (`decay_per_hour`, `mood_weight`, `critical_threshold`, `start_value`) |
| Durée et gains d'une action | `data/actions/*.tres` (`duration_minutes`, `need_gains`, `relationship_gain`) |
| Nombre d'utilisateurs simultanés d'un objet | `data/objects/*.tres` (`capacity`) |
| Rythme du temps, heure de départ, multiplicateurs de vitesse | `data/settings/clock_settings.tres` |
| Autonomie : fréquence de réflexion, poids de la distance, priorité des besoins bas, score minimal | `data/settings/autonomy_settings.tres` |
| Vitesse de marche, autonomie par défaut | `data/characters/*.tres` (`walk_speed`, `autonomy_enabled`) |

L'autonomie calcule, pour chaque action possible :

```
score = Σ min(gain, 100 − valeur du besoin) × urgence^urgency_exponent − distance × distance_penalty_per_cell
urgence = 1 − valeur / 100
```

Le personnage choisit l'action qui a le meilleur score, si ce score dépasse `min_score`. Il ne va pas déranger un personnage occupé ; un ordre du joueur, lui, interrompt l'autre personnage.

## Brancher ses propres mécaniques : l'EventBus

L'autoload `EventBus` (`scripts/core/event_bus.gd`) émet les événements du jeu. On peut s'y connecter de n'importe où, sans modifier le cœur du jeu :

| Signal | Quand |
|---|---|
| `action_queued(character, action)` | Une action est ajoutée à une file |
| `action_started(character, action)` | Le personnage commence l'action sur place |
| `action_finished(character, action)` | L'action est allée jusqu'au bout |
| `action_cancelled(character, action)` | L'action a été annulée ou était impossible |
| `need_changed(character, need_id, value)` | Un besoin a changé |
| `need_critical(character, need_id, value)` | Un besoin passe sous son seuil critique |
| `mood_changed(character, mood)` | L'humeur a changé |
| `relationship_changed(a, b, value, delta)` | Une relation a changé |
| `character_selected(character)` | Le joueur change de personnage |

`action` est un `QueuedAction`. On y trouve `definition` (l'`ActionDefinition`), `target_object`, `target_character`, `is_autonomous` et `get_label()`.

Exemple : un système de souvenirs, à ajouter comme nœud dans `main.tscn` :

```gdscript
extends Node

func _ready() -> void:
	EventBus.action_finished.connect(_on_action_finished)

func _on_action_finished(character: Node, action: RefCounted) -> void:
	if action.is_social():
		print("%s se souvient d'avoir discuté avec %s (%s)" % [
			character.get_display_name(),
			action.target_character.get_display_name(),
			GameClock.format_time(),
		])
```

## Limites connues de cette première version

- Le menu contextuel n'a pas encore la pointe tournée vers l'objet prévue par le design.
- Les personnages peuvent se traverser : ils ne bloquent pas la navigation.
- Deux personnages peuvent viser le même objet. Le premier arrivé le réserve, et l'action du second est annulée ; son autonomie choisit alors autre chose.
- Pas de sauvegarde ni de chargement.

## Crédits

Polices [Baloo 2](https://fonts.google.com/specimen/Baloo+2) et [Nunito](https://fonts.google.com/specimen/Nunito), sous licence SIL Open Font License 1.1 (textes de licence dans `assets/fonts/`).
