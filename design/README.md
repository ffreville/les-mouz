# Les Mouz — Direction artistique « Maison de poche »

Maquettes complètes (écran de jeu, composants, sprites, icônes) :
https://claude.ai/artifact/UXdkDt3fTCFtjiGrQ62zEE

Ce dossier contient tout ce qu'il faut pour reproduire le design dans Godot 4.

```
design/
├── README.md                  ce fichier : toutes les mesures
├── tokens.json                couleurs, rayons, espacements, seuils (source de vérité)
├── palette.gd                 les mêmes valeurs en GDScript (autoload « Palette »)
├── apercu_sprites_icones.png  planche de contrôle (premier lot)
├── apercu_construction.png    planche de contrôle (construction et achat)
└── svg/
    ├── sprites/               objets, portes, fenêtres et Mouz vus de dessus, à la taille de la grille
    ├── sols/                  tuiles de sol 32 × 32 raccordables
    └── icones/
        ├── encre/             icônes 24 × 24 couleur #2B2440
        └── blanc/             mêmes icônes en blanc, à teinter avec `modulate`
```

## L'idée

Une maison vue du plafond, comme une maquette en papier découpé : aplats doux, contour encre, ombres décalées sans flou. Les Mouz sont de petites boules à oreilles avec une pousse sur le dos. Ce sont les seuls êtres vivants de l'écran et ils en portent les couleurs les plus vives.

Quatre règles :

1. **Aplats et contour encre.** Chaque objet posé a un contour de 2 px `#3D3357` (détails à 1,5 px). Pas de dégradé. Les sols n'ont jamais de contour.
2. **Ombre découpée.** Les panneaux d'interface ont une ombre décalée de 4 px vers le bas, sans flou, `#2B2440` à 12 %.
3. **Les Mouz d'abord.** Les couleurs saturées sont réservées aux Mouz et aux besoins ; sols et meubles restent doux.
4. **Jamais la couleur seule.** Chaque besoin a son icône et son nom. En état bas ou critique, une étiquette écrite (et des hachures en critique) s'ajoute à la couleur.

## Palette

### Interface

| Rôle | Hex | Usage |
|---|---|---|
| Encre | `#2B2440` | texte principal |
| Encre douce | `#5E5675` | texte secondaire, titres de section |
| Contour | `#3D3357` | contour des objets, bouton actif, case cochée |
| Papier | `#FFF8EE` | fond des panneaux |
| Papier 2 | `#F6EBDD` | fonds en retrait, élément de file en attente, groupe de vitesse |
| Trait | `#E3D5C0` | bordure des panneaux |
| Piste | `#EFE4D4` | fond des barres |
| Accent | `#E8794A` | sélection, action en cours, relation |
| Accent texte | `#A8461F` | texte accentué sur papier (contraste 5,6:1) |
| Accent doux | `#FDE7DB` | survol de menu, étiquette « bas » |
| Critique | `#B3261E` | état critique (texte blanc dessus) |
| Critique doux | `#F9D9D6` | piste d'une barre critique |

### Sols et murs

| Pièce | Couleurs | Motif |
|---|---|---|
| Salon (parquet) | `#E8CBA4`, lames `#DDBA8F` | ligne de 1 px toutes les 16 px |
| Cuisine (carrelage) | `#D3E7DD` / `#C6DFD2` | damier de 32 px |
| Chambre (moquette) | `#DCCFEB`, points `#CDBDE2` | point de 1,5 px tous les 16 px |
| Salle de bain | `#D2E6F3`, joints `#BCD6E8` | quadrillage de 16 px |
| Jardin | `#A7C796`, points `#98BC86` | point de 2 px tous les 24 px |
| Mur | `#5B4E72` | 8 px |
| Seuil de porte | `#C9A27E` | dans l'ouverture du mur |

### Besoins

Palette inspirée d'Okabe-Ito, lisible par les daltoniens. La couleur remplit la barre, le fond teinte la case de l'icône.

| Besoin | Couleur | Fond d'icône |
|---|---|---|
| Faim | `#D55E00` | `#FBE3D3` |
| Énergie | `#E8B100` | `#FBF0C7` |
| Hygiène | `#3E9BD6` | `#DCEDF8` |
| Social | `#C46BA0` | `#F4DFEC` |
| Plaisir | `#0E9C74` | `#D3EFE5` |
| Humeur | `#6C5BB3` | `#E6E1F5` |

Seuils : **normal** à partir de 40, **bas** de 20 à 39, **critique** sous 20.
Humeur affichée en mots : Grognon (< 30), Bof (30–49), Content (50–69), Radieux (≥ 70).

### Mouz

| Élément | Hex |
|---|---|
| Pépin (corps) | `#F2A56B` |
| Myrtille (corps) | `#A3B5EC` |
| Intérieur d'oreille | `#F6B8C4` |
| Truffe | `#D9667E` |
| Pousse | `#7DB36A`, trait `#4F8A43` |

## Typographie

Deux polices Google Fonts (licence OFL), à télécharger dans `res://assets/fonts/` :
[Baloo 2](https://fonts.google.com/specimen/Baloo+2) et [Nunito](https://fonts.google.com/specimen/Nunito).

| Usage | Police | Taille / graisse |
|---|---|---|
| Logo | Baloo 2 | 24 / 800 |
| Nom du Mouz | Baloo 2 | 22 / 700 |
| Horloge | Baloo 2 | 22 / 700, chiffres tabulaires |
| Titre de section | Nunito | 12 / 800, majuscules, espacement +0,08 em |
| Libellé, nom d'action | Nunito | 14 / 700 (800 dans la file) |
| Action du menu contextuel | Nunito | 15 / 700 |
| Valeur d'un besoin | Nunito | 13 / 800, chiffres tabulaires |
| Texte secondaire | Nunito | 12 / 600 |

Dans Godot : crée un `Theme` avec Nunito par défaut, et des `LabelSettings` pour les styles Baloo 2.

## Grille et maison

- Case : **32 × 32 px**. La maison fait **20 × 16 cases** (640 × 512 px de sol).
- Murs : **8 px**. Les murs extérieurs sont à l'extérieur du sol ; les cloisons sont centrées sur la limite entre deux cases.
- Portes : ouvertures d'une case, avec un seuil `#C9A27E`.

| Pièce | Cases (x, y, largeur, hauteur) |
|---|---|
| Salon | 0, 0, 12, 9 |
| Cuisine | 12, 0, 8, 9 |
| Chambre | 0, 9, 12, 7 |
| Salle de bain | 12, 9, 8, 7 |

Portes : salon ↔ cuisine en case (12, 4) sur la cloison verticale ; salon ↔ chambre en case (5, 9) ; cuisine ↔ salle de bain en case (15, 9) ; entrée sur le mur gauche du salon, case (0, 6). Pas de porte entre chambre et salle de bain.

| Objet | Fichier | Taille (cases) | Position (case) | Action |
|---|---|---|---|---|
| Frigo | `frigo.svg` | 1 × 1 | 19, 0 | Manger |
| Lit | `lit.svg` | 2 × 3 | 1, 9 | Dormir |
| Douche | `douche.svg` | 2 × 2 | 18, 9 | Se laver |
| Canapé | `canape.svg` | 3 × 2 | 4, 4 | Regarder la TV |
| Meuble TV | `tv.svg` | 3 × 1 | 4, 0 | (cible du canapé) |
| Bibliothèque | `bibliotheque.svg` | 3 × 1 | 8, 0 | Lire |
| Tapis (déco) | `tapis.svg` | 6 × 4 | 2, 2 | — |
| Plante (déco) | `plante.svg` | 1 × 1 | 0, 0 | — |
| Plan de travail (déco) | `plan_travail.svg` | 3 × 1 | 16, 0 | — |
| Table (déco) | `table.svg` | 2 × 2 | 15, 4 | — |
| Table de nuit (déco) | `table_nuit.svg` | 1 × 1 | 3, 9 | — |
| Lavabo (déco) | `lavabo.svg` | 1 × 1 | 13, 9 | — |

Ordre d'affichage : sols → tapis → objets → murs → Mouz → bulles et étiquettes → menus.
Le canapé regarde vers le haut (vers la TV) ; les Mouz sont dessinés tournés vers le haut, fais-les pivoter selon leur direction.

## Écran de jeu (1280 × 720)

Le jardin remplit le fond. Tous les panneaux flottent à 12 px des bords.

| Zone | Position | Taille | Contenu |
|---|---|---|---|
| Barre du haut | 12, 12 | 1256 × 52 | logo à gauche, horloge au centre, vitesse + Autonomie à droite |
| Panneau du Mouz | 12, 76 | 272 × auto | portrait 64, nom, humeur, 5 besoins |
| Relation | sous le panneau, écart 12 | 272 × auto | les deux Mouz et la barre de relation |
| File d'actions | 996, 76 | 272 × auto | titre + compteur, éléments, aide |
| Maison | sol à 320, 128 | 640 × 512 | centrée entre les panneaux |

### Panneau (StyleBoxFlat)

- `bg_color` `#FFF8EE`, `border_width_*` 2, `border_color` `#E3D5C0`, `corner_radius_*` 16
- `shadow_color` `#2B24401F` (12 %), `shadow_size` 0, `shadow_offset` (0, 4)
- marges de contenu 16 px

## Composants

### Barre de besoin (240 × 28)

- Case d'icône 28 × 28, rayon 8, fond = teinte du besoin, icône 18 px couleur encre. Écart 10 px avec la colonne de droite.
- Ligne du haut : nom (Nunito 14/700) à gauche ; à droite étiquette éventuelle + valeur (13/800, tabulaire).
- Barre : hauteur 10, rayon 5, piste `#EFE4D4`, remplissage couleur du besoin, écart 4 px sous le texte.
- **Bas** : étiquette « bas » Nunito 11/800, padding 1 × 6, rayon 6, fond `#FDE7DB`, texte `#A8461F`.
- **Critique** : case d'icône cerclée 2 px `#B3261E`, piste `#F9D9D6`, remplissage hachuré (bandes blanches à 50 %, 135°, 5 px plein / 3 px blanc), étiquette « critique » avec icône alerte 12 px, fond `#B3261E`, texte blanc.
- Écart entre deux besoins : 12 px. La barre d'humeur utilise le même composant.

### Menu contextuel

- Largeur 196, padding 8, rayon 14, fond `#FFF8EE`, bordure 2 px `#E3D5C0`, ombre découpée.
- En-tête : vignette de l'objet (×0,75) + nom Nunito 13/800, séparateur 2 px `#F6EBDD`.
- Action : hauteur 40, rayon 10, padding horizontal 10, icône 20 + libellé Nunito 15/700. Survol : fond `#FDE7DB`.
- Pointe de 14 px tournée vers l'objet ; le menu s'ouvre à 12 px de l'objet. Fermeture : clic à côté ou Échap.

### Élément de la file d'actions (240 × 56)

- Rayon 12, padding 0 8 0 12, écart 10.
- **En attente** : fond `#F6EBDD`. **En cours** : fond blanc, bordure 2 px `#E8794A`, barre de progression 4 px (rayon 2, accent sur piste) à 12 px des côtés et 6 px du bas.
- Icône 32 × 32 rayon 8 (fond = teinte du besoin rempli), nom 14/800, détail 12/600 encre douce (« Frigo · en cours 62 % »).
- Bouton ✕ 28 × 28 rayon 8, icône 14 trait 2,5. Survol : fond `#F6EBDD` + bordure 2 px `#E3D5C0`. Écart entre éléments : 8 px.

### Vitesse et autonomie

- Groupe : fond `#F6EBDD`, padding 4, rayon 12, écart 4.
- Bouton 40 × 32, rayon 8, icône 18. Normal : transparent, icône encre. **Actif** : fond `#3D3357`, icône `#FFF8EE`. **Survol** : fond blanc, bordure 2 px accent.
- Séparateur vertical 2 × 28 `#E3D5C0`, puis case « Autonomie » : 20 × 20, rayon 6, bordure 2 px `#3D3357` ; cochée : fond `#3D3357`, coche 14 px `#FFF8EE`. Libellé Nunito 14/700.

### Relation

- Deux portraits 32 + noms (13/700), cœur 18 px accent au centre.
- Barre 240 × 10 de −100 à +100, repère central 2 × 16 px `#3D3357`, remplissage accent depuis le centre.
- Sous la barre : « −100 » et « +100 » (11/700 encre douce), au centre « Copains · +35 » (13/800).
- Paliers : Ennemis (< −50), Froids (−50 à −11), Neutres (−10 à 10), Copains (11 à 50), Inséparables (> 50).

### Dans la maison

- **Sélection** : cercle de rayon 19 centré sur le Mouz, fond accent à 18 %, trait 3 px accent en pointillés 7 / 4.
- **Bulle d'action** : 32 × 32, fond blanc, bordure 2 px `#3D3357`, icône 16. Anneau de progression 3 px accent (rayon 15) quand l'action est en cours.
- **Étiquette de nom** : Nunito 11/800, fond `#3D3357`, texte `#FFF8EE`, rayon 8, sous le Mouz sélectionné.

## Icônes

Grille 24 × 24, trait 2 px, extrémités arrondies. Lisibles de 16 à 48 px.

- Besoins : `faim`, `energie`, `hygiene`, `social`, `plaisir`, `humeur`
- Actions : `manger`, `dormir`, `se_laver`, `regarder_tv`, `lire`, `discuter`
- Interface : `pause`, `vitesse_1`, `vitesse_2`, `vitesse_3`, `horloge`, `valider`, `fermer`, `relation`, `alerte`

Utilise `icones/blanc/` quand l'icône doit changer de couleur (bouton actif, étiquette critique) : `modulate` multiplie la couleur, donc seul le blanc se teinte correctement.

## Importer dans Godot

1. Copie `design/svg/` dans `res://assets/` (ou importe directement depuis `design/`).
2. Dans l'onglet Import, garde `svg/scale` à 1 pour les sprites (ils sont déjà à la taille de la grille). Mets 2 si tu zoomes la caméra ×2, pour garder des bords nets.
3. Ajoute `palette.gd` en autoload nommé `Palette`, puis utilise `Palette.ACCENT`, `Palette.besoin("faim").couleur` ou `Palette.etat_besoin(valeur)`.
4. Construis un `Theme` à partir des valeurs de ce fichier (panneau, boutons, barres) pour que toute l'interface suive automatiquement.

## Accessibilité

- Texte : contraste d'au moins 4,5:1 sur papier (encre 13,9:1, encre douce 6,5:1, accent texte 5,6:1).
- Les états des besoins se lisent sans couleur : étiquette écrite, hachures, bordure.
- Zones cliquables d'au moins 28 px dans les panneaux, 40 px pour les actions de menu.

---

# Construction et achat (brief n° 2)

Maquettes : mêmes liens que plus haut, colonne « Construction et achat » du canvas (terrain vide, mode Construire, mode Acheter, éléments, composants, icônes).

Rien ne change dans le style : aplats, contour 2 px `#3D3357`, ombre découpée, Baloo 2 + Nunito, jamais la couleur seule.

## Règles du jeu reprises dans le design

- Terrain : **30 × 20 cases** de 32 px, couvert d'herbe. Hors terrain : herbe plus sombre `#94B884` et haie `#6E9A5F`.
- Monnaie : le **Mz**, budget de départ **20 000 Mz**. Revendre le jour même rembourse 100 %, ensuite 75 %.
- Montants affichés avec une espace insécable : « 18 450 Mz » (voir `Palette.format_mz()`).
- Construire et Acheter mettent le temps en pause : la barre du haut remplace l'horloge par une pastille « En pause ».
- En mode Construire, la grille s'affiche : traits de 1 px `#2B2440` à 10 %, et le terrain est entouré d'un tiret 2 px `#3D3357` à 50 %.

## Murs

8 px d'épaisseur, posés sur les lignes de la grille (4 px de chaque côté). Aux angles, prolonge chaque segment de 4 px pour fermer le coin.

| Clé | Nom | Couleur | Prix par segment |
|---|---|---|---|
| `prune` | Prune (actuel) | `#5B4E72` | 60 Mz |
| `brique` | Brique | `#9C5B4A` | 80 Mz |
| `sauge` | Sauge | `#4F7363` | 70 Mz |
| `ardoise` | Ardoise | `#3F5470` | 70 Mz |

## Portes et fenêtres

| Fichier | Nom | Taille du sprite | Segments | Prix |
|---|---|---|---|---|
| `svg/sprites/porte_bois.svg` | Porte en bois | 32 × 40 px | 1 | 250 Mz |
| `svg/sprites/porte_blanche.svg` | Porte blanche | 32 × 40 px | 1 | 300 Mz |
| `svg/sprites/fenetre.svg` | Fenêtre | 32 × 8 px | 1 | 200 Mz |
| `svg/sprites/fenetre_large.svg` | Fenêtre large | 64 × 8 px | 2 | 350 Mz |

- **Porte** : le sprite fait 32 × 40. Les 8 px du haut remplacent le segment de mur (seuil `#C9A27E`) ; les 32 px du dessous montrent le battant ouvert (4,5 px d'épaisseur, charnière à gauche) et son quart de cercle de 32 px en tirets, avec un voile `#3D3357` à 8 %. La pièce est donc **sous** le mur.
  - Ancrage : coin haut-gauche du segment de mur, soit (x, y − 4) pour un mur horizontal posé sur la ligne y.
  - Pièce au-dessus du mur : rotation de 180°. Mur vertical : rotation de 90° ou 270°. Charnière à droite : retournement horizontal (`flip_h`). La version verticale est donc une simple rotation, pas de fichier séparé.
- **Fenêtre** : remplace le segment de mur à l'identique (32 × 8 ou 64 × 8) : cadre crème, vitrage `#9FD3F2`, meneaux `#3D3357`.

## Sols

Tuiles de 32 × 32 px dans `svg/sols/`, raccordables dans les deux sens. Dans Godot, utilise-les comme sources d'un `TileSet` (une tuile par fichier). La gomme remet de l'herbe.

| Fichier | Nom | Couleurs | Prix par case |
|---|---|---|---|
| `svg/sols/herbe.svg` | Herbe (terrain) | #A7C796 / #98BC86 | gratuit |
| `svg/sols/parquet.svg` | Parquet | #E8CBA4 / #DDBA8F | 15 Mz |
| `svg/sols/carrelage.svg` | Carrelage damier | #D3E7DD / #C6DFD2 | 20 Mz |
| `svg/sols/moquette.svg` | Moquette | #DCCFEB / #CDBDE2 | 12 Mz |
| `svg/sols/faience.svg` | Faïence | #D2E6F3 / #BCD6E8 | 18 Mz |
| `svg/sols/beton.svg` | Béton ciré | #CFCAC2 / #D7D3CC / #B5AFA5 | 10 Mz |
| `svg/sols/tomettes.svg` | Tomettes | #D0805F / #C6714F / joint #A9583F | 22 Mz |
| `svg/sols/parquet_fonce.svg` | Parquet foncé | #8E6A51 / #6E5240 / #9A7559 | 25 Mz |
| `svg/sols/lino.svg` | Lino à motif | #EFE6D2 / #9CC9B5 / #E8794A | 8 Mz |

## Nouveaux objets

Dessinés **face avant vers le haut** (côté où le Mouz se place) : le jeu les tourne par quarts de tour, ils restent lisibles. Attention, les sprites du premier lot ont leur face **vers le bas** (sauf le canapé) : prévois un décalage de 180° pour eux, ou utilise le champ `face` de `tokens.json`.

| Fichier | Nom | Cases | Prix | Catégorie |
|---|---|---|---|---|
| `svg/sprites/cuisiniere.svg` | Cuisinière | 1 × 1 | 650 Mz | Cuisine |
| `svg/sprites/evier.svg` | Évier | 2 × 1 | 400 Mz | Cuisine |
| `svg/sprites/chaise.svg` | Chaise | 1 × 1 | 80 Mz | Cuisine |
| `svg/sprites/lampe_pied.svg` | Lampe sur pied | 1 × 1 | 120 Mz | Salon |
| `svg/sprites/armoire.svg` | Armoire | 2 × 1 | 700 Mz | Chambre |
| `svg/sprites/baignoire.svg` | Baignoire | 3 × 2 | 1 200 Mz | Salle de bain |
| `svg/sprites/toilettes.svg` | Toilettes | 1 × 1 | 300 Mz | Salle de bain |
| `svg/sprites/bureau.svg` | Bureau | 2 × 1 | 450 Mz | Chambre |

Prix suggérés pour les objets existants : frigo 800 Mz, lit 1 000 Mz, douche 900 Mz, canapé 750 Mz, meuble tv 600 Mz, bibliothèque 350 Mz, plante 40 Mz, plan de travail 300 Mz, table 250 Mz, lavabo 250 Mz, table de nuit 90 Mz, tapis 150 Mz.

### Catalogue

- **Cuisine** (`cuisine`) : frigo, cuisiniere, evier, plan_travail, table, chaise
- **Chambre** (`chambre`) : lit, armoire, table_nuit, bureau
- **Salon** (`salon`) : canape, tv, bibliotheque, lampe_pied
- **Salle de bain** (`salle_de_bain`) : douche, baignoire, toilettes, lavabo
- **Déco** (`deco`) : plante, tapis
- **Sols** (`sols`) : parquet, carrelage, moquette, faience, beton, tomettes, parquet_fonce, lino
- **Murs** (`murs`) : prune, brique, sauge, ardoise
- **Ouvertures** (`ouvertures`) : porte_bois, porte_blanche, fenetre, fenetre_large

## Écrans (1280 × 720)

| Mode | Barre du haut | Gauche | Bas |
|---|---|---|---|
| Vivre | logo, onglets de mode, horloge + vitesse, solde | besoins + relation | — |
| Construire | logo, onglets, pastille « En pause », solde | panneau d'outils (272 de large) | aide du tracé à droite |
| Acheter | logo, onglets, pastille « En pause », solde | — | catalogue 1256 × 196 à 12 px des bords |

Dans les maquettes, le terrain est affiché à l'échelle 1 avec son coin haut-gauche en (300, 72) : il tient entre le panneau de gauche et le bord droit. En mode Acheter, le catalogue recouvre le bas du terrain : la caméra doit pouvoir défiler.

## Composants

### Barre du haut

Ordre : logo · onglets de mode · (horloge ou « En pause ») centré · solde. Écart 20 px.

- **Onglets de mode** : groupe fond `#F6EBDD`, padding 4, rayon 14, écart 4. Onglet : hauteur 36, padding 0 14, rayon 10, icône 18 + Nunito 14/800, écart 8. Normal transparent ; **actif** fond `#3D3357`, texte `#FFF8EE` ; **survol** fond blanc, bordure intérieure 2 px accent. Raccourcis suggérés F1 / F2 / F3.
- **En pause** : pastille hauteur 28, padding 0 10, rayon 8, fond `#3D3357`, texte `#FFF8EE` 13/800, icône pause 14 ; puis « Jour 3 · 14:35 » 14/700 encre douce.
- **Solde** : capsule hauteur 36, padding 0 14 0 10, rayon 12, fond `#F6EBDD`, pièce 20 px (`piece_mz.svg`), montant Baloo 2 20/700 tabulaire.
- **Variation du solde** : pastille sous la capsule, alignée à droite (8 px), padding 2 × 8, rayon 8, Nunito 13/800, ombre découpée. Baisse : fond `#F9D9D6`, texte `#B3261E` (« −1 200 Mz »). Hausse : fond `#D3EFE5`, texte `#0B6E52` (« +900 Mz »). Animation : apparaît, monte de 12 px et s'efface en 1,2 s ; le montant défile vers sa nouvelle valeur en 0,4 s.

### Panneau Construire (272 de large, à la place des besoins)

- Titre « Outils », puis grille de 4 colonnes, écart 4 : boutons 56 × 56, rayon 12, icône 22 + libellé Nunito 11/800, écart 3. Normal fond `#F6EBDD` ; **actif** fond `#3D3357`, texte `#FFF8EE` ; **survol** fond blanc + bordure 2 px accent.
- Outils : Mur, Démolir, Porte, Fenêtre, Sol, Gomme, Déplacer, Annuler (Tourner sert en mode Acheter, touche R).
- Séparateur 2 px `#F6EBDD`, puis les options de l'outil actif :
  - **Mur** : couleurs en 2 colonnes, bouton 113 de large, padding 8, rayon 10, pastille 22 × 22 rayon 6, nom 12/800, prix 11/700. Choisi : bordure 2 px accent + fond `#FDE7DB`.
  - **Sol** : revêtements en 3 colonnes de 72 px, aperçu 60 × 60 rayon 6, nom et prix 11 px.
  - Phrase d'aide 12/600 encre douce en bas.

### Catalogue Acheter

- Panneau 1256 × 196 en bas, padding 14 16 16, écart 12.
- Onglets de catégorie : hauteur 34, padding 0 12, rayon 10, icône 16 + Nunito 13/800, écart 6. Normal fond `#F6EBDD`, actif `#3D3357`, survol bordure accent. À droite : « R pour tourner » 12/700.
- Vignettes : 120 de large, padding 8, rayon 12, écart 12 ; image 104 × 72 sur `#F6EBDD` rayon 8 ; nom 13/800 ; pièce 14 + prix 13/800.
  - **Survol** : bordure 2 px accent. **Choisi** : bordure 3 px accent + fond `#FDE7DB`.
  - **Trop cher** : image grisée à 40 %, prix `#B3261E`, mention « Trop cher » 11/700, clic refusé (`aria-disabled`).

### Aperçu de placement

- **Objet fantôme** : sprite à 60 % d'opacité + cadre de 2 px autour de son emprise (2 px de débord, rayon 6). Valide : trait plein accent, fond accent à 16 %. Invalide : tirets `#B3261E`, fond `#B3261E` à 18 %, pastille ✕ de 22 px en haut à droite.
- **Mur en cours de tracé** : couleur du mur à 45 %, contour 2 px accent en tirets décalé de 1 px ; poignées rondes de 14 px (bordure 3 px accent, fond blanc) aux deux extrémités.
- **Étiquette de coût** : à 14 px en bas à droite du pointeur. Fond blanc, bordure 2 px `#3D3357`, rayon 10, padding 5 × 10, ombre découpée ; pièce 14 + « 4 murs · 240 Mz » Nunito 13/800. Argent insuffisant : bordure et texte `#B3261E`, ligne « Il manque 450 Mz » 11/800.

### Bulle de revente

Au clic sur un objet posé (mode Acheter). Mêmes règles que le menu contextuel, 220 de large : en-tête vignette ×0,6 + nom ; « Déplacer » (hauteur 40) ; « Revendre +900 Mz » sur fond `#FDE7DB`, montant en `#0B6E52`, précision 11/700 en dessous (« Remboursé en entier aujourd'hui » ou « 75 % du prix d'achat »).

### Raccourcis

R tourner · Échap annuler le tracé ou l'achat · Ctrl Z annuler la dernière action · Suppr revendre l'objet choisi.

## Nouvelles icônes

- Modes : `vivre`, `construire`, `acheter`
- Outils : `mur`, `demolir`, `porte`, `fenetre`, `sol`, `gomme`, `tourner`, `deplacer`, `vendre`, `annuler`
- Catégories : `cuisine`, `chambre`, `salon`, `salle_de_bain`, `deco`, `sols`, `murs`, `ouvertures`
- Argent : `mz` (icône au trait) et `svg/sprites/piece_mz.svg` (pièce en couleur pour le solde et les prix)

## Corrections

- `palette.gd` : l'épaisseur des murs s'appelle maintenant `EPAISSEUR_MUR` (la constante `MUR` reste la couleur). Ajouts : `MURS`, `SOLS`, `TERRAIN`, `BUDGET_DEPART`, `REVENTE_MEME_JOUR`, `REVENTE_ENSUITE` et `format_mz()`.
