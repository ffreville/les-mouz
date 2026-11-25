# Brief n° 7 pour Claude Design : les étages et l'escalier

Même direction artistique « Maison de poche » (référence complète dans `design/README.md`) et mêmes règles de la **vue trois quarts** que le brief n° 6 (`docs/brief-claude-design-6.md`) : grille de cases de 32 × 32 px, ce qui a de la hauteur monte vers le haut de l'écran, ancrage en bas de l'emprise, contour encre 2 px `#3D3357` (détails 1,5 px), aplats sans dégradé, ombre découpée, 4 vues nommées selon le côté où regarde la face avant. Noms de fichiers en français, minuscules, sans accents, avec des tirets bas.

## Ce qui change dans le jeu

Les maisons peuvent maintenant avoir **deux étages au-dessus du rez-de-chaussée** (niveaux 0, 1 et 2). Comme dans les jeux de maison de poupée :

- on regarde **un étage à la fois**, choisi avec un petit sélecteur dans la barre du haut (ou les touches Page haut / Page bas) ;
- l'étage regardé est dessiné normalement ; **les étages du dessous restent visibles, assombris**, là où l'étage regardé n'a pas de sol (un trou, le jardin, la cage d'escalier) ; les étages du dessus sont cachés ;
- un étage est dessiné **au même endroit à l'écran** que le rez-de-chaussée (pas de décalage vers le haut) : on change de plan, comme on tourne la page d'une maquette ;
- un sol d'étage se pose au-dessus d'une pièce fermée de l'étage du dessous ; murs, portes, fenêtres, papiers peints et objets s'y posent comme au rez-de-chaussée ;
- un **escalier** relie un niveau au suivant : les Mouz le montent et le descendent tout seuls quand ils vont d'un étage à l'autre.

En attendant tes dessins, le jeu utilise des images provisoires (escalier gris, bord de dalle en aplat) : tout ce qui suit les remplace.

## Ce qu'il faut dessiner

### 1. L'escalier (objet du catalogue, catégorie Construction)

- **Escalier droit** : emprise **1 × 3 cases**, il monte d'un étage, soit **64 px** (la hauteur d'un mur plein). La marche du bas est sa **face avant** : c'est de là qu'on monte. 6 ou 8 marches, comme tu le juges le plus lisible.
- **4 vues** (`bas`, `haut`, `gauche`, `droite`) : en vue `bas`, la marche du bas est en bas de l'écran et l'escalier monte vers le haut de l'écran ; en vue `haut`, il monte vers le bas de l'écran (on voit surtout sa rampe et le dessous des marches) ; en vues `gauche` et `droite`, on le voit de profil (`droite` peut être le miroir de `gauche`).
- Une **rampe** du côté visible, et le dessous de l'escalier fermé (pas de vide à dessiner sous les marches).
- Dans les **3 collections** : `escalier_nature_<vue>.svg`, `escalier_retro_<vue>.svg`, `escalier_moderne_<vue>.svg`, plus une vignette du catalogue par collection (`design/svg/vignettes/escalier_<collection>.svg`, 104 × 72 comme les autres).
- Dans `tokens.json` : la taille de chaque sprite, et pour chaque vue la **ligne des marches** (de la première à la dernière, en pixels dans l'image) pour que le jeu fasse monter le Mouz le long des marches.

### 2. Le bord d'un étage

À l'étage, une case sans sol laisse voir l'étage du dessous. Il faut marquer le bord du plancher :

- **Tranche de dalle** : le bord d'un sol d'étage au-dessus du vide, vue de face (bord horizontal, 8 px d'épaisseur qui descend) et vue de dessus (bord vertical, bande de 8 px). Avec les raccords d'angle (rentrant, sortant). Une seule teinte neutre qui aille avec les 11 sols.
- **Ombre portée** sur l'étage du dessous, sous le bord de la dalle (ombre découpée, sans flou, `#2B2440` à 12 %), si ça aide à lire la profondeur.
- **Garde-corps** (facultatif, à ton jugement) : une balustrade basse posée automatiquement autour de la cage d'escalier et au bord des trous. Si tu le proposes : segments horizontal et vertical, poteaux, raccords, dans les 3 collections ou en une seule version neutre.
- **Le vide en mode Construire** : comment montrer, à l'étage, les cases où l'on ne peut pas encore poser de sol (hachures légères ? teinte ?) et celles où l'on peut (au-dessus d'une pièce fermée).

### 3. Les Mouz dans l'escalier

- **Monter et descendre** : 2 images de marche par direction utile (on monte vers le `haut` de l'écran en vue `bas`, vers la `gauche` ou la `droite` de profil, et on descend vers le `bas`), pour chaque âge (enfant, ado, adulte, aîné) et chaque sexe, avec les mêmes calques que le lot 2 (corps, tête, cheveux, tenue à teinter).
- Si une pose « marche haute » suffit en décalant les images existantes, dis-le : on fera avec moins de dessins.

### 4. L'interface

- Un **sélecteur d'étage** pour la barre du haut, à côté des onglets Vivre / Construire / Acheter : le nom de l'étage regardé (« Rez-de-chaussée », « 1er étage », « 2e étage ») et deux boutons monter / descendre, avec les états actif, survol et désactivé (on ne descend pas sous le rez-de-chaussée, on ne monte pas au-dessus du 2e étage). Propose aussi une version compacte.
- **Icônes** 24 × 24 en encre et en blanc : `etage_monter`, `etage_descendre`, `escalier` (catalogue et menus).
- La **teinte des étages du dessous** quand on regarde un étage (proposition chiffrée : couleur et opacité du voile).
- Le **petit repère d'étage** des portraits de Mouz (en haut à gauche de l'écran) quand un Mouz n'est pas à l'étage regardé : un badge « 1er », « RDC »…

### 5. La planche de contrôle

`design/apercu_etages.png` : une maison de deux niveaux (salon et cuisine en bas, deux chambres et une salle de bain en haut, escalier dans l'entrée), vue au rez-de-chaussée puis au 1er étage, avec un Mouz dans l'escalier et le sélecteur d'étage dans la barre du haut. Une version en mode Construire à l'étage, avec les cases où l'on peut poser un sol.

## Hors sujet pour ce brief

Les toits, les escaliers en colimaçon ou en L et les sous-sols viendront plus tard s'il le faut : ne les dessine pas.

## Format de livraison

Comme d'habitude, dans `design/` : sprites dans `svg/sprites/`, vignettes dans `svg/vignettes/`, bords de dalle et garde-corps dans `svg/murs/`, personnages dans `svg/personnages/`, icônes dans `svg/icones/`, mesures et noms dans `README.md` et `tokens.json`, et la planche PNG. Si tout ne tient pas en un message, coupe en deux lots (par exemple 1 + 2 + 4, puis 3) et dis-moi où tu t'es arrêté.
