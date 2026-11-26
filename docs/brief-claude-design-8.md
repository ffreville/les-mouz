# Brief n° 8 pour Claude Design : les toits, la piscine et le jardin

Même direction artistique « Maison de poche » (`design/README.md`) et mêmes règles de la **vue trois quarts** que les briefs n° 6 et 7 : cases de 32 × 32 px, ce qui a de la hauteur monte vers le haut de l'écran (1 m ≈ 32 px), ancrage en bas de l'emprise, contour encre 2 px `#3D3357` (détails 1,5 px), aplats sans dégradé, ombre découpée, 4 vues nommées selon le côté où regarde la face avant. Noms de fichiers en français, minuscules, sans accents, avec des tirets bas. Livraison dans `design/` comme d'habitude (sprites, sols, murs, personnages, icônes, `README.md`, `tokens.json`, planche PNG).

En attendant tes dessins, le jeu dessine tout cela en aplats provisoires : ce brief les remplace.

## 1. Les toits

### Ce que fait le jeu

- Le toit est **automatique** : le jeu le pose sur chaque pièce fermée qui n'a rien au-dessus (pas de plancher à l'étage). Sur une maison à étage, le toit du rez-de-chaussée couvre la partie qui dépasse, et celui de l'étage couvre l'étage.
- C'est un **toit à quatre pans** (en croupe) : chaque case de la pièce prend la hauteur de sa distance au bord le plus proche, comme une pyramide qui s'allonge en faîtage sur les pièces rectangulaires. Sur une maison en L, deux toits se rejoignent dans une noue.
- **Pente 45°** : chaque case vers l'intérieur monte de 32 px. Le bas du toit est posé sur le haut des murs pleins (64 px), avec un **débord de 8 px** tout autour.
- On le voit en mode Vivre avec un nouveau réglage de murs, **« Toits »** (touche V : toits → murs pleins → murs coupés → murs baissés), et sur le plan du quartier. Il disparaît en Construire et en Acheter.
- Le joueur choisit un **style de toit pour toute la maison** dans l'outil « Toit » du mode Construire.

### À dessiner

- **4 styles** : tuiles rouges (Nature), ardoise (Rétro), zinc à joints debout (Moderne), chaume (pour la Bicoque et le Potager). Un aplat principal, une teinte claire et une teinte sombre par style (les pans au soleil et à l'ombre ; lumière en haut à gauche, comme les ombres).
- **Pièces de toit, à la case** (32 × 32 au sol, à étirer à l'écran selon la hauteur) : pan sud (celui qu'on voit le plus, en face), pan nord (vu du dessus, écrasé), pans est et ouest, arêtier (rencontre de deux pans en angle sortant), noue (angle rentrant), faîtage (ligne du haut), égout avec gouttière (le bas du pan, débord de 8 px), et la jonction avec un mur d'étage qui dépasse du toit.
- Si un toit par pièces est trop rigide, propose plutôt des **motifs à répéter** (tuiles, ardoises, joints, chaume) que le jeu applique sur les pans qu'il calcule, plus les filets (faîtage, arêtier, noue, égout) : dis-moi ce qui rend le mieux.
- Une **cheminée** facultative qui sort du toit au-dessus de l'objet cheminée (1 × 1, 3 collections).
- **Icônes** 24 × 24 encre et blanc : `toit` (outil et réglage « Toits »).
- Les **vignettes des styles de toit** pour le panneau de l'outil (comme les cartes de murs : échantillon, nom, prix).

## 2. La piscine

### Ce que fait le jeu

- Outil **« Piscine »** du mode Construire : on glisse un rectangle dans le jardin (au rez-de-chaussée, hors des pièces), et il devient un bassin d'eau entouré d'une margelle. Les cases d'eau ne se traversent pas à pied.
- Deux objets à poser sur le bord : l'**échelle** (« Nager ») et le **plongeoir** (« Plonger »). Les Mouz descendent par l'échelle, nagent en faisant des longueurs, et ressortent par l'échelle. Nager fait monter la Forme, le Plaisir et l'Hygiène, et fatigue.

### À dessiner

- **Eau** : tuile 32 × 32 raccordable, avec **3 images** d'animation (reflets qui bougent), et la variante « bord » sur la ligne de flottaison sous la margelle (on voit la paroi du bassin descendre sous l'eau du côté nord).
- **Margelle** : bords (nord, sud, est, ouest), angles sortants et rentrants, posés comme les bords de dalle du brief n° 7. La paroi nord se voit en face, sur 16 px de profondeur d'eau.
- **Échelle** (1 × 1, sur le bord, face avant tournée vers l'eau, 4 vues) et **plongeoir** (1 × 2, planche qui avance au-dessus de l'eau, 4 vues), en Nature, Rétro et Moderne.
- **Transat** (2 × 1, 4 vues, 3 collections) : « Bronzer » au bord de la piscine.
- **Mouz qui nagent** : la tête et les épaules hors de l'eau, dans les 4 directions, 2 images de brasse, pour chaque âge et chaque sexe, en calques comme au lot 2 (le bas du corps n'est pas dessiné). Une image **plongeon** (en l'air, bras tendus) et une **éclaboussure** (2 images, à poser sur l'eau).
- **Mouz sur le transat** : allongé, comme les poses du lot 7 (`data/vue34/places.json` : donne les places du transat).
- **Icônes** : `piscine` (outil), `nager`, `plonger`, `bronzer`.

## 3. La terrasse et les plantations

### Ce que fait le jeu

- **Terrasse** : un nouveau sol d'extérieur en lames de bois.
- **Plantations** : le potager et un nouveau **massif de fleurs** poussent d'eux-mêmes en quelques jours s'ils sont arrosés : graines → pousses → mûr. Mûr, le potager se récolte (et se vend mieux) ; le massif de fleurs embellit le jardin (Plaisir en le regardant). Sans eau pendant deux jours, la plantation **fane** ; on la sauve en l'arrosant.

### À dessiner

- **Terrasse** : tuile 32 × 32 de lames de bois (sens est-ouest), raccordable, sans contour ; et une variante plus foncée pour la bordure si elle aide.
- **Potager** (2 × 2, existe déjà en 3 collections, en vue trois quarts) : les **4 états** des plantations, en calque posé sur le bac existant : `graines` (terre retournée, petites marques), `pousses` (jeunes plants), `mur` (légumes visibles : tomates, salades, carottes), `fane` (plants jaunis, couchés).
- **Massif de fleurs** (2 × 1, 4 vues, 3 collections : bordure en bois, en brique, en béton) avec ses 4 états (`graines`, `pousses`, `fleuri`, `fane`).
- Une petite **jauge d'eau** au-dessus d'une plantation qui a soif (une goutte vide ou pleine), dans le style des bulles d'action.
- **Icônes** : `terrasse` (catalogue des sols), `fleurs` (objet), et l'état « a soif ».

## 4. La planche de contrôle

`design/apercu_toits_piscine.png` : une maison à étage (Les Glycines) vue de la rue avec son toit en tuiles, son jardin avec une terrasse, une piscine (un Mouz qui nage, un autre sur le plongeoir, un troisième sur le transat), un potager mûr et un massif de fleurs ; puis la même maison en « Murs coupés » sans toit, pour vérifier que tout se raccorde ; et les 4 styles de toit côte à côte sur une maison en L.

## Hors sujet pour ce brief

Les toits plats avec terrasse, les lucarnes, les vérandas, les jacuzzis et les arbres fruitiers viendront plus tard s'il le faut : ne les dessine pas.

Si tout ne tient pas en un message, coupe en lots (par exemple 1, puis 2, puis 3 et 4) et dis-moi où tu t'es arrêté.
