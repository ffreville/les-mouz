# Brief n° 6 pour Claude Design : « Les Mouz » passe en vue trois quarts

Même direction artistique « Maison de poche » (maquettes : https://claude.ai/artifact/UXdkDt3fTCFtjiGrQ62zEE, référence complète dans `design/README.md`) : palette, aplats, contour encre 2 px `#3D3357` (détails 1,5 px), pas de dégradé, ombre découpée, Baloo 2 + Nunito, jamais la couleur seule. L'interface (HUD, menus, catalogue, icônes) ne change pas.

Ce qui change, c'est la **caméra**. On quitte la vue strictement de dessus pour une **vue trois quarts**, comme les Zelda en 2D sur Super Nintendo : la grille du sol reste carrée, mais on voit à la fois le dessus des choses et leur face tournée vers le bas de l'écran, avec leur hauteur. Ce n'est **pas** de l'isométrique : pas de losanges, les lignes du sol restent horizontales et verticales.

## Travailler en plusieurs lots

C'est un gros chantier (chaque objet doit exister en 4 vues), donc on le fait **en plusieurs lots**, un message à la fois, pour ne pas tout produire d'un coup. Je t'enverrai « Fais le lot 1 du brief n° 6 », puis j'intègre et je vérifie dans le jeu avant de demander le suivant. Chaque lot doit être livrable seul : dans `design/`, avec la mise à jour du README, de `tokens.json` et une planche de contrôle PNG pour ce lot.

| Lot | Contenu |
|---|---|
| 1 | Les règles de la vue, les sols, les murs, les portes et fenêtres, 7 objets témoins et un personnage provisoire : de quoi valider la vue dans une vraie pièce |
| 2 | Les humains et l'écran de création de famille (brief n° 5, à dessiner directement en vue trois quarts) |
| 3 | Objets de la cuisine (10) |
| 4 | Objets de la chambre (8) et de la salle de bain (7) |
| 5 | Objets du salon (9) et de la déco (4) |
| 6 | Objets des loisirs (6) et du jardin (6) |
| 7 | Poses des personnages (assis, allongé, au sol) et finitions |

Si un lot est trop gros pour un seul message, coupe-le en deux et dis-moi où tu t'es arrêté : je te relancerai sur la suite.

## Les règles de la vue (valables pour tous les lots)

### Grille et hauteur

- Le sol reste une grille de **cases de 32 × 32 px**, vue d'en haut, sans déformation. Le terrain fait toujours 30 × 20 cases.
- Tout ce qui a de la hauteur **monte vers le haut de l'écran** à partir de son emprise au sol : on voit sa face avant (tournée vers le bas de l'écran) et son dessus.
- Repère de hauteur : **1 m ≈ 32 px**. Propose les hauteurs exactes ; à titre indicatif :

| Élément | Hauteur à l'écran |
|---|---|
| Tapis, tapis de yoga | 0 (à plat) |
| Lit, table basse, baignoire | 16 à 20 px |
| Table, bureau, plan de travail | 24 à 28 px |
| Canapé, fauteuil (dossier) | 28 à 32 px |
| Frigo, armoire, bibliothèque | 56 à 64 px |
| Mur plein | 64 px |
| Mur baissé | 12 px |
| Adulte debout | environ 48 px |

### Taille et ancrage d'un sprite

- Un sprite fait la **largeur de son emprise** (cases × 32) et la **profondeur de son emprise plus sa hauteur**. Exemple : une armoire de 2 × 1 cases et 60 px de haut fait 64 × 92 px.
- **Ancrage : le bas du sprite est le bas de l'emprise au sol.** Dans `tokens.json`, donne pour chaque sprite sa taille et le décalage vertical entre le bas de l'image et le bas de l'emprise (0 en principe).
- L'**ombre au sol** (ombre découpée, sans flou) est dessinée dans le sprite, sur l'emprise, du côté droit et en bas.

### Les 4 vues d'un objet

On ne peut plus faire tourner une image : chaque objet est dessiné dans **4 vues**, nommées selon le côté vers lequel regarde sa **face avant** (le côté où le Mouz se place pour s'en servir) :

| Vue | Face avant tournée vers | Ce qu'on voit |
|---|---|---|
| `bas` | le bas de l'écran | sa face avant (c'est la vue du catalogue) |
| `haut` | le haut de l'écran | son dos |
| `gauche` | la gauche | son profil |
| `droite` | la droite | son autre profil |

- Une emprise de 2 × 1 en vue `bas` ou `haut` devient 1 × 2 en vue `gauche` ou `droite`.
- Si un objet est symétrique, la vue `droite` peut être la vue `gauche` retournée. Dans ce cas, ne livre pas de fichier `droite` et indique `"miroir": true` dans `tokens.json`.
- Nommage : `<clé>_<collection>_<vue>.svg`, et `<clé>_<collection>_<vue>_actif.svg` pour l'état « en marche ». Exemple : `canape_retro_gauche.svg`.
- Les objets à plusieurs (table, table de jeux, salon de jardin) gardent la place de chacun visible dans les 4 vues.

### Ordre d'affichage

Le jeu dessine les objets, les murs et les personnages **du haut vers le bas de l'écran**, selon le bas de leur emprise : ce qui est plus bas passe devant. Les tapis restent toujours dessous. Dessine donc chaque élément comme un volume complet, sans compter sur ce qui sera devant ou derrière.

### Les murs

- Un mur posé sur une ligne horizontale montre son **dessus** (8 px de profondeur, comme aujourd'hui) et sa **face** (64 px de haut). Un mur posé sur une ligne verticale ne montre que son dessus, en bande de 8 px de large qui monte de 64 px, et sa tranche en bas.
- Il faut deux états, pour chacun des 4 styles (prune, brique, sauge, ardoise) :
  - **mur plein** ;
  - **mur baissé** (12 px), utilisé en mode Construire et pour voir l'intérieur des pièces.
- Prévois les raccords : angles, croisements en T et en croix, bout de mur.
- La face d'un mur peut porter la couleur du style à l'intérieur et une teinte neutre à l'extérieur : propose ce qui te paraît le plus lisible.

### Portes et fenêtres

- Chaque ouverture dans un **mur horizontal** (face visible) et dans un **mur vertical** (dessus seul), pleine hauteur et baissée.
- Porte : ouverte ou fermée, comme tu le juges le plus lisible.
- Fenêtre : on voit le vitrage dans la face du mur.

## Lot 1 : valider la vue

- Les règles ci-dessus, détaillées dans le README avec les mesures exactes.
- **Sols** : les 9 sols existants restent valables. Ajuste-les seulement si la nouvelle vue le demande (par exemple un peu plus de contraste sous les meubles).
- **Murs** : les 4 styles, plein et baissé, avec leurs raccords.
- **Portes et fenêtres** : les 4 ouvertures (`porte_bois`, `porte_blanche`, `fenetre`, `fenetre_large`) dans les deux sens de mur.
- **7 objets témoins**, en collection **nature**, dans leurs 4 vues : `canape`, `tele` (avec son état allumé), `lit`, `frigo`, `table`, `chaise`, `plante`.
- **Un personnage provisoire** (un adulte simple) dans 4 directions, debout et avec 2 images de marche, pour juger des proportions. Les vrais personnages viennent au lot 2.
- Une **planche** : un salon et une chambre meublés avec ces objets, murs pleins, puis la même scène murs baissés, avec le personnage à plusieurs endroits (devant un meuble, derrière, au ras d'un mur).

## Lot 2 : les humains et la création de famille

Fais le brief n° 5 (`docs/brief-claude-design-5.md`), en appliquant les règles de la vue trois quarts aux personnages :

- chaque calque (corps, tête, coiffure, contour) en **4 directions** (`bas`, `haut`, `gauche`, `droite` ; `droite` peut être le miroir de `gauche`) ;
- debout, plus 2 images de marche par direction ;
- proportions validées au lot 1.

## Lots 3 à 6 : les objets

Pour chaque objet de la catégorie (liste et emprises dans `design/README.md`, brief n° 4) :

- les **4 vues** dans **chacune des collections** où il existe déjà (nature, rétro, moderne), avec l'état « en marche » pour les objets qui en ont un ;
- les objets « au sol, traversables » (`tapis`, `tapis_yoga`) sont plats : une seule vue suffit si le motif le permet ;
- une planche de contrôle par lot (`apercu_cuisine.png`…), avec les 4 vues côte à côte.

Les objets témoins du lot 1 sont à compléter dans les collections rétro et moderne avec leur catégorie.

## Lot 7 : poses et finitions

- Poses des personnages pour les actions, dans les directions utiles : **assis** (chaise, canapé, fauteuil, toilettes), **allongé** (lit, hamac, baignoire), **au sol** (yoga, jardinage). Indique où se place le personnage par rapport à l'objet (décalage en pixels) dans `tokens.json`.
- Les vignettes du catalogue passent à la vue `bas`.
- Une planche finale : une maison complète dans chaque collection, avec une famille de 4.

## Format de livraison

Comme les fois précédentes, dans le dossier `design/` : sprites dans `svg/sprites/` (les sprites vus de dessus actuels restent en place jusqu'à ce que leur remplaçant soit livré), murs et ouvertures dans `svg/murs/` et `svg/ouvertures/`, personnages dans `svg/personnages/`, mesures dans `README.md` et `tokens.json`, une planche PNG par lot. Noms de fichiers en français, en minuscules, sans accents, avec des tirets bas.
