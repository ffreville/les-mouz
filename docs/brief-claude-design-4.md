# Brief n° 4 pour Claude Design : « Les Mouz », catalogue de 50 objets en plusieurs styles

Même direction artistique « Maison de poche » que les lots précédents (maquettes : https://claude.ai/artifact/UXdkDt3fTCFtjiGrQ62zEE, référence complète dans `design/README.md`). Mêmes règles : vue strictement de dessus, aplats, contour encre 2 px `#3D3357` (détails 1,5 px), pas de dégradé, grille de 32 px par case, sprite exactement à la taille de l'objet en cases.

Le catalogue du jeu passe de 20 à **50 objets**, et chaque objet existe en **2 ou 3 styles**. Il me faut les sprites, les icônes des nouvelles interactions et l'interface pour choisir un style.

## Les styles : trois collections

Pour que le joueur puisse meubler une maison cohérente, les variantes suivent trois **collections** qui traversent tout le catalogue. Propose leur identité précise (palette, matières, formes) en restant dans la palette du jeu :

| Collection | Clé | Idée |
|---|---|---|
| Nature | `nature` | Bois clair, tissus sauge et lin, formes douces. Les sprites actuels en sont proches. |
| Rétro | `retro` | Couleurs chaudes (moutarde, brique, orange), pieds compas, formes arrondies. |
| Moderne | `moderne` | Blanc, ardoise, métal, lignes nettes, angles peu arrondis. |

- Chaque objet doit exister dans **au moins 2 collections**, idéalement les 3.
- Un style ne change que l'apparence : même taille en cases, même face avant, même interaction.
- Les 20 sprites existants comptent comme une variante. Dis-moi à quelle collection tu les rattaches, puis dessine les autres. Tu peux retoucher un sprite existant pour qu'il colle à sa collection.

## Prévoir les déclinaisons (plus tard)

Plus tard viendront des **déclinaisons** : des modèles différents d'un même objet, avec d'autres tailles, prix et effets, par exemple « Petit frigo » (1 × 1) puis « Frigo américain » (2 × 1). Ne les dessine pas maintenant, mais :

- garde un style qui laissera de la place pour une version « simple » et une version « luxe » de chaque objet ;
- pour chaque objet, **suggère 1 ou 2 déclinaisons** (nom, taille en cases, ce qui change) dans un tableau du README. Je m'en servirai pour le prochain brief.

## Les 50 objets

**Face avant** = côté où le Mouz se place pour s'en servir. Dessine-la **vers le haut**, comme pour le deuxième lot : le jeu tourne les objets par quarts de tour, ils doivent rester lisibles une fois tournés. Pour les 20 existants, fais la même chose dans les nouvelles variantes (le premier lot avait la face vers le bas).

Le prix est indicatif : corrige-le si un autre te paraît plus juste.

### Cuisine (10)

| Clé | Objet | Cases | Interactions | Prix | État |
|---|---|---|---|---|---|
| `frigo` | Frigo | 1 × 1 | Manger, Prendre un en-cas | 800 | existe |
| `cuisiniere` | Cuisinière | 1 × 1 | Cuisiner | 650 | existe |
| `evier` | Évier | 2 × 1 | Faire la vaisselle | 400 | existe |
| `plan_travail` | Plan de travail | 3 × 1 | Préparer un repas | 300 | existe |
| `table` | Table | 2 × 2 | Manger à table (à plusieurs) | 250 | existe |
| `chaise` | Chaise | 1 × 1 | S'asseoir | 80 | existe |
| `micro_ondes` | Micro-ondes | 1 × 1 | Réchauffer un plat | 200 | nouveau |
| `machine_cafe` | Machine à café | 1 × 1 | Boire un café | 180 | nouveau |
| `lave_vaisselle` | Lave-vaisselle | 1 × 1 | Lancer la vaisselle | 450 | nouveau |
| `poubelle` | Poubelle | 1 × 1 | Sortir la poubelle | 40 | nouveau |

### Chambre (8)

| Clé | Objet | Cases | Interactions | Prix | État |
|---|---|---|---|---|---|
| `lit` | Lit double | 2 × 3 | Dormir, Faire la sieste | 1000 | existe |
| `armoire` | Armoire | 2 × 1 | Se changer | 700 | existe |
| `table_nuit` | Table de nuit | 1 × 1 | Lire un peu | 90 | existe |
| `bureau` | Bureau | 2 × 1 | Lire, Écrire | 450 | existe |
| `lit_simple` | Lit simple | 1 × 2 | Dormir | 600 | nouveau |
| `commode` | Commode | 2 × 1 | Ranger ses affaires | 400 | nouveau |
| `coiffeuse` | Coiffeuse avec miroir | 2 × 1 | Se coiffer | 500 | nouveau |
| `lampe_chevet` | Lampe de chevet | 1 × 1 | Lire au lit (décor) | 60 | nouveau |

### Salon (9)

| Clé | Objet | Cases | Interactions | Prix | État |
|---|---|---|---|---|---|
| `canape` | Canapé | 3 × 2 | Regarder la TV, Faire une sieste | 750 | existe |
| `tele` | Meuble TV | 3 × 1 | Regarder la TV (avec le canapé) | 600 | existe |
| `bibliotheque` | Bibliothèque | 3 × 1 | Lire | 350 | existe |
| `lampe_pied` | Lampe sur pied | 1 × 1 | Allumer, éteindre (décor) | 120 | existe |
| `fauteuil` | Fauteuil | 1 × 1 | S'asseoir, Lire | 350 | nouveau |
| `table_basse` | Table basse | 2 × 1 | Poser un verre (décor) | 150 | nouveau |
| `cheminee` | Cheminée | 2 × 1 | Se réchauffer | 1500 | nouveau |
| `console_jeux` | Console de jeux | 1 × 1 | Jouer aux jeux vidéo (à deux) | 400 | nouveau |
| `chaine_hifi` | Chaîne hi-fi | 1 × 1 | Écouter de la musique, Danser | 300 | nouveau |

### Salle de bain (7)

| Clé | Objet | Cases | Interactions | Prix | État |
|---|---|---|---|---|---|
| `douche` | Douche | 2 × 2 | Se laver | 900 | existe |
| `baignoire` | Baignoire | 3 × 2 | Prendre un bain | 1200 | existe |
| `toilettes` | Toilettes | 1 × 1 | Utiliser | 300 | existe |
| `lavabo` | Lavabo | 1 × 1 | Se laver les mains, Se brosser les dents | 250 | existe |
| `miroir_mural` | Miroir et meuble | 2 × 1 | Se maquiller, Se raser | 350 | nouveau |
| `machine_laver` | Machine à laver | 1 × 1 | Faire la lessive | 550 | nouveau |
| `panier_linge` | Panier à linge | 1 × 1 | Trier le linge | 50 | nouveau |

### Loisirs (6) — nouvelle catégorie

| Clé | Objet | Cases | Interactions | Prix | État |
|---|---|---|---|---|---|
| `ordinateur` | Ordinateur | 2 × 1 | Surfer, Jouer en ligne, Discuter en ligne | 900 | nouveau |
| `piano` | Piano | 2 × 1 | Jouer du piano | 1800 | nouveau |
| `chevalet` | Chevalet de peinture | 1 × 1 | Peindre | 300 | nouveau |
| `tapis_yoga` | Tapis de yoga | 1 × 2 | Faire du yoga (au sol, traversable) | 80 | nouveau |
| `table_jeux` | Table de jeux | 2 × 2 | Jouer aux échecs, Jouer aux cartes (à deux) | 400 | nouveau |
| `telescope` | Télescope | 1 × 1 | Observer les étoiles | 700 | nouveau |

### Jardin (6) — nouvelle catégorie, posée sur l'herbe

| Clé | Objet | Cases | Interactions | Prix | État |
|---|---|---|---|---|---|
| `barbecue` | Barbecue | 1 × 1 | Faire un barbecue | 450 | nouveau |
| `hamac` | Hamac | 3 × 1 | Faire la sieste | 350 | nouveau |
| `balancoire` | Balançoire | 2 × 1 | Se balancer | 300 | nouveau |
| `potager` | Potager | 2 × 2 | Jardiner, Récolter | 200 | nouveau |
| `salon_jardin` | Salon de jardin | 2 × 2 | Prendre l'apéro (à plusieurs) | 500 | nouveau |
| `arbre` | Arbre | 2 × 2 | Grimper (décor) | 150 | nouveau |

### Déco (4)

| Clé | Objet | Cases | Interactions | Prix | État |
|---|---|---|---|---|---|
| `plante` | Plante en pot | 1 × 1 | Arroser | 40 | existe |
| `tapis` | Tapis | 6 × 4 | Aucune (au sol, traversable) | 150 | existe |
| `aquarium` | Aquarium | 2 × 1 | Regarder les poissons, Nourrir les poissons | 600 | nouveau |
| `horloge` | Horloge comtoise | 1 × 1 | Remonter l'horloge | 450 | nouveau |

Objets « au sol, traversables » (tapis, tapis de yoga) : on marche dessus, ils passent sous les autres meubles. Objets « à plusieurs » : 2 Mouz ou plus s'en servent ensemble, prévois la place de chacun dans le dessin (deux places d'un même côté, ou face à face).

## Ce que j'attends

### 1. Sprites

- Les **30 nouveaux objets**, chacun dans 2 ou 3 collections.
- Les **20 objets existants** dans 1 ou 2 collections supplémentaires (face avant vers le haut).
- Fichiers dans `svg/sprites/`, nommés `<clé>_<collection>.svg` : `canape_nature.svg`, `canape_retro.svg`, `canape_moderne.svg`. Les fichiers existants gardent leur nom ; indique dans le README à quelle collection chacun correspond.
- Pour quelques objets, un **état « en marche »** facultatif mais bienvenu, nommé `<clé>_<collection>_actif.svg` : télé allumée, cheminée avec feu, douche qui coule, plaques rouges sur la cuisinière, écran d'ordinateur allumé, chaîne hi-fi avec des notes.

### 2. Icônes (24 × 24, trait 2 px, versions `encre` et `blanc`)

- Une icône par **nouvelle interaction** des tableaux ci-dessus (prendre un en-cas, faire la vaisselle, préparer un repas, s'asseoir, réchauffer, café, poubelle, sieste, se changer, écrire, ranger, se coiffer, se réchauffer, jeux vidéo, musique, danser, mains, dents, maquiller, lessive, linge, surfer, piano, peindre, yoga, échecs, cartes, étoiles, barbecue, se balancer, jardiner, récolter, apéro, grimper, arroser, poissons, horloge…). Tu peux en regrouper quand une même icône convient (par exemple lire et lire au lit).
- Les catégories **`loisirs`** et **`jardin`**.
- Une icône par **collection** (`nature`, `retro`, `moderne`).

### 3. Interface : choisir un style

Avec les mesures de chaque composant, comme dans les README précédents :

- **Vignette du catalogue** : la vignette montre la collection choisie, et des **pastilles de collection** (une par style disponible) permettent de changer de style avant d'acheter. La vignette garde ses états actuels (survol, choisi, trop cher).
- **Filtre par collection** dans le catalogue, à côté des onglets de catégorie (Toutes / Nature / Rétro / Moderne).
- Dans la **bulle d'un objet posé** (Déplacer / Revendre), une option **« Changer de style »** avec les pastilles, et le coût affiché s'il y en a un.
- Une maquette 1280 × 720 du **mode Acheter** avec le catalogue de la catégorie Salon, un objet en main en style Rétro et le filtre de collection visible.
- Une maquette d'une **maison meublée** dans chacune des trois collections, pour vérifier que chacune est cohérente.

### 4. Tableaux de référence dans le README

- Pour chaque objet : clé, nom, cases, face avant, collections disponibles, prix suggéré.
- Pour chaque objet : 1 ou 2 **déclinaisons suggérées** pour plus tard (nom, cases, ce qui change).
- Les couleurs de chaque collection dans `tokens.json`.

## Format de livraison

Comme les fois précédentes, dans le dossier `design/` : sprites dans `svg/sprites/`, icônes dans `svg/icones/encre/` et `svg/icones/blanc/`, mesures et tableaux dans `README.md` et `tokens.json`, et une planche de contrôle PNG par catégorie (`apercu_cuisine.png`, `apercu_chambre.png`…). Noms de fichiers en français, en minuscules, sans accents, avec des tirets bas.
