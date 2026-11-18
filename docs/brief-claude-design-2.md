# Brief n° 2 pour Claude Design : « Les Mouz », mode Construction et Achat

Tu as déjà créé la direction artistique « Maison de poche » de **Les Mouz** (maquettes : https://claude.ai/artifact/UXdkDt3fTCFtjiGrQ62zEE). Elle est intégrée au jeu et fonctionne bien. Garde exactement le même style, la même palette, les mêmes polices (Baloo 2 + Nunito) et les mêmes règles : aplats, contour encre 2 px `#3D3357`, ombre découpée, jamais la couleur seule.

Le jeu va maintenant permettre au joueur de **construire sa maison lui-même** sur un terrain vide, avec un budget. Il me faut les visuels de ces nouveautés.

## Le fonctionnement

- Le joueur part d'un **terrain vide** de 30 × 20 cases (32 px par case), couvert d'herbe (le « jardin » actuel `#A7C796`).
- Il dispose d'un **budget** dans une monnaie inventée, le **Mz** (« 20 000 Mz »). Pas de revenus pour l'instant : on dépense en construisant et en achetant. Revendre le jour même rembourse tout ; ensuite on récupère 75 %.
- Trois **modes**, accessibles par des onglets dans la barre du haut :
  - **Vivre** : le jeu actuel (besoins, file d'actions…) ;
  - **Construire** (temps en pause) : tracer des murs en glissant le long des lignes de la grille, démolir, poser des portes et des fenêtres sur un mur existant, peindre le sol case par case (ou en rectangle), gommer le sol ;
  - **Acheter** (temps en pause) : choisir un objet dans un catalogue par catégorie, le voir suivre la souris en aperçu, le tourner (R), cliquer pour l'acheter et le poser ; cliquer sur un objet déjà posé pour le déplacer ou le revendre.
- Les murs font 8 px d'épaisseur et sont posés **sur les lignes de la grille**, entre deux cases. Une porte ou une fenêtre occupe un segment de mur d'une case (32 px).

## Ce que j'attends

### 1. Sprites vus de dessus (SVG, mêmes règles que les sprites existants)
- **Porte** : dans une ouverture de mur de 32 × 8 px, avec le battant ouvert dessiné en quart de cercle (32 px de rayon) côté pièce. Deux variantes : bois et blanche. Donne aussi la version verticale si elle n'est pas une simple rotation.
- **Fenêtre** : dans un segment de mur de 32 × 8 px, vitrage visible. Deux variantes : simple et large (64 px, sur deux segments).
- **Mur** : confirme le rendu actuel (aplat `#5B4E72`) et propose 2 ou 3 autres couleurs de mur au choix du joueur, avec leur prix suggéré.
- **Revêtements de sol** : 8 sols en **tuiles SVG de 32 × 32 px raccordables** (le motif doit se répéter sans couture) : les 4 actuels (parquet, carrelage damier, moquette, faïence) plus 4 nouveaux (par exemple béton ciré, tomettes, parquet foncé, lino à motif). Pour chacun : nom, couleurs, prix suggéré par case.
- **Nouveaux objets** pour remplir le catalogue, à la taille de la grille, dessinés tournés vers le haut (le jeu les fait pivoter par quarts de tour, donc ils doivent rester lisibles une fois tournés) : cuisinière, évier, chaise, lampe sur pied, armoire, baignoire, toilettes, bureau. Pour chacun : taille en cases et prix suggéré.

### 2. Icônes (grille 24 × 24, trait 2 px, versions `encre` et `blanc`, comme les existantes)
- **Modes** : vivre, construire, acheter.
- **Outils** : mur, démolir, porte, fenetre, sol, gomme, tourner, deplacer, vendre, annuler.
- **Catégories du catalogue** : cuisine, chambre, salon, salle_de_bain, deco, sols, murs, ouvertures.
- **Argent** : une pièce « Mz ».

### 3. Composants d'interface (avec toutes les mesures, comme dans ton premier README)
- **Onglets de mode** dans la barre du haut (Vivre / Construire / Acheter) : normal, actif, survol.
- **Affichage du solde** dans la barre du haut : pièce + montant (« 18 450 Mz »), plus un petit retour visuel quand l'argent baisse ou monte (« −1 200 » qui apparaît puis disparaît).
- **Barre d'outils du mode Construire** : la liste des outils, l'outil actif mis en avant.
- **Panneau catalogue** du mode Acheter (en bas de l'écran ou sur un côté, à toi de proposer) : onglets de catégories, grille de vignettes avec nom et prix ; états normal, survol, sélectionné, **trop cher** (grisé, prix en rouge).
- **Aperçu de placement** dans la maison : objet fantôme valide (contour accent) et invalide (contour rouge critique), étiquette de coût qui suit la souris pendant le tracé d'un mur ou la peinture d'un sol (« 4 murs · 240 Mz »), et coût en rouge s'il manque de l'argent.
- **Bulle de revente** au clic sur un objet posé : « Déplacer » / « Revendre +900 Mz ».

### 4. Maquettes 1280 × 720
- Le **mode Construire** sur un terrain en cours de construction (quelques murs, une porte, une fenêtre, un sol peint, un mur en train d'être tracé avec son coût).
- Le **mode Acheter** avec le catalogue ouvert et un objet fantôme en cours de placement.
- Le **terrain vide** au tout début d'une partie.

## Format de livraison

Mets à jour le dossier `design/` livré la première fois, en gardant la même organisation :

- `svg/sprites/` : portes, fenêtres, nouveaux objets ;
- `svg/sols/` : les tuiles de sol 32 × 32 ;
- `svg/icones/encre/` et `svg/icones/blanc/` : les nouvelles icônes ;
- `tokens.json` et `README.md` : complétés avec les nouvelles couleurs, mesures, composants et prix suggérés ;
- une planche de contrôle PNG des nouveautés.

Noms de fichiers en français, en minuscules, sans accents, avec des tirets bas (comme `table_nuit.svg`).

Petite correction au passage : dans `palette.gd`, la constante `MUR` est déclarée deux fois (une couleur et une épaisseur), ce qui empêche le script de compiler. Renomme l'épaisseur en `EPAISSEUR_MUR`.
