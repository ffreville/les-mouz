# Les Mouz

Petit jeu de simulation de vie en 2D vue de dessus, inspiré des Sims, fait avec **Godot 4.7** en GDScript.

Tu arrives dans un quartier où vivent déjà quelques familles. Tu en joues une, ou tu crées la tienne (1 à 4 humains : prénoms, âge, apparence, liens) et tu l'installes dans une maison à vendre ou sur un terrain libre, puis tu leur construis une maison (murs, portes, fenêtres, sols), tu achètes et places les meubles et tu les regardes vivre. Ils ont des besoins, utilisent des objets « intelligents », discutent entre eux et peuvent agir seuls.

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

Le jeu s'ouvre sur un **écran d'accueil** : la maison de la dernière partie en fond (ou un petit jardin où se promènent des Mouz s'il n'y en a pas), et les portraits de la dernière famille jouée.

- **Continuer** reprend la dernière partie enregistrée : la famille qu'on jouait, ou l'écran du quartier si on l'avait quittée depuis le quartier ;
- **Nouveau quartier** crée une partie : le quartier des Tilleuls, ses maisons, et trois familles tirées au hasard déjà installées (voir « Le quartier ») ;
- **Charger une partie** affiche toutes les parties : vignette, nom, jour, heure, famille jouée et son argent (ou le nombre de familles du quartier) et date. On peut y **renommer** ou **supprimer** une partie directement sur sa carte. Une partie dont le fichier ne se lit plus est marquée **Abîmée** : on peut **restaurer sa copie de secours** (la version précédente, gardée à chaque sauvegarde) ou la supprimer ;
- **Quitter**.

En jeu, **Échap** (ou un clic sur le logo « Les Mouz ») ouvre le **menu** et arrête le temps : Reprendre, Sauvegarder, Sauvegarder sous… (une copie avec un autre nom, qui devient la partie en cours), Charger une partie…, **Retour au quartier**, Menu principal, Quitter le jeu. **Ctrl+S** sauvegarde à tout moment. Un message en bas de l'écran confirme chaque sauvegarde ; en cas d'échec, il reste 6 secondes et propose « Réessayer ».

La partie en cours est aussi **sauvegardée automatiquement** : peu après chaque modification du terrain, au retour en mode Vivre, toutes les 2 minutes, avant d'en charger une autre et à la fermeture du jeu.

Une sauvegarde contient tout le quartier : l'heure, et pour chaque emplacement son terrain et la famille qui y vit (prénoms, apparences, liens, argent ; et, une fois jouée, la position, les besoins, les relations, l'autonomie, le métier et les compétences de chaque Mouz, les factures, le Mouz sélectionné et la caméra). Les parties d'avant les humains (format 2) retrouvent Pépin et Myrtille, devenus humains ; celles d'avant le quartier (format 3) y entrent : leur maison prend le premier terrain libre, sous le nom « Ma maison », et l'on continue de jouer leur famille.

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

Le format est en version 4 (voir `migrate()`). La version 1 n'avait pas de styles, et six objets y étaient dessinés face avant en bas. La migration leur donne le style Nature et les retourne d'un demi-tour, pour qu'ils gardent leur aspect.

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
| Clic sur le Mouz sélectionné | Son téléphone : « Petites annonces », « Inviter un voisin… », « Démissionner » |
| Clic sur un voisin en visite | Actions sociales, « Raccompagner à la porte » |
| Clic sur ✕ dans la file | Annule l'action |
| Boutons Pépin / Myrtille, ou **Tab** | Change de Mouz |
| Bouton « Autonomie » | Active ou coupe l'autonomie du Mouz sélectionné |
| Pause / x1 / x2 / x3, ou **Espace** et **1** à **3** | Vitesse du jeu |
| **V** | Hauteur des murs : coupés (par défaut), baissés, pleins |
| **M** | Couper ou remettre la musique |

Un ordre du joueur remplace toujours les actions choisies par l'autonomie.

### Construire (le temps est en pause)

| Outil | Geste |
|---|---|
| Pièce | Glisser un rectangle : murs tout autour et sol dedans, en une seule opération (une seule annulation). On choisit la couleur des murs et le sol dans le panneau ; un mur déjà là (pièce voisine) n'est pas repayé |
| Mur | Glisser le long de la grille : un mur droit, payé par segment |
| Clôture | Glisser le long de la grille : piquets blancs, planches de bois ou haie taillée, payés par segment. Une clôture bloque le passage mais ne ferme pas de pièce (le jardin reste dehors) |
| Démolir | Glisser sur des murs ou des clôtures : ils sont revendus, avec leurs portes, fenêtres et portails |
| Porte, Fenêtre | Clic sur un mur. Le battant s'ouvre du côté du pointeur ; **R** inverse la charnière. Le **portail** (dans les portes) se pose sur une clôture et s'ouvre quand un Mouz passe |
| Sol | Glisser pour peindre un rectangle ; l'ancien revêtement est revendu. Pour le jardin : allée de gravier, allée de dalles et terrasse en bois |
| Gomme | Glisser pour remettre de l'herbe (revêtement revendu) |
| Piscine | Glisser un rectangle dans le jardin (hors des pièces, sans objet ni mur dedans) : un bassin d'eau avec sa margelle, 60 Mz la case. On ne le traverse pas à pied ; la gomme le rebouche (revente). Au bord, une **échelle** (« Nager », 1 h) et un **plongeoir** (« Plonger ») du catalogue Jardin : le Mouz fait des longueurs, le bas du corps sous l'eau ; Forme, Plaisir et Hygiène montent, l'énergie baisse |
| Toit | Choisir un style (chaume, tuiles rouges, zinc, ardoise) ou « Sans toit », puis cliquer sur le terrain : il couvre toute la maison, au prix des cases couvertes (l'ancien est revendu). On le voit en mode Vivre avec le réglage « Toits » (touche V) |
| Papier | Clic dans une pièce fermée : le papier peint choisi habille la face visible de ses murs (le mur du haut de chaque case, vue trois quarts) ; « Retirer » le revend. Les portes séparent les pièces. Démolir un mur revend aussi son papier |
| Déplacer | Clic sur un objet pour le reprendre, puis le reposer |
| ▼ RDC ▲ (barre du haut) ou Page bas / Page haut | Change d'étage : on construit et on achète à l'étage regardé (voir « Les étages ») |
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
  quartier/            Le quartier (quartier.tres : emplacements, adresses), ses maisons
                       (maisons/*.tres) et le terrain des emplacements libres — générés par
                       tools/construire_quartier.gd
  settings/            Horloge, autonomie, économie
scenes/                title.tscn (accueil, scène de démarrage), neighborhood.tscn (le quartier),
                       new_game.tscn (création d'une famille), main.tscn (le jeu), personnage, objet, HUD
scripts/
  core/                Autoloads (GameClock, EventBus, Wallet, GameMode), monde, rendu, navigation,
                       caméra, catalogue, sauvegarde
  lot/                 Terrain : arêtes, murs, sols, ouvertures, objets posés, définitions du catalogue
  editor/              Modes Construire et Acheter : éditeur de terrain, contrôleurs, grille
  needs/               Définition d'un besoin et composant « besoins » d'un personnage
  objects/             Définitions d'action et d'objet, objet posé dans le monde
  characters/          Personnage, déplacement, file d'actions, autonomie, relations, famille,
                       apparence (calques à teinter) et corps dessiné en jeu
  neighborhood/        Quartier : définitions, données de la partie, familles au hasard, outil de maisons
  save/                Autoload SaveManager, format JSON (quartier, foyer, terrain), vignettes
  ui/                  Autoload Palette, thème, panneaux du HUD, portraits, écran d'accueil, menu en jeu
  ui/creation/         Écran de création : colonne de la famille, aperçu, éditeur
  ui/neighborhood/     Écran du quartier : carte, plans des terrains, fiche d'un emplacement
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

**Ajouter un personnage** : dupliquer `data/characters/myrtille.tres` (nom, `sprite`, `color`), ajouter la copie à `character_profiles` sur le nœud `World`, et une case de départ dans `spawn_cells` de `data/quartier/terrain_libre.tres`.

**Lancer directement le jeu sans l'accueil** : ouvrir `scenes/main.tscn` dans l'éditeur et appuyer sur F6 (terrain : `starting_lot` du nœud `World`, par exemple une maison de `data/quartier/maisons/`). La partie n'a alors pas d'emplacement : « Sauvegarder » en crée une, nommée « Ma partie », dans un quartier neuf où cette maison prend le premier terrain libre.

## Où modifier l'équilibrage

| Quoi | Où |
|---|---|
| Budget de départ, part rendue à la revente (même jour / ensuite) | `data/settings/economy_settings.tres` |
| Prix des objets, sols, murs, portes et fenêtres | `data/catalog/**/*.tres` (`price`, `price_per_cell`, `price_per_segment`) |
| Maisons du quartier, cases de départ | `tools/construire_quartier.gd` (puis relancer l'outil) |
| Emplacements, nombre de familles au départ | `data/quartier/quartier.tres` (`plots`, `starting_families`) |
| Prix des maisons, compositions des familles au hasard | `scripts/neighborhood/neighborhood.gd` (`PRICE_RATIO`, `COMPOSITIONS`) |
| Relation de départ selon le lien de famille | `Family.LINK_START` (`scripts/characters/family.gd`) |
| Prénoms et noms tirés au dé | `scripts/ui/creation/name_ideas.gd` |
| Vitesse de baisse d'un besoin, poids dans l'humeur, seuil critique, valeur de départ | `data/needs/*.tres` (`decay_per_hour`, `mood_weight`, `critical_threshold`, `start_value`) |
| Durée et gains d'une action | `data/actions/*.tres` (`duration_minutes`, `need_gains`, `relationship_gain`) |
| Coût des repas (courses) | `data/actions/*.tres` (`cost`) |
| Clôtures (aspect, couleurs, prix par segment) | `data/catalog/fences/*.tres` (`look` : piquets, planches, haie) |
| Papiers peints (couleur, motif, prix par pan) | `data/catalog/wallpapers/*.tres` (`pattern` : uni, rayures, pois, losanges, carreaux) |
| Recette du travail à la maison | `data/actions/*.tres` (`earning_base`, `earning_per_level`) |
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

## La musique

L'autoload `Music` joue une piste en boucle selon l'écran, avec un fondu enchaîné d'environ une seconde :

| Écran | Fichier |
|---|---|
| Accueil et création de la famille | `assets/musique/menu.mp3` |
| Vivre | `assets/musique/jeu.mp3` |
| Construire | `assets/musique/construction.mp3` |
| Acheter | `assets/musique/achat.mp3` |

Aujourd'hui : `menu.mp3` est « Good Morning, World! », `jeu.mp3` est « Felt Piano Motif », `construction.mp3` est « Relaxed Gaming Groove ». Une piste absente est remplacée par sa voisine (Acheter ↔ Construire, sans reprendre la musique au début quand on passe de l'un à l'autre), sinon par `jeu.mp3`. L'accueil, lui, reste silencieux s'il n'a pas de `menu.mp3`. Pour ajouter une piste, dépose le fichier sous ce nom : rien à changer dans le code. Le volume se règle dans `scripts/core/music.gd` (`VOLUME_DB`).

## Le travail

Un Mouz trouve un métier dans les **petites annonces** :

- **sur son téléphone** : clic sur le Mouz sélectionné, « Petites annonces (téléphone) » ; 3 annonces ;
- **sur l'ordinateur** : action « Lire les petites annonces » (20 min) ; 5 annonces, dont celles du téléphone.

Les annonces changent chaque jour (tirées au sort d'après le numéro du jour). Le jour 1 est un lundi ; l'horloge affiche le jour de la semaine (« Lun. 1 — 08:00 »).

| Métier | Jours | Horaires | Salaire |
|---|---|---|---|
| Développeur·se web | Lun – Ven | 9 h – 17 h | 280 Mz |
| Infirmier·ère | Lun – Ven | 7 h – 15 h | 260 Mz |
| Pianiste de salon | Mer – Sam | 15 h – 22 h | 240 Mz |
| Commis de cuisine | Mar – Sam | 10 h – 18 h | 210 Mz |
| Jardinier·ère paysagiste | Lun – Ven | 8 h – 15 h | 190 Mz |
| Libraire | Mar – Sam | 10 h – 18 h | 180 Mz |
| Illustrateur·rice | Lun – Jeu | 11 h – 17 h | 170 Mz |
| Serveur·se (petit boulot, dès l'adolescence) | Ven – Dim | 17 h – 21 h | 90 Mz |
| Livreur·se de journaux (dès l'adolescence) | Lun – Sam | 6 h – 8 h | 60 Mz |

Les enfants ne travaillent pas ; les ados n'ont que les petits boulots.

Une journée de travail (`MouzJob`, un composant de chaque Mouz) :

1. À l'heure de début, un jour travaillé, le Mouz laisse tomber ce qu'il faisait et sort par la rue (en bas du terrain). Au bout de 20 minutes de marche, il est parti de toute façon (il a pris le bus).
2. Au travail, il disparaît : il n'est plus cliquable, ses ordres sont refusés avec un message, l'autonomie le laisse tranquille. L'en-tête affiche « Au travail jusqu'à 17 h ».
3. À l'heure de fin, il revient par la rue avec son salaire (« Pépin rentre du travail : +280 Mz ») et sa journée a marqué ses besoins (`need_changes` du métier : moins d'énergie, plus ou moins de plaisir…).

### Carrière

Chaque métier a **5 grades**, avec un intitulé et un salaire chacun (Commis 210 Mz → Cuisinier·ère 270 → Chef·fe de partie 340 → Sous-chef·fe 420 → Chef·fe étoilé·e 520). Pour monter d'un grade, il faut, au retour du travail :

1. le **niveau demandé dans la compétence du métier** : 2, puis 4, 6, 8 (Cuisine pour la cuisine, Informatique pour le développement, Charisme pour l'infirmerie et le service…) ;
2. une **performance** d'au moins 80 %. Elle part de 50 % et bouge à chaque départ au travail : +15 de bonne humeur (≥ 65), +5 d'humeur moyenne, −10 grognon, et encore −10 si l'énergie est sous 20.

Une promotion remet la performance à 50 %. Une performance tombée à 0 fait redescendre d'un grade. Dans les petites annonces, la carte « Ton métier » montre le grade, la performance et ce qu'il manque pour le suivant ; les autres annonces montrent jusqu'où mène la carrière.

Les métiers sont des `JobDefinition` dans `data/jobs/` : en ajouter un, c'est ajouter un `.tres` (nom, phrase de l'annonce, icône, horaires, jours, âge minimum, effets sur les besoins, et pour la carrière : compétence, intitulés, salaires et niveaux de chaque grade). Le métier, le grade, la performance et l'état « au travail » sont sauvegardés avec chaque Mouz.

## Le quartier

Une partie, c'est un **quartier** : le quartier des Tilleuls, huit emplacements de part et d'autre de la rue des Lilas.

| Emplacement | Maison | Style |
|---|---|---|
| 1 rue des Lilas | La Bicoque : grande pièce à vivre, une chambre | Nature |
| 3 rue des Lilas | Les Glycines, sur deux niveaux : en bas salon, cuisine, salle de jeux, WC et hall avec l'escalier ; en haut chambre des parents, chambre des enfants, salle de bain avec baignoire | Rétro |
| 7 rue des Lilas | Villa Horizon : grande pièce ouverte, bureau avec ordinateur, chambre, entrée avec l'escalier ; à l'étage, une chambre d'amis et un palier | Moderne |
| 2 rue des Lilas | Le Potager : petite maison, grand jardin (trois potagers, barbecue, salon de jardin, hamac) | Nature |
| 6 rue des Lilas | L'Atelier : atelier avec piano et chevalet, cuisine, chambre, grande salle de bain | Rétro |
| 4, 5 et 8 rue des Lilas | Terrains libres | |

- À la création, **trois familles tirées au hasard** (une personne seule, un couple, des parents et leurs enfants, des colocs, un parent et son ado, deux aînés…) s'installent dans trois des maisons. Elles ont payé leur maison et gardent un peu d'argent.
- **L'écran du quartier** montre la carte, avec le plan de chaque terrain. Un clic sur un emplacement ouvre sa fiche : la famille qui y vit (membres, âges, argent) et **Jouer cette famille**, ou bien le prix et **Faire emménager une famille**. Un double-clic fait la même chose que le bouton.
- **Faire emménager une famille** ouvre la création : nom de famille, 1 à 4 membres. Pour chacun : prénom (le dé en tire un), homme ou femme, âge (enfant, ado, adulte, aîné), peau, coupe et couleur des cheveux, tenue et sa couleur, ou « Apparence au hasard ». Entre deux cartes, une pastille fixe leur **lien** (couple, parent, enfant, frères et sœurs, colocs), qui donne leur relation de départ. Il faut au moins un adulte ou un aîné, et un prénom à chacun. La famille arrive avec 20 000 Mz, moins le prix de la maison (70 % de ce qu'elle a coûté, arrondi à 500 Mz ; un terrain libre est gratuit). Sur un terrain libre, on commence en mode Construire.
- **Déménager** : dans la fiche d'une famille, « Déménager… », puis on choisit sur la carte une maison à vendre ou un terrain libre. La fiche montre l'argent du foyer, la vente de l'ancienne maison (meubles compris, au prix d'une maison à vendre : 70 % de ce qu'elle a coûté), le prix de la nouvelle et ce qu'il restera ; « Déménager ici » si l'argent suffit. Les Mouz emportent tout ce qu'ils sont (besoins, métiers, compétences, amitiés avec les voisins) ; les meubles restent avec la maison, remise en vente (une maison bâtie sur un terrain libre prend le nom « La maison des … »). Échap ou « Annuler » abandonne.
- On joue **une famille à la fois** ; les autres attendent, comme on les a laissées. Chaque famille a son argent ; l'heure est commune au quartier. **Retour au quartier** (menu Échap) enregistre la famille et revient à la carte.

Les maisons sont décrites en code dans `tools/construire_quartier.gd` (pièces, portes, fenêtres, meubles en coordonnées de cases, `on_level(1)` pour passer à l'étage), avec l'aide de `HouseBuilder`. Les deux maisons à étage (31 500 et 23 000 Mz) sont trop chères pour une famille qui arrive : on y accède en déménageant, une fois qu'on a économisé. Pour les régénérer :

```
godot --headless --script tools/construire_quartier.gd
```

## Les visites

Les familles du quartier se rendent visite.

- **Inviter** : clic sur son Mouz, « Inviter un voisin… ». La liste montre chaque voisin, sa famille et la relation qu'on a avec lui ; il arrive par la rue une demi-heure plus tard. On ne peut pas inviter avant 8 h ni après 21 h, quelqu'un qui est déjà là ou en route, ni plus de trois visiteurs à la fois (« maison pleine »).
- **Visites spontanées** : entre 10 h et 19 h, s'il n'y a personne, un voisin (pas un enfant) passe parfois sans prévenir (8 % de chances par heure).
- **Bienvenue** : une heure après l'emménagement d'une nouvelle famille, un ou deux voisins viennent dire bonjour.
- **Pendant la visite**, le voisin vit sa vie chez vous : il discute, s'assoit, regarde la télé, joue… mais ne dort pas, ne se lave pas, ne mange pas vos courses, ne touche pas aux lampes et ne travaille pas. Il apparaît dans le panneau Relations (« En visite ») et on peut lancer avec lui les actions sociales.
- **Départ** : au bout de 2 h 30 à 5 h, à 22 h au plus tard, ou quand on le **raccompagne à la porte**, il repart par la rue.

Les relations avec les voisins sont gardées dans le quartier (`"relationships"` de la sauvegarde, une valeur par paire de Mouz) : on retrouve ses amis d'une visite à l'autre, et quand on joue l'autre famille. Deux membres d'une même famille venus ensemble gardent leur relation de famille. Les visiteurs ne sont pas sauvegardés : une partie rechargée repart sans eux. Réglages : `scripts/neighborhood/visits.gd`.

## Les plantations

Le **potager** et le **massif de fleurs** (catalogue Jardin) poussent tout seuls s'ils ont de l'eau : graines → pousses → mûr (ou fleuri) en 3 jours. L'eau tient environ deux jours ; une goutte apparaît au-dessus quand la plantation a soif, et à sec elle **fane** (elle ne pousse plus) jusqu'au prochain arrosage.

- **Arroser** remet l'eau au plein et sauve une plantation fanée ; **Jardiner** fait avancer la pousse.
- **Récolter** et **Vendre des légumes au marché** demandent un potager mûr ; il repart ensuite des graines.
- **Admirer les fleurs** (Plaisir) demande un massif fleuri.
- Une plantation achetée part des graines ; celles des maisons du quartier sont déjà mûres.

Les états sont dessinés provisoirement en attendant le brief n° 8. Réglages : `scripts/objects/garden.gd`.

## Les toits

Le toit se calcule tout seul : un toit à quatre pans sur chaque pièce fermée qui n'a pas de plancher au-dessus (sur une maison à étage, le toit du rez-de-chaussée couvre ce qui dépasse). Chaque case monte selon sa distance au bord de la pièce (16 px par case), à partir du haut des murs pleins ; le faîtage, les arêtiers et les noues se placent d'eux-mêmes. La maison partage un seul style, choisi avec l'outil Toit (les maisons du quartier en ont déjà un).

La touche V passe par **murs pleins → murs coupés → murs baissés → toits**. Avec « Toits », en mode Vivre, on voit la maison de l'extérieur : murs pleins et toit sur les pièces ; quand on regarde un étage, les étages au-dessus (cachés) ne comptent pas et le toit couvre celui qu'on regarde. Le dessin est provisoire (aplats, rangs du matériau) en attendant le brief n° 8 (`docs/brief-claude-design-8.md`). Réglages : `scripts/core/roof_view.gd`, styles dans `data/catalog/roofs/`.

## Les étages

Une maison peut avoir **deux étages** au-dessus du rez-de-chaussée.

- **Regarder un étage** : le sélecteur de la barre du haut (descendre, trois points pour l'étage regardé, « RDC », « 1er » ou « 2e », monter), ou Page haut / Page bas. L'étage regardé est dessiné normalement ; ceux du dessous restent visibles sous un voile (45 % pour l'étage juste en dessous, 60 % deux étages plus bas), là où il n'a pas de sol ; ceux du dessus sont cachés. En mode Vivre, la vue suit le Mouz contrôlé quand il change d'étage, et le portrait d'un Mouz qui n'est pas à l'étage regardé porte un badge « RDC », « 1er » ou « 2e ».
- **Construire à l'étage** : un sol d'étage se pose au-dessus d'une **pièce fermée** de l'étage du dessous (en mode Construire, ces cases portent un « + » vert ; ailleurs, le vide est hachuré). Le bord d'un plancher montre sa tranche et son ombre sur l'étage du dessous ; un garde-corps se pose tout seul autour de la cage d'escalier (sauf du côté de l'arrivée) et au bord du plancher là où il n'y a pas de mur. L'outil Pièce y marche aussi. Murs, portes, fenêtres et papier peint se posent au bord du plancher ; les objets, sur le plancher. Les clôtures restent au jardin (rez-de-chaussée).
- **L'escalier** (catalogue, catégorie Construction, 900 Mz, en Nature, Rétro et Moderne) : 1 × 3 cases, 8 marches, il monte d'un étage. On le pose à l'étage du bas, la marche du bas du côté de sa face avant ; il faut un plancher à l'étage, au bout de la dernière marche. Les cases au-dessus des marches deviennent la cage d'escalier (pas de sol, on voit l'escalier en dessous).
- **Les Mouz** prennent l'escalier tout seuls quand ce qu'ils vont faire est à un autre étage (ordres du joueur, autonomie, visiteurs, départ au travail). Ils montent marche par marche le long du dessin (`data/vue34/escalier.json`, la « ligne des marches » de chaque vue) : de profil avec leurs images « monter » et « descendre », de face ou de dos avec celles de la marche, sans ombre. Ils restent de l'étage du bas jusqu'à la dernière marche. La rampe (de profil) et les marches du dessus (de dos) passent devant eux.

Dessins : brief n° 7 (`docs/brief-claude-design-7.md`, livraison dans `design/`). Côté code : `Levels` (cases de navigation, un décalage de `Levels.STRIDE` lignes par étage), `LotLevel` (les données d'un niveau), `GridNavigation` (un seul graphe pour tous les niveaux, relié par les escaliers).

## Gagner de l'argent à la maison

Sans métier, ou en plus, un Mouz peut travailler chez lui. Ces activités se lancent depuis l'objet et rapportent à la fin, selon son niveau dans la compétence de l'activité. Le menu de l'objet affiche ce qu'elles rapporteront (« Peindre un tableau à vendre · 92 Mz »).

| Activité | Objet | Compétence | Durée | Recette |
|---|---|---|---|---|
| Peindre un tableau à vendre | chevalet | Art | 3 h | 20 + 18 par niveau |
| Vendre des légumes au marché | potager | Jardinage | 1 h 30 | 10 + 7 par niveau |
| Mission en freelance | ordinateur | Informatique | 3 h | 20 + 20 par niveau |
| Écrire un article | bureau | Culture | 2 h | 10 + 13 par niveau |
| Composer une chanson | piano | Musique | 3 h | 15 + 18 par niveau |

- Au niveau 0, c'est peu (5 à 7 Mz de l'heure) ; vers le niveau 4, autant qu'un premier grade de métier ; au niveau 10, autant qu'un bon métier, mais fatigant (énergie qui baisse).
- Interrompue après au moins un quart de sa durée, l'activité rapporte au prorata (« inachevé »).
- Les Mouz ne les choisissent jamais d'eux-mêmes en autonomie (`autonomous = false`).
- La mission en freelance demande l'électricité (ordinateur).

Une action rapporte dès qu'elle a `earning_base` ou `earning_per_level` (`ActionDefinition`, section « Revenu ») ; `earning_text` est le message (« %s vend un tableau »).

## L'usure et les pannes

Les appareils s'usent quand on s'en sert : frigo, cuisinière, micro-ondes, machine à café, lave-vaisselle, machine à laver, télé, ordinateur, console, chaîne hi-fi, douche, baignoire, toilettes, lavabo et évier (`wear_per_hour` de leur définition : de 3 à 10 points par heure d'utilisation, un peu au hasard). À 100, l'objet **tombe en panne** : un message, un petit son, un panneau rouge au-dessus de lui ; ses actions sont grisées (« en panne ») et l'autonomie l'ignore. Au-delà de 50, son menu le dit « usé ».

Deux façons de le remettre en état, depuis son menu :

- **Réparer** (1 h) : réussit à 45 % au niveau 0 de **Bricolage**, 5,5 % de plus par niveau (100 % vers le niveau 10) ; sinon il faut réessayer. Le menu affiche la chance de réussite. Réparer fait monter le Bricolage.
- **Appeler un réparateur** : 50 Mz + 15 % du prix de l'objet, payés tout de suite ; il passe une heure plus tard.

Un objet en panne se revend moitié moins cher. L'usure et le réparateur attendu sont sauvegardés. Réglages : `scripts/objects/upkeep.gd`.

## Les courses

Manger coûte : les actions qui nourrissent ont un `cost` (`data/actions/*.tres`), payé quand le Mouz s'y met. Sans assez d'argent, elles sont grisées (« pas assez d'argent ») et l'autonomie les ignore.

| Action | Coût |
|---|---|
| En-cas | 3 Mz |
| Apéro | 5 Mz |
| Réchauffer un plat | 6 Mz |
| Manger (frigo), manger à table | 8 Mz |
| Préparer un repas | 10 Mz |
| Cuisiner | 15 Mz |
| Barbecue | 20 Mz |

Pendant qu'un Mouz est au travail, ses besoins baissent moitié moins vite (il mange et se pose sur place) ; le métier marque la journée au retour par ses `need_changes`. Réglage : `NeedsComponent.AWAY_DECAY`.

## Les factures

Tous les 3 jours (jours 3, 6, 9…) à 8 h, une facture arrive : **50 Mz + 1,5 % de la valeur de la maison** (ce qu'ont coûté ses murs, sols, portes, fenêtres et objets). La maison de démo (19 136 Mz) reçoit ainsi 337 Mz tous les 3 jours, à comparer à 60 – 640 Mz de salaire par jour travaillé.

- Les factures à payer s'affichent à côté de l'argent, en haut de l'écran. Un clic montre le détail et propose « Tout payer ».
- Une facture est à payer dans les 3 jours. En retard, elle est **majorée de 10 %** et **l'électricité est coupée** : le bouton passe au rouge, les objets électriques (frigo, cuisinière, micro-ondes, machine à café, lave-vaisselle, machine à laver, télé, ordinateur, console, chaîne hi-fi, lampes, aquarium) ne servent plus, les lampes s'éteignent et l'autonomie les ignore. Tout payer rétablit le courant.

Les réglages sont dans `scripts/core/bills.gd` (intervalle, heure, délai, forfait, taux, majoration, objets électriques). Les factures et la coupure sont sauvegardées.

## Les compétences

Chaque Mouz a 9 compétences, de 0 à 10, visibles dans l'onglet « Compétences » du panneau de gauche :

| Compétence | Actions qui la font monter |
|---|---|
| Cuisine | cuisiner, préparer un repas, barbecue |
| Informatique | surfer, jouer ou discuter en ligne, jeux vidéo, freelance |
| Musique | jouer du piano, écouter de la musique, composer |
| Art | peindre, peindre un tableau à vendre |
| Jardinage | jardiner, récolter, arroser, vendre des légumes |
| Culture | lire (partout), écrire, écrire un article, observer les étoiles, échecs |
| Forme | yoga, balançoire, danser, grimper |
| Charisme | discuter, apéro, cartes |
| Bricolage | réparer un objet en panne |

Chaque minute passée sur l'action compte. Le niveau 1 demande 1 h de pratique, et chaque niveau 70 min de plus (du niveau 9 au 10, environ 11 h 30 ; environ 66 h de pratique pour tout monter). On apprend ×1,5 de bonne humeur (≥ 65), ×0,5 grognon (≤ 35) ; les enfants ×1,3, les ados ×1,2, les aînés ×0,9. Un niveau gagné s'annonce par un message et un petit son.

Les réglages sont dans `scripts/characters/skills.gd` ; une action choisit sa compétence avec son champ `skill`.

## Les bruitages

L'autoload `Sfx` joue de courts sons, rangés dans `assets/sons/<nom>.wav` :

| Son | Quand |
|---|---|
| `clic` | n'importe quel bouton |
| `poser`, `achat` | un objet acheté et posé (ou déplacé) |
| `construire` | un mur, un sol, une porte ou une fenêtre posés |
| `vente` | une revente |
| `erreur` | une pose refusée, un message d'échec |
| `sauvegarde` | un message de réussite (« Partie enregistrée ») |
| `alerte` | un besoin critique pour le Mouz sélectionné |
| `porte` | une porte qui s'ouvre au passage d'un Mouz |
| `eau`, `cuisson`, `micro_ondes`, `piano`, `manger`, `interrupteur` | au début de l'action correspondante (`ACTION_SOUNDS` dans `scripts/core/sfx.gd`) |
| `chasse` | à la fin de l'utilisation des toilettes |
| `niveau`, `promotion` | un niveau de compétence gagné, une promotion |

Les sons de la maison sont placés dans le monde : plus faibles quand la scène est loin de l'écran. Un même son ne se répète pas à moins de 80 ms (un mur tiré sur dix cases ne fait pas dix bruits d'affilée).

Ces sons sont **provisoires** : ils sont synthétisés par `tools/generer_sons.py` (`python3 tools/generer_sons.py`). Pour en remplacer un, dépose un vrai fichier sous le même nom ; un son absent est simplement ignoré.

## Le jour et la nuit

`DayNight` (enfant du monde) teinte la maison selon l'heure : nuit bleutée jusqu'à 5 h, aube rosée vers 6 h 30, plein jour de 8 h à 18 h, coucher orangé vers 19 h 30, nuit à partir de 21 h. Les couleurs sont dans `SKY` (`scripts/core/day_night.gd`). L'interface n'est pas teintée.

La nuit, les objets en marche éclairent autour d'eux : lampes de chevet et sur pied, cheminée, télé, ordinateur, cuisinière, barbecue (`LIGHTS` : couleur et rayon). En Construire et Acheter, la nuit est nettement adoucie pour qu'on voie ce qu'on fait.

## La vue trois quarts

Le jeu passe progressivement en vue trois quarts (brief n° 6, livré par lots ; règles complètes dans `design/README.md`). La grille reste carrée, les objets montent vers le haut de l'écran.

- **Ordre d'affichage** : `World`, `Objects`, `Characters` et `WallView` ont `y_sort_enabled`. Chaque nœud est posé à son point de tri : le bas de l'emprise pour un objet, les pieds pour un personnage, le pied du mur pour un morceau de mur. Ce qui est plus bas à l'écran passe devant.
- **Murs** (`WallView`) : un Sprite2D par segment, par poteau (forme choisie selon les murs qui partent du nœud) et par ouverture. En murs coupés, un mur horizontal qui cache une pièce est baissé ; les murs verticaux restent pleins. En Construire et Acheter, tout est baissé. Les portes s'ouvrent quand un Mouz est sur l'une des cases qu'elles séparent.
- **Clics** : `World.get_object_at_point` cherche l'image de l'objet (hauteur comprise), celle de devant en premier.
- **Lot 1 livré** : murs, portes, fenêtres, 7 objets témoins en Nature (canapé, télé, lit, frigo, table, chaise, plante). Les autres objets restent vus de dessus en attendant leur lot.
- **Lot 2 livré** : les humains. `MouzAppearance` liste les calques à superposer (ombre, cheveux arrière, pantalon, peau, tenue, contours, tête, cheveux), blancs dans les SVG et teintés par `modulate`. `MouzBody` les dessine en jeu (32 × 64, pieds à 48 px du haut ; `droite` = `gauche` retourné ; tête et cheveux remontent d'1 px en marchant), `MouzPortrait` dessine le portrait de face dans l'interface. Les calques sont importés à l'échelle 2 (portraits à l'échelle 4) pour rester nets.
- **Lot 3 livré** : la cuisine complète dans les trois collections (frigo, cuisinière, évier, plan de travail, table, chaise, micro-ondes, machine à café, lave-vaisselle, poubelle). Cuisinière, micro-ondes, machine à café et lave-vaisselle ont des vues « en marche » (`_actif`). L'évier et le plan de travail, asymétriques, ont leur propre vue `droite`. Micro-ondes et machine à café sont dessinés posés sur un petit meuble bas.
- **Lots 4 et 5 livrés** : chambre, salle de bain, salon et déco dans les trois collections. Vues « en marche » : lampes, douche, machine à laver, télé, cheminée, chaîne hi-fi. Le tapis n'a que deux vues (`bas` et `gauche`) : de dos, le jeu reprend la vue `bas`, et de droite la vue `gauche` retournée. Il reste dessiné sous tout le reste.
- **Lot 6 livré** : loisirs et jardin (ordinateur sur son bureau, piano, chevalet, tapis de yoga, table de jeux, télescope, barbecue, hamac, balançoire, potager, salon de jardin, arbre). Tous les objets du catalogue sont désormais en vue trois quarts ; une image `_actif` a toujours la même taille que la version éteinte.
- **Lot 7 livré** : les poses. Pendant une action sur une chaise, un fauteuil, un canapé, les toilettes, une table de jeux, un salon de jardin, un lit, une baignoire, un hamac, un tapis de yoga ou le potager, le Mouz s'installe à sa place : assis, en tailleur, à genoux ou allongé, puis se relève et retrouve sa case à la fin. Les places viennent de `data/vue34/places.json` (extrait de `design/tokens.json`), lues par `SeatPlaces`. Assis, le nœud du Mouz prend le point de tri de l'objet (un rien après lui) et son corps est décalé vers sa place ; un calque `_devant_<n>` de l'objet (dossier, couette, eau du bain) est redessiné devant lui par `SeatFront`. Chaque utilisateur garde sa place (`SmartObject._seats`) jusqu'à ce qu'il parte. Allongé, ce sont les calques debout de face, tournés autour du centre de la tête. Le catalogue affiche les vignettes dessinées pour lui (`assets/vignettes/`).

## Limites connues

- Les Mouz peuvent se traverser : ils ne bloquent pas la navigation.
- Deux Mouz peuvent viser le même objet. Le premier arrivé le réserve, et l'action du second est annulée ; son autonomie choisit alors autre chose.
- La file d'actions des Mouz n'est pas sauvegardée : au chargement, ils repartent les mains vides (l'autonomie reprend vite la main).
- Rien n'empêche de démolir les murs du dessous d'un étage, ni de revendre l'escalier quand un Mouz est en haut : l'étage reste en l'air, et le Mouz y reste jusqu'à ce qu'on repose un escalier.
- Les étages sont dessinés au même endroit que le rez-de-chaussée (pas de décalage en hauteur) : en haut de l'escalier, le Mouz redescend de quelques pixels pour rejoindre le plancher de l'étage. Le badge des portraits ne montre pas encore l'icône d'escalier pendant la montée.
- Au travail, un Mouz est simplement absent : on ne le voit pas travailler. Une mauvaise performance fait redescendre d'un grade, jamais renvoyer.

## Crédits

Polices [Baloo 2](https://fonts.google.com/specimen/Baloo+2) et [Nunito](https://fonts.google.com/specimen/Nunito), sous licence SIL Open Font License 1.1 (textes de licence dans `assets/fonts/`).
