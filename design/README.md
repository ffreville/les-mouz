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

---

# Catalogue de 50 objets en trois collections (brief n° 4)

Maquettes : même lien que plus haut, colonne « Catalogue en trois collections » du canvas (collections, mode Acheter Salon Rétro, trois maisons meublées, choisir un style, icônes, une planche par catégorie).

## Les trois collections

Une collection change les couleurs, les matières et l'arrondi des coins. Elle ne change jamais la taille en cases, la face avant, l'interaction ni le contour encre 2 px `#3D3357`.

| | Nature (`nature`) | Rétro (`retro`) | Moderne (`moderne`) |
|---|---|---|---|
| Idée | Bois clair, sauge et lin, formes douces | Teck, moutarde, brique, orange ; formes très arrondies | Blanc, ardoise, métal ; lignes nettes |
| Rayon des coins | ×1 | ×1,7 | ×0,35 |
| Signature | veinage du bois, touche végétale | pieds compas visibles aux coins | filets métal sur les façades |
| Couleur signature (pastille) | `#8DB596` | `#E2A93B` | `#4A5568` |
| Bois | `#D9B48F` | `#A9653E` | `#E4E6EA` |
| Bois foncé, pieds | `#B88E6B` | `#844A2B` | `#4A5568` |
| Veinage, filets | `#C49D78` | `#94552F` | `#C9CDD4` |
| Tissu | `#8DB596` | `#E2A93B` | `#5C6B80` |
| Tissu foncé | `#6F9C7B` | `#C68B1F` | `#4A5568` |
| Coussins | `#B5D1B9` | `#E8794A` | `#8796AB` |
| Lin, crème, draps | `#EDE3D3` | `#F3E3C3` | `#F5F5F2` |
| Électroménager | `#F7F3EC` | `#F3E3C3` | `#F5F5F2` |
| Ombre électroménager | `#DCD5C8` | `#E0C89E` | `#D3D7DD` |
| Plan de travail | `#EDE3D3` | `#F3E3C3` | `#4A5568` |
| Accent | `#7DB36A` | `#B85C45` | `#3E9BD6` |
| Accent 2 | `#E8B100` | `#4F9C95` | `#E8794A` |
| Métal | `#8E99A6` | `#C9A66B` | `#A9B1BC` |
| Pierre (cheminée) | `#C9C4BC` | `#B85C45` | `#E4E6EA` |
| Pots | `#C97B5A` | `#B85C45` | `#F5F5F2` |

Ces couleurs sont dans `tokens.json` → `collections`. Les draps restent blancs, l'eau `#D2E8F5`, les écrans `#2B2440` (éteints) ou `#9FD3F2` (allumés), et le feu `#D55E00` / `#E8794A` / `#E8B100` dans toutes les collections.

Pour coordonner la maison, les maquettes utilisent : Nature → murs sauge, parquet, carrelage, moquette, faïence ; Rétro → murs brique, parquet foncé, lino, tomettes ; Moderne → murs ardoise, béton ciré, faïence.

**Place pour les déclinaisons** : chaque sprite laisse une marge de 2 px et ne remplit pas toute sa surface de détails. Une version « simple » enlèvera des détails (coussins, objets posés), une version « luxe » en ajoutera (accent supplémentaire, matière plus riche) sans changer de langage.

## Les 20 sprites existants

Ils appartiennent à la collection **Nature**. Je les ai redessinés face avant vers le haut dans `<clé>_nature.svg`. Les anciens fichiers restent en place mais ne servent plus que de référence :

| Ancien fichier | Face | Nouveau fichier |
|---|---|---|
| `svg/sprites/frigo.svg` | bas | `svg/sprites/frigo_nature.svg` |
| `svg/sprites/cuisiniere.svg` | haut | `svg/sprites/cuisiniere_nature.svg` |
| `svg/sprites/evier.svg` | haut | `svg/sprites/evier_nature.svg` |
| `svg/sprites/plan_travail.svg` | bas | `svg/sprites/plan_travail_nature.svg` |
| `svg/sprites/table.svg` | indifférent | `svg/sprites/table_nature.svg` |
| `svg/sprites/chaise.svg` | haut | `svg/sprites/chaise_nature.svg` |
| `svg/sprites/lit.svg` | bas | `svg/sprites/lit_nature.svg` |
| `svg/sprites/armoire.svg` | haut | `svg/sprites/armoire_nature.svg` |
| `svg/sprites/table_nuit.svg` | indifférent | `svg/sprites/table_nuit_nature.svg` |
| `svg/sprites/bureau.svg` | haut | `svg/sprites/bureau_nature.svg` |
| `svg/sprites/canape.svg` | haut | `svg/sprites/canape_nature.svg` |
| `svg/sprites/tv.svg` | bas | `svg/sprites/tele_nature.svg` |
| `svg/sprites/bibliotheque.svg` | indifférent | `svg/sprites/bibliotheque_nature.svg` |
| `svg/sprites/lampe_pied.svg` | indifférent | `svg/sprites/lampe_pied_nature.svg` |
| `svg/sprites/douche.svg` | bas | `svg/sprites/douche_nature.svg` |
| `svg/sprites/baignoire.svg` | haut | `svg/sprites/baignoire_nature.svg` |
| `svg/sprites/toilettes.svg` | haut | `svg/sprites/toilettes_nature.svg` |
| `svg/sprites/lavabo.svg` | bas | `svg/sprites/lavabo_nature.svg` |
| `svg/sprites/plante.svg` | indifférent | `svg/sprites/plante_nature.svg` |
| `svg/sprites/tapis.svg` | indifférent | `svg/sprites/tapis_nature.svg` |

Attention : la clé du meuble TV devient `tele` (l'ancien fichier s'appelait `tv.svg`).

## Fichiers

- `svg/sprites/<clé>_<collection>.svg` : 150 sprites (50 objets × 3 collections), tous face avant en haut, exactement à la taille de l'objet en cases.
- `svg/sprites/<clé>_<collection>_actif.svg` : état « en marche » pour 13 objets × 3 collections (cuisinière, micro-ondes, machine à café, lave-vaisselle, lampe de chevet, meuble TV, lampe sur pied, cheminée, chaîne hi-fi, douche, machine à laver, ordinateur, barbecue). Même taille que le sprite normal : il suffit d'échanger la texture.
- `apercu_<catégorie>.png` : une planche de contrôle par catégorie (Nature, Rétro, Moderne, puis l'état actif Nature).
- Objets à poser contre un mur : le dos est en bas du sprite. Pour les orienter, tourne de 180° (mur du haut), 90° (mur de gauche) ou 270° (mur de droite).
- Objets « au sol, traversables » (`tapis`, `tapis_yoga`) : sans contour extérieur, à dessiner sous les meubles et les Mouz.
- Objets « à plusieurs » : la table et le salon de jardin ont une place en haut et une en bas (face à face) ; la table de jeux a un coussin de chaque côté ; le canapé a trois coussins ; la console a deux manettes.

## Tous les objets

Face avant = haut pour tous. Prix : je garde ceux du brief, ils sont cohérents entre eux.

| Clé | Nom | Catégorie | Cases | Face | Collections | Prix | Interactions → icônes | État actif |
|---|---|---|---|---|---|---|---|---|
| `frigo` | Frigo | Cuisine | 1 × 1 | haut | nature, retro, moderne | 800 Mz | Manger → `manger`, Prendre un en-cas → `en_cas` | — |
| `cuisiniere` | Cuisinière | Cuisine | 1 × 1 | haut | nature, retro, moderne | 650 Mz | Cuisiner → `cuisiner` | oui |
| `evier` | Évier | Cuisine | 2 × 1 | haut | nature, retro, moderne | 400 Mz | Faire la vaisselle → `vaisselle` | — |
| `plan_travail` | Plan de travail | Cuisine | 3 × 1 | haut | nature, retro, moderne | 300 Mz | Préparer un repas → `preparer_repas` | — |
| `table` | Table | Cuisine | 2 × 2 | haut | nature, retro, moderne | 250 Mz | Manger à table → `manger` | — |
| `chaise` | Chaise | Cuisine | 1 × 1 | haut | nature, retro, moderne | 80 Mz | S'asseoir → `s_asseoir` | — |
| `micro_ondes` | Micro-ondes | Cuisine | 1 × 1 | haut | nature, retro, moderne | 200 Mz | Réchauffer un plat → `rechauffer` | oui |
| `machine_cafe` | Machine à café | Cuisine | 1 × 1 | haut | nature, retro, moderne | 180 Mz | Boire un café → `cafe` | oui |
| `lave_vaisselle` | Lave-vaisselle | Cuisine | 1 × 1 | haut | nature, retro, moderne | 450 Mz | Lancer la vaisselle → `vaisselle` | oui |
| `poubelle` | Poubelle | Cuisine | 1 × 1 | haut | nature, retro, moderne | 40 Mz | Sortir la poubelle → `poubelle` | — |
| `lit` | Lit double | Chambre | 2 × 3 | haut | nature, retro, moderne | 1 000 Mz | Dormir → `dormir`, Faire la sieste → `sieste` | — |
| `armoire` | Armoire | Chambre | 2 × 1 | haut | nature, retro, moderne | 700 Mz | Se changer → `se_changer` | — |
| `table_nuit` | Table de nuit | Chambre | 1 × 1 | haut | nature, retro, moderne | 90 Mz | Lire un peu → `lire` | — |
| `bureau` | Bureau | Chambre | 2 × 1 | haut | nature, retro, moderne | 450 Mz | Lire → `lire`, Écrire → `ecrire` | — |
| `lit_simple` | Lit simple | Chambre | 1 × 2 | haut | nature, retro, moderne | 600 Mz | Dormir → `dormir` | — |
| `commode` | Commode | Chambre | 2 × 1 | haut | nature, retro, moderne | 400 Mz | Ranger ses affaires → `ranger` | — |
| `coiffeuse` | Coiffeuse avec miroir | Chambre | 2 × 1 | haut | nature, retro, moderne | 500 Mz | Se coiffer → `se_coiffer` | — |
| `lampe_chevet` | Lampe de chevet | Chambre | 1 × 1 | haut | nature, retro, moderne | 60 Mz | Lire au lit → `lire` | oui |
| `canape` | Canapé | Salon | 3 × 2 | haut | nature, retro, moderne | 750 Mz | Regarder la TV → `regarder_tv`, Faire une sieste → `sieste` | — |
| `tele` | Meuble TV | Salon | 3 × 1 | haut | nature, retro, moderne | 600 Mz | Regarder la TV → `regarder_tv` | oui |
| `bibliotheque` | Bibliothèque | Salon | 3 × 1 | haut | nature, retro, moderne | 350 Mz | Lire → `lire` | — |
| `lampe_pied` | Lampe sur pied | Salon | 1 × 1 | haut | nature, retro, moderne | 120 Mz | Allumer → `—`, éteindre → `—` | oui |
| `fauteuil` | Fauteuil | Salon | 1 × 1 | haut | nature, retro, moderne | 350 Mz | S'asseoir → `s_asseoir`, Lire → `lire` | — |
| `table_basse` | Table basse | Salon | 2 × 1 | haut | nature, retro, moderne | 150 Mz | Poser un verre → `—` | — |
| `cheminee` | Cheminée | Salon | 2 × 1 | haut | nature, retro, moderne | 1 500 Mz | Se réchauffer → `se_rechauffer` | oui |
| `console_jeux` | Console de jeux | Salon | 1 × 1 | haut | nature, retro, moderne | 400 Mz | Jouer aux jeux vidéo → `jeux_video` | — |
| `chaine_hifi` | Chaîne hi-fi | Salon | 1 × 1 | haut | nature, retro, moderne | 300 Mz | Écouter de la musique → `musique`, Danser → `danser` | oui |
| `douche` | Douche | Salle de bain | 2 × 2 | haut | nature, retro, moderne | 900 Mz | Se laver → `se_laver` | oui |
| `baignoire` | Baignoire | Salle de bain | 3 × 2 | haut | nature, retro, moderne | 1 200 Mz | Prendre un bain → `bain` | — |
| `toilettes` | Toilettes | Salle de bain | 1 × 1 | haut | nature, retro, moderne | 300 Mz | Utiliser → `toilettes` | — |
| `lavabo` | Lavabo | Salle de bain | 1 × 1 | haut | nature, retro, moderne | 250 Mz | Se laver les mains → `se_laver_mains`, Se brosser les dents → `dents` | — |
| `miroir_mural` | Miroir et meuble | Salle de bain | 2 × 1 | haut | nature, retro, moderne | 350 Mz | Se maquiller → `maquiller`, Se raser → `se_raser` | — |
| `machine_laver` | Machine à laver | Salle de bain | 1 × 1 | haut | nature, retro, moderne | 550 Mz | Faire la lessive → `lessive` | oui |
| `panier_linge` | Panier à linge | Salle de bain | 1 × 1 | haut | nature, retro, moderne | 50 Mz | Trier le linge → `linge` | — |
| `ordinateur` | Ordinateur | Loisirs | 2 × 1 | haut | nature, retro, moderne | 900 Mz | Surfer → `surfer`, Jouer en ligne → `jeux_video`, Discuter en ligne → `discuter` | oui |
| `piano` | Piano | Loisirs | 2 × 1 | haut | nature, retro, moderne | 1 800 Mz | Jouer du piano → `piano` | — |
| `chevalet` | Chevalet de peinture | Loisirs | 1 × 1 | haut | nature, retro, moderne | 300 Mz | Peindre → `peindre` | — |
| `tapis_yoga` | Tapis de yoga | Loisirs | 1 × 2 | haut | nature, retro, moderne | 80 Mz | Faire du yoga → `yoga` | — |
| `table_jeux` | Table de jeux | Loisirs | 2 × 2 | haut | nature, retro, moderne | 400 Mz | Jouer aux échecs → `echecs`, Jouer aux cartes → `cartes` | — |
| `telescope` | Télescope | Loisirs | 1 × 1 | haut | nature, retro, moderne | 700 Mz | Observer les étoiles → `etoiles` | — |
| `barbecue` | Barbecue | Jardin | 1 × 1 | haut | nature, retro, moderne | 450 Mz | Faire un barbecue → `barbecue` | oui |
| `hamac` | Hamac | Jardin | 3 × 1 | haut | nature, retro, moderne | 350 Mz | Faire la sieste → `sieste` | — |
| `balancoire` | Balançoire | Jardin | 2 × 1 | haut | nature, retro, moderne | 300 Mz | Se balancer → `se_balancer` | — |
| `potager` | Potager | Jardin | 2 × 2 | haut | nature, retro, moderne | 200 Mz | Jardiner → `jardiner`, Récolter → `recolter` | — |
| `salon_jardin` | Salon de jardin | Jardin | 2 × 2 | haut | nature, retro, moderne | 500 Mz | Prendre l'apéro → `apero` | — |
| `arbre` | Arbre | Jardin | 2 × 2 | haut | nature, retro, moderne | 150 Mz | Grimper → `grimper` | — |
| `plante` | Plante en pot | Déco | 1 × 1 | haut | nature, retro, moderne | 40 Mz | Arroser → `arroser` | — |
| `tapis` | Tapis | Déco | 6 × 4 | haut | nature, retro, moderne | 150 Mz | — | — |
| `aquarium` | Aquarium | Déco | 2 × 1 | haut | nature, retro, moderne | 600 Mz | Regarder les poissons → `poissons`, Nourrir les poissons → `poissons` | — |
| `horloge` | Horloge comtoise | Déco | 1 × 1 | haut | nature, retro, moderne | 450 Mz | Remonter l'horloge → `remonter_horloge` | — |

## Déclinaisons suggérées (pour le prochain brief)

| Clé | Déclinaison | Cases | Ce qui change |
|---|---|---|---|
| `frigo` | Petit frigo | 1 × 1 | Version simple : moins d'en-cas, se vide plus vite, 450 Mz |
| `frigo` | Frigo américain | 2 × 1 | Luxe : deux portes, distributeur de glaçons, repas de meilleure qualité, 1 800 Mz |
| `cuisiniere` | Réchaud deux feux | 1 × 1 | Simple : cuisson plus lente, risque de rater le plat |
| `cuisiniere` | Piano de cuisson | 2 × 1 | Luxe : six feux, cuisine pour plusieurs Mouz, bonus de plaisir |
| `evier` | Évier double bac | 3 × 1 | Vaisselle plus rapide, deux Mouz en même temps |
| `plan_travail` | Plan d'angle | 2 × 2 | Se pose dans un coin |
| `plan_travail` | Îlot central | 3 × 2 | Luxe : accessible des deux côtés, deux Mouz préparent ensemble |
| `table` | Table pour deux | 1 × 2 | Simple : deux places seulement |
| `table` | Grande tablée | 3 × 2 | Six places, bonus social aux repas partagés |
| `chaise` | Tabouret | 1 × 1 | Simple : moins confortable, 30 Mz |
| `chaise` | Chaise rembourrée | 1 × 1 | Luxe : confort supérieur |
| `micro_ondes` | Four encastré | 1 × 1 | Luxe : réchauffe et cuit, repas de meilleure qualité |
| `machine_cafe` | Cafetière filtre | 1 × 1 | Simple : plus lente, moins d'énergie gagnée |
| `machine_cafe` | Machine expresso pro | 2 × 1 | Luxe : deux tasses à la fois, bonus de plaisir |
| `lave_vaisselle` | Lave-vaisselle compact | 1 × 1 | Simple : cycle plus long, plus bruyant |
| `poubelle` | Poubelle de tri | 2 × 1 | Trois bacs, se remplit moins vite |
| `lit` | Futon | 2 × 2 | Simple : se pose au sol, sommeil moins réparateur |
| `lit` | Lit à baldaquin | 3 × 3 | Luxe : meilleur sommeil, bonus d'humeur au réveil |
| `armoire` | Penderie ouverte | 2 × 1 | Simple : se changer plus vite, moins de rangement |
| `armoire` | Dressing | 3 × 2 | Luxe : on y entre, bonus d'humeur |
| `table_nuit` | Caisse en bois | 1 × 1 | Simple : décor seul, 20 Mz |
| `bureau` | Bureau d'angle | 2 × 2 | Plus de place, ordinateur et écriture côte à côte |
| `bureau` | Secrétaire ancien | 2 × 1 | Luxe : bonus d'inspiration pour écrire |
| `lit_simple` | Lit superposé | 1 × 2 | Deux places l'une sur l'autre |
| `lit_simple` | Lit d'enfant | 1 × 2 | Plus court, pour les petits Mouz |
| `commode` | Chiffonnier | 1 × 1 | Version haute et étroite, moins de rangement |
| `coiffeuse` | Miroir sur pied | 1 × 1 | Simple : se coiffer debout, moins de bonus |
| `lampe_chevet` | Lampe tactile | 1 × 1 | Luxe : intensité réglable, bonus pour lire au lit |
| `canape` | Causeuse | 2 × 1 | Simple : deux places, moins de confort |
| `canape` | Canapé d'angle | 3 × 3 | Luxe : quatre places, sieste plus réparatrice |
| `tele` | Petite télé | 2 × 1 | Simple : moins de plaisir par heure |
| `tele` | Home cinéma | 4 × 1 | Luxe : grand écran et enceintes, regarder à plusieurs |
| `bibliotheque` | Étagère murale | 2 × 1 | Simple : moins de livres, apprentissage plus lent |
| `bibliotheque` | Bibliothèque d'angle | 2 × 2 | Luxe : plus de choix, bonus d'apprentissage |
| `lampe_pied` | Lampadaire arc | 1 × 2 | Luxe : éclaire deux cases plus loin |
| `fauteuil` | Pouf | 1 × 1 | Simple : s'asseoir seulement |
| `fauteuil` | Fauteuil inclinable | 1 × 2 | Luxe : on peut y faire la sieste |
| `table_basse` | Table gigogne | 1 × 1 | Simple : plus petite |
| `table_basse` | Table basse coffre | 2 × 1 | Rangement de jeux de société |
| `cheminee` | Poêle à bois | 1 × 1 | Simple : chauffe une seule pièce, moins cher |
| `cheminee` | Cheminée double face | 2 × 1 | Luxe : chauffe deux pièces à travers un mur |
| `console_jeux` | Console portable | 1 × 1 | Simple : un seul joueur, pas besoin de télé |
| `chaine_hifi` | Radio | 1 × 1 | Simple : musique seulement, pas de danse |
| `chaine_hifi` | Platine vinyle | 2 × 1 | Luxe : bonus d'humeur, danser à plusieurs |
| `douche` | Douche à l'italienne | 2 × 2 | Luxe : plus rapide, bonus de plaisir |
| `douche` | Douche d'angle | 1 × 1 | Simple : se pose dans un coin, plus lente |
| `baignoire` | Baignoire sabot | 2 × 1 | Simple : bain plus court |
| `baignoire` | Spa | 3 × 3 | Luxe : à plusieurs, bonus de plaisir et social |
| `toilettes` | Toilettes japonaises | 1 × 1 | Luxe : bonus d'hygiène |
| `lavabo` | Double vasque | 2 × 1 | Deux Mouz se brossent les dents en même temps |
| `miroir_mural` | Miroir lumineux | 2 × 1 | Luxe : se maquiller plus vite, meilleur résultat |
| `machine_laver` | Lavante-séchante | 1 × 1 | Luxe : pas besoin d'étendre le linge |
| `panier_linge` | Bac à trois compartiments | 2 × 1 | Tri plus rapide |
| `ordinateur` | Ordinateur portable | 1 × 1 | Simple : se pose sur un bureau ou une table |
| `ordinateur` | Poste de jeu | 3 × 1 | Luxe : deux écrans, bonus en jeu en ligne |
| `piano` | Clavier électrique | 2 × 1 | Simple : moins cher, apprentissage plus lent |
| `piano` | Piano à queue | 3 × 3 | Luxe : bonus de compétence et d'humeur pour ceux qui écoutent |
| `chevalet` | Table à dessin | 2 × 1 | Dessiner assis, peindre plus vite |
| `tapis_yoga` | Tapis épais | 1 × 2 | Luxe : bonus d'énergie après la séance |
| `table_jeux` | Table de poker | 3 × 2 | Quatre joueurs, cartes uniquement |
| `table_jeux` | Billard | 3 × 2 | Nouvelle interaction à deux |
| `telescope` | Lunette de jardin | 1 × 1 | Simple : observer les oiseaux le jour |
| `barbecue` | Plancha | 2 × 1 | Luxe : cuisine pour plusieurs Mouz, se pose sur la terrasse |
| `hamac` | Hamac sur pied | 3 × 1 | Pas besoin d'arbres, se pose n'importe où |
| `balancoire` | Balançoire double | 3 × 1 | Deux Mouz se balancent ensemble |
| `potager` | Jardinière | 2 × 1 | Simple : moins de récoltes |
| `potager` | Serre | 3 × 3 | Luxe : récoltes en toute saison |
| `salon_jardin` | Table de pique-nique | 3 × 2 | Six places |
| `salon_jardin` | Bistrot | 1 × 1 | Simple : deux places autour d'une petite table |
| `arbre` | Arbuste | 1 × 1 | Simple : décor, on ne grimpe pas |
| `arbre` | Arbre fruitier | 2 × 2 | Récolter des fruits |
| `plante` | Cactus | 1 × 1 | Arroser une fois par semaine |
| `plante` | Grande plante | 1 × 1 | Luxe : bonus d'humeur dans la pièce |
| `tapis` | Petit tapis | 2 × 1 | Simple : décor seul |
| `tapis` | Grand tapis | 8 × 5 | Luxe : bonus de confort dans la pièce |
| `aquarium` | Bocal | 1 × 1 | Simple : un seul poisson |
| `aquarium` | Grand aquarium | 3 × 1 | Luxe : bonus d'humeur, poissons rares |
| `horloge` | Pendule murale | 1 × 1 | Simple : décor, pas besoin de la remonter |

## Nouvelles icônes

Grille 24 × 24, trait 2 px, versions `encre/` et `blanc/`.

- Interactions : `en_cas`, `cuisiner`, `vaisselle`, `preparer_repas`, `s_asseoir`, `rechauffer`, `cafe`, `poubelle`, `sieste`, `se_changer`, `ecrire`, `ranger`, `se_coiffer`, `se_rechauffer`, `jeux_video`, `musique`, `danser`, `se_laver_mains`, `dents`, `maquiller`, `se_raser`, `lessive`, `linge`, `surfer`, `piano`, `peindre`, `yoga`, `echecs`, `cartes`, `etoiles`, `barbecue`, `se_balancer`, `jardiner`, `recolter`, `arroser`, `apero`, `grimper`, `poissons`, `remonter_horloge`, `allumer`, `toilettes`, `bain`
- Catégories : `loisirs`, `jardin`
- Collections : `nature` (feuille), `retro` (soleil), `moderne` (cube)
- Regroupements : « Lancer la vaisselle » → `vaisselle` ; « Lire un peu » et « Lire au lit » → `lire` ; « Jouer en ligne » → `jeux_video` ; « Discuter en ligne » → `discuter` ; « Nourrir les poissons » → `poissons` ; « Faire une sieste » → `sieste` ; « Manger à table » → `manger`.

## Composants : choisir un style

### Pastille de collection

- Rond de 22 px (20 dans la vignette), bordure 2 px `#3D3357`, fond = couleur signature de la collection.
- Icône de la collection 12 px (trait 2,5) : encre sur Nature et Rétro, blanc sur Moderne. La forme de l'icône distingue les collections sans la couleur.
- **Choisie** : anneau extérieur 2 px `#3D3357`, séparé par 2 px de papier (`box-shadow: 0 0 0 2px #FFF8EE, 0 0 0 4px #3D3357`). **Survol** : même anneau en accent.
- Écart 8 px ; on n'affiche que les collections disponibles pour l'objet.

### Vignette du catalogue

- Inchangée (120 de large, padding 8, rayon 12, image 104 × 72) ; sous le prix : séparateur 2 px `#F6EBDD`, puis la rangée de pastilles.
- L'image montre la collection choisie. Cliquer une pastille change l'image et la collection achetée, sans sélectionner la vignette.
- États survol / choisi / trop cher inchangés. En « trop cher », les pastilles restent actives (on peut regarder les styles).
- Hauteur du panneau catalogue : environ 252 px avec les pastilles.

### Filtre par collection

- À droite des onglets de catégorie : « Toutes / Nature / Rétro / Moderne ».
- Groupe fond `#F6EBDD`, padding 3, rayon 11, écart 2. Bouton hauteur 30, padding 0 10, rayon 8, point 12 px couleur signature (bord intérieur 1,5 px encre) + Nunito 13/800.
- Actif : fond `#3D3357`, texte `#FFF8EE`. Survol : fond blanc, bordure 2 px accent.
- Un filtre actif masque les objets sans cette collection et affiche cette collection par défaut dans toutes les vignettes.

### Onglets de catégorie compacts

Avec 10 catégories, seul l'onglet actif garde son libellé (padding 0 12). Les autres sont des carrés 36 × 34 avec icône 16 et `aria-label` (infobulle au survol).

### Bulle d'un objet posé

- 236 de large. Ordre : en-tête (vignette + nom + « Collection Rétro » 11/700), Déplacer, **Changer de style**, Revendre.
- « Changer de style » : icône `peindre` 20 + Nunito 15/700 ; en dessous, décalées de 30 px, les pastilles 22 px et le coût aligné à droite ; une ligne d'explication 11/700 encre douce.
- Coût suggéré : **gratuit le jour de l'achat**, puis **25 % du prix** (revente à 75 % + rachat au prix plein). « Gratuit » en `#0B6E52` ; montant avec pièce 12 + Nunito 12/800 ; s'il manque de l'argent, le montant passe en `#B3261E` et la pastille est refusée.
- Le changement se fait au clic sur une pastille, avec la variation du solde habituelle.

---

# Vue trois quarts (brief n° 6)

Planches : colonne « Vue trois quarts · lot 1 » du canvas (scène salon + chambre, règles et pièces). Planche de contrôle : `apercu_vue34_lot1.png`.

Les sprites vus de dessus restent en place tant que leur remplaçant n'est pas livré.

## Lot 1 · Les règles de la vue

### Projection

Un point du monde (x, y) au sol, à la hauteur z, s'affiche en **(x, y − z)**. Le sol reste une grille de cases carrées de 32 px, sans déformation, et le terrain fait toujours 30 × 20 cases. Le dessus d'un volume garde sa vraie profondeur et sa face avant (tournée vers le bas de l'écran) garde sa vraie hauteur. On ne voit jamais les faces gauche, droite ou arrière d'un volume, seulement son dessus et sa face du bas.

Repère : **1 m ≈ 32 px**. Les faces avant sont plus foncées que les dessus (même teinte, 14 % plus sombre), toujours en aplat.

### Hauteurs retenues

| Élément | Hauteur |
|---|---|
| Tapis, tapis de yoga | 0 |
| Table basse | 18 |
| Lit (matelas et couette) | 20, tête de lit 34 |
| Baignoire | 20 |
| Table, bureau, plan de travail | 27 |
| Chaise | assise 16, dossier 34 |
| Canapé, fauteuil | assise 20, dossier 30 à 32 |
| Meuble TV | 18, écran jusqu'à 44 |
| Plante en pot | 34 (pot 13) |
| Frigo, armoire, bibliothèque | 60 |
| Mur plein / baissé | 64 / 12 |
| Adulte debout | 48 |

### Taille et ancrage d'un sprite

- Largeur = emprise × 32 ; hauteur = profondeur de l'emprise × 32 + hauteur de l'objet. Ex. : canapé 3 × 2 et 32 px de haut → 96 × 96 ; armoire 2 × 1 et 60 px → 64 × 92.
- **Ancrage** : le bas de l'image est le bas de l'emprise (décalage 0 pour tous les objets). On pose l'image en `(x_emprise, bas_emprise − hauteur_image)`.
- **Ombre** : ombre découpée `#2B2440` à 16 %, sans flou, au pied de chaque volume posé au sol, décalée de 3 px vers la droite (bande de 7 px). Elle est dans le sprite. Les objets laissent 2 px de marge dans leur emprise pour qu'elle se voie.

### Ordre d'affichage

Le jeu dessine du haut vers le bas de l'écran, selon le **bas de l'emprise** (les pieds pour un personnage) : ce qui est plus bas passe devant. Les tapis restent toujours dessous. Chaque sprite est un volume complet : il ne compte pas sur ce qui sera devant ou derrière lui.

### Les 4 vues

| Vue | Face avant tournée vers | On voit |
|---|---|---|
| `bas` | le bas de l'écran | la face avant (vue du catalogue) |
| `haut` | le haut | le dos |
| `gauche` | la gauche | le côté gauche de l'objet |
| `droite` | la droite | le côté droit ; si `miroir: true`, c'est `gauche` retourné |

Une emprise 2 × 1 en `bas`/`haut` devient 1 × 2 en `gauche`/`droite`. Nommage : `<clé>_<collection>_<vue>.svg`, état en marche `<clé>_<collection>_<vue>_actif.svg`.

## Lot 1 · Les murs

Un mur fait 8 px d'épaisseur, posé à cheval sur une ligne de la grille (4 px de chaque côté).

- **Mur horizontal** : on voit son dessus (bande de 8 px, remontée de la hauteur du mur) et sa face (64 px, ou 12 px baissé).
- **Mur vertical** : on ne voit que son dessus, une bande de 8 px de large remontée de 64 px, et sa tranche en bas, qui est la face du poteau du bout.

### Couleurs

La face tournée vers l'intérieur d'une pièce prend la couleur du style. La face tournée vers l'extérieur est un enduit clair avec un soubassement de la couleur du style : de dehors, la maison se lit d'un coup d'œil et les styles restent reconnaissables.

| Style | Dessus | Face intérieure | Plinthe (6 px) | Face extérieure |
|---|---|---|---|---|
| prune | `#898099` | `#5B4E72` | `#473D59` | `#EFE6D6` + soubassement `#5B4E72` |
| brique | `#B8897D` | `#9C5B4A` | `#7A473A` | `#EFE6D6` + soubassement `#9C5B4A` |
| sauge | `#809A8F` | `#4F7363` | `#3E5A4D` | `#EFE6D6` + soubassement `#4F7363` |
| ardoise | `#758498` | `#3F5470` | `#314257` | `#EFE6D6` + soubassement `#3F5470` |

### Les pièces (`svg/murs/`)

Le mur se monte avec des morceaux entre les nœuds de la grille et un poteau à chaque nœud. Les traits de contour ne sont dessinés que sur le bord extérieur de l'ensemble, donc les raccords ne montrent aucune couture.

| Pièce | Taille plein / baissé | Où la poser (nœud en X, Y) | Tri |
|---|---|---|---|
| `mur_<style>_<plein\|baisse>_h_<int\|ext>` | 24 × 72 / 24 × 20 | segment entre (X, Y) et (X + 32, Y) : en (X + 4, Y + 4 − hauteur de l'image) | Y + 4 |
| `mur_<style>_<plein\|baisse>_v` | 8 × 88 / 8 × 36 | segment entre (X, Y) et (X, Y + 32) : en (X − 4, Y + 4 − hauteur du mur) | Y + 28 |
| `poteau_<style>_<plein\|baisse>_<masque>[_<int\|ext>]` | 8 × 72 / 8 × 20 | nœud (X, Y) : en (X − 4, Y + 4 − hauteur de l'image) | Y + 4 |

- **Masque du poteau** : les lettres `n`, `e`, `s`, `o` des directions où un mur part du nœud, dans cet ordre (`ne`, `neso`, `eo`…), ou `seul`. Les 16 combinaisons couvrent tous les raccords : angle (`es`, `so`, `ne`, `no`), T (`eso`, `neo`, `nes`, `nso`), croix (`neso`), bout (`e`, `o`, `n`, `s`), ligne droite (`eo`, `ns`).
- **Face** : un poteau sans mur vers le bas (`s` absent) montre sa face, en version `_int` ou `_ext`. Prends `_int` si l'une des deux cases sous le nœud est dans une pièce. Pour un segment horizontal, prends `_int` si la case juste en dessous est dans une pièce.
- **Mur baissé** : mêmes pièces, même placement, avec une hauteur de mur de 12 px. On l'utilise en mode Construire et pour voir l'intérieur des pièces.

## Lot 1 · Portes et fenêtres (`svg/ouvertures/`)

Ce sont des calques posés **par-dessus** le morceau de mur correspondant (même position, dessinés juste après lui). Ils ne dépendent pas du style du mur.

| Fichier | Taille plein / baissé | Contenu |
|---|---|---|
| `<porte>_h_plein.svg` | 24 × 72 | porte fermée dans la face, linteau de 14 px au-dessus |
| `<porte>_h_plein_ouverte.svg` | 24 × 72 | passage sombre, battant rabattu à gauche, seuil |
| `<porte>_h_baisse[_ouverte].svg` | 24 × 20 | seuil et battant à 12 px |
| `<porte>_v_plein[_ouverte].svg` | 8 × 88 | repère sur la bande du dessus : seuil et battant |
| `<porte>_v_baisse[_ouverte].svg` | 8 × 36 | seuil, battant fermé (5 px) ou ouvert (toute la longueur) |
| `fenetre_h_plein.svg` | 24 × 72 | cadre crème, vitrage `#9FD3F2`, meneau, appui |
| `fenetre_large_h_plein.svg` | 56 × 72 | sur deux segments, couvre le poteau du milieu |
| `fenetre[_large]_h_baisse.svg` | 24 (56) × 20 | vitrage posé sur le dessus du mur baissé |
| `fenetre[_large]_v_<plein\|baisse>.svg` | 8 × 88 (120) / 8 × 36 (68) | vitrage dans la bande du dessus |

Les portes sont **fermées par défaut** : une porte ouverte en permanence encombre la face du mur. Le jeu affiche `_ouverte` le temps qu'un Mouz passe. Dans un mur vertical plein, une porte est cachée par le mur, comme en vrai. On la repère donc à son seuil et à son battant dessinés sur la bande du dessus, et elle se lit pleinement en mur baissé.

## Lot 1 · Sols

Les 9 sols existants restent valables tels quels. Les objets ont maintenant un contour encre, une face avant plus sombre et une ombre au pied, donc ils se détachent assez de tous les sols, y compris le béton et le lino. Je n'ai rien changé.

## Lot 1 · Objets témoins (collection Nature)

Tous symétriques gauche/droite : `miroir: true`, on livre `bas`, `haut` et `gauche`, et `droite` est `gauche` retourné.

| Clé | Nom | Emprise | Hauteur | Sprite bas/haut | Sprite gauche/droite | Miroir |
|---|---|---|---|---|---|---|
| `canape` | Canapé | 3 × 2 | 32 px | 96 × 96 | 64 × 128 | oui |
| `tele` | Meuble TV | 3 × 1 | 44 px | 96 × 76 | 32 × 140 | oui |
| `lit` | Lit double | 2 × 3 | 34 px | 64 × 130 | 96 × 98 | oui |
| `frigo` | Frigo | 1 × 1 | 60 px | 32 × 92 | 32 × 92 | oui |
| `table` | Table | 2 × 2 | 27 px | 64 × 91 | 64 × 91 | oui |
| `chaise` | Chaise | 1 × 1 | 34 px | 32 × 66 | 32 × 66 | oui |
| `plante` | Plante en pot | 1 × 1 | 34.0 px | 32 × 66.0 | 32 × 66.0 | oui |

- `tele_nature_<vue>_actif.svg` : écran allumé et reflet sur le meuble (vues bas, haut, gauche).
- La table et ses deux couverts restent face à face dans les 4 vues. Le lit a sa tête contre le mur (en haut en vue `bas`). Le canapé en vue `haut` montre son dos : c'est le cas habituel quand il regarde une télé placée plus haut dans la pièce.

## Lot 1 · Personnage provisoire

Un adulte simple, uniquement pour juger des proportions : 48 px de haut, dans une image de **32 × 64**. Ses pieds sont au centre de sa case, 16 px au-dessus du bas de l'image. On pose l'image en `(x_case, bas_case − 64)` et on le trie selon ses pieds (`bas_case − 16`).

Fichiers : `svg/personnages/provisoire_<bas|haut|gauche>[_marche_1|_marche_2].svg`. La vue `droite` est le miroir de `gauche`. La marche fait alterner jambes et bras, avec un rebond de 1 px.

## À vérifier dans le jeu avant le lot 2

- Le tri par bas d'emprise : le personnage doit passer derrière la table quand il est au-dessus, devant quand il est en dessous, et disparaître derrière le mur du bas quand il le longe (visible en mur baissé).
- La lisibilité des portes dans les murs verticaux pleins.
- La place du personnage dans sa case (pieds au centre) par rapport aux meubles.

## Lot 2 · Les humains

Planches : colonne « Vue trois quarts · lot 2 » du canvas. Planches de contrôle : `apercu_personnages.png` (âge × sexe × directions, trois jeux de couleurs) et `apercu_creation_famille.png` (les écrans de création et le choix du terrain).

Les Mouz sont maintenant des humains, aux proportions du personnage provisoire validé au lot 1.

### Cadre et ancrage

- Chaque calque est une image **32 × 64**, toutes superposées sans décalage. Les pieds sont à y = 48, au centre de la case. On pose l'image en `(x_case, bas_case − 64)` et on trie selon les pieds (`bas_case − 16`).
- Hauteurs : enfant 32 px, ado 42, adulte 48, aîné 46 (épaules un peu voûtées, tête légèrement en avant de profil).
- Directions livrées : `bas`, `haut`, `gauche`. `droite` est `gauche` retourné (miroir horizontal de l'ensemble des calques).
- Poses : debout, `_marche_1`, `_marche_2`. Les calques du corps sont dessinés pour chaque pose. Les têtes et les cheveux n'existent qu'en une version par direction : en marche, le jeu les **remonte de 1 px**.

### Les calques, dans l'ordre d'empilement

| # | Fichier | Couleur |
|---|---|---|
| 1 | `ombre_<sexe>_<age>.svg` | fixe |
| 2 | `cheveux_<coupe>_<age>_<dir>_arriere.svg` puis `…_arriere_contour.svg` | cheveux / encre |
| 3 | `corps_<sexe>_<age>_<tenue>_<dir>[_marche_n]_pantalon.svg` | pantalon (absent avec la robe) |
| 4 | `corps_…_peau.svg` (bras, mains, jambes sous la robe) | peau |
| 5 | `corps_…_tenue.svg` | tenue |
| 6 | `corps_…_contour.svg` (traits, chaussures, plis, encolure) | fixe |
| 7 | `tete_<age>_<dir>.svg` | peau |
| 8 | `tete_<age>_<dir>_contour.svg` (yeux, bouche, joues, nez, rides de l'aîné) | fixe |
| 9 | `cheveux_<coupe>_<age>_<dir>.svg` | cheveux |
| 10 | `cheveux_<coupe>_<age>_<dir>_contour.svg` | fixe |

- Les zones à teinter sont en blanc pur `#FFFFFF`. Le jeu les colore par `modulate`.
- Le **pantalon** a son propre calque. Par défaut, je propose de le teinter en ardoise `#4A5568`, ce qui va avec toutes les tenues. Tu peux aussi lui donner une deuxième couleur de tenue plus tard.
- `_arriere` n'existe qu'en vue `bas` (cheveux longs, chignon, couettes, queue, boucles et afro, qui passent derrière la tête). De dos et de profil, tout est dans le calque de devant.
- `<tenue>` : `tshirt`, `pull`, `robe`. Les trois formes existent pour les deux sexes.

### Coupes

11 coupes, toutes disponibles à tous les âges pour qu'un Mouz garde sa coupe en vieillissant. Seule exception : `degarni` n'existe qu'à partir d'adulte. Si un enfant ou un ado en hérite, le jeu prend `court`.

| Coupe | Suggérée pour |
|---|---|
| `court`, `rase`, `degarni` | hommes |
| `longs`, `carre`, `chignon`, `couettes` | femmes |
| `meche`, `boucles`, `afro`, `queue` | les deux |

L'écran de création propose d'abord les coupes suggérées pour le sexe choisi (7 ou 8), avec un lien « Toutes les coupes (11) ».

### Palettes (`tokens.json` → `personnages.palettes`)

- **Peau** (8, de très claire à très foncée) : porcelaine `#FBE3D2`, claire `#F3CDB0`, doree `#E5B48C`, miel `#D39A6A`, caramel `#B77B4E`, cannelle `#97603A`, cacao `#764528`, ebene `#5A3420`.
- **Cheveux** (8) : noir `#3B2F35`, brun `#6B4532`, blond `#E2C178`, roux `#C8643B`, gris `#A8A6AE`, blanc `#EEECE6`, rose `#E58FB5`, bleu `#6FA8DC`. Pour les aînés, le tirage au hasard prend gris ou blanc.
- **Tenue** (10, prises dans la palette du jeu) : orange `#E8794A`, moutarde `#E2A93B`, sauge `#8DB596`, canard `#6FA3A0`, bleu `#3E9BD6`, pervenche `#A3B5EC`, prune `#C46BA0`, brique `#B85C45`, ardoise `#4A5568`, creme `#F3E3C3`.

### Portraits (`portrait_*`, 64 × 64, de face)

Même découpage et mêmes couleurs que le sprite, pour qu'on fasse le lien : `portrait_cheveux_<coupe>_<age>_arriere` (+ contour), `portrait_corps_<sexe>_<age>_<tenue>_peau`, `_tenue`, `_contour`, `portrait_tete_<age>` (+ contour avec le visage), `portrait_cheveux_<coupe>_<age>` (+ contour). Tailles d'affichage : 64 (panneau du personnage), 48 (carte de membre), 40 (sélecteur), 32 (relations), 220 (création).

### En jeu

- **Sélection** : ellipse au sol sous les pieds (rayons 13 × 6,5), fond accent à 18 %, trait 2,5 px accent en tirets 6/4, dessinée avant le personnage.
- **Étiquette de nom** : au-dessus de la tête (8 px au-dessus du haut de l'image), Nunito 9/800 sur `#3D3357`, rayon 6.
- **Sélecteur de famille** : en haut du panneau du personnage, portraits de 40 px avec le prénom en dessous. Le membre choisi a un anneau accent.
- **Relations** : une ligne par membre, portrait de 32 px, lien (« Couple », « Sa fille ») et barre de −100 à +100.

## Lot 2 · Créer la famille

Parcours : Accueil → Nouvelle partie → **Créer la famille** → **Choisir le terrain** → jeu.

### Écran de création (1280 × 720)

- **Barre du haut** : logo, « Nouvelle partie », étapes « 1 Famille — 2 Terrain » (étape faite : rond vert `#0B6E52` avec une coche).
- **Colonne de gauche** (308 de large) : nom de famille avec bouton dé (« Sert aussi de nom à la partie »), compteur « n / 4 », cartes de membre, emplacement « Ajouter un membre » tant qu'il reste de la place, puis le message de règle s'il y a lieu.
- **Aperçu** (360 de large) : portrait de 220 px dans un rond, prénom (Baloo 2 30/800), « Nom · Sexe · Âge », sprite ×2 qui marche sur du parquet, et les 4 directions à taille réelle.
- **Éditeur** (564 de large), en deux colonnes :
  - prénom + dé, interrupteur homme/femme, âge (4 boutons), « Apparence au hasard » ;
  - pastilles de peau, coupes (vignettes 58 × 58 avec le portrait du membre), couleur des cheveux, tenue (3 vignettes avec le sprite), couleur de la tenue.
- **Barre du bas** : Retour (secondaire) ; à droite, la raison du blocage en `#B3261E` s'il y en a une, puis « Choisir le terrain » (principal, inactif tant que ça bloque).

### Règles et erreurs

- 1 à 4 membres. On ne peut pas retirer le dernier (pas de ✕ sur sa carte).
- **Au moins un adulte ou un aîné.** Sinon, un bandeau rouge doux dans la colonne de gauche, « Il faut au moins un adulte ou un aîné dans la famille. », et le bouton reste inactif avec « Ajoute un adulte ou un aîné. ».
- **Prénom vide** : le champ passe en erreur (« Écris un prénom ou tire-en un au hasard. »), la carte montre « Prénom manquant » avec un bord rouge, et le bouton reste inactif avec « Donne un prénom à chaque membre. ».
- **Liens entre membres** (facultatif) : une petite pastille entre deux cartes, « Couple ▾ » (couple, parent, enfant, fratrie, colocs). Elle fixe la relation de départ. Elle reste discrète et n'alourdit pas l'écran. Sans lien choisi, la relation part de 0.

### Composants

Les mesures sont dans la planche « Composants création » et dans `tokens.json` → `composants` :
- **Carte de membre** : 276 × 72, rayon 14, portrait 48. Choisie : fond `#FDE7DB`, bord 3 px accent. Erreur : bord `#B3261E`. Vide : bord en tirets.
- **Champ de texte** : 44 de haut, rayon 10. Focus : bord accent + halo 3 px. Erreur : bord et message rouges.
- **Bouton dé** : 44 × 44, fond `#F6EBDD`.
- **Interrupteur homme/femme** et **sélecteur d'âge** : groupe fond `#F6EBDD`, padding 4, rayon 12. Actif : `#3D3357`.
- **Pastilles de couleur** : 26 px (20 pour la tenue). Choisie : anneau 2 px papier + 2 px encre. Chacune porte un nom (infobulle, lecteur d'écran).
- **Vignette de coupe** : 58 × 58. Indisponible pour l'âge : grisée, « dès adulte ».
- **Boutons** : principal, secondaire, destructif, inactif (44 de haut, rayon 12).
- **Carte de terrain** : 388 de large, vignette 16:9, nom Baloo 2 22/700, étiquette « Terrain vide » ou « Maison meublée », taille et prix. Choisie : fond `#FDE7DB`, bord 3 px accent.

### Choisir le terrain

- En haut : portraits de la famille en ligne (44 px, qui se chevauchent de 10 px), « Famille Lambert » et les prénoms, le champ **Nom de la partie** (prérempli « La maison des Lambert ») et le budget.
- 3 cartes de terrain côte à côte, puis en bas : Retour et « Emménager » (principal), avec le solde restant après l'achat.
- J'ai mis le nom de la partie ici, et plus sur l'accueil. On le connaît maintenant grâce au nom de famille, et on le valide au moment d'emménager.

### Icônes

`homme`, `femme`, `enfant`, `ado`, `adulte`, `aine`, `hasard` (dé), `ajouter_membre`, `retirer`, `famille`, `terrain`, `emmenager`, en versions encre et blanc.

## Plus tard : robot et IA (idées, pas de sprites)

- **Vieillir** : les calques gardent les mêmes clés d'un âge à l'autre (coupe, tenue, couleurs). Passer d'une tranche à la suivante ne change que `<age>` dans les noms de fichiers, et les cheveux grisent seulement si le joueur le choisit. Dans le panneau du personnage, une petite jauge d'âge sous le nom (« Adulte · 12 jours avant Aîné »).
- **Devenir un robot** : on garde la silhouette et les calques. La peau est teintée en métal (`#A9B1BC`), un calque fixe `robot_<age>_<dir>.svg` ajoute des rivets, une antenne et des articulations, et les yeux deviennent deux points lumineux `#9FD3F2`. Dans l'écran de création, cela pourrait devenir une 5e tranche d'âge, « Robot » (icône d'écrou), qui n'apparaît qu'une fois débloquée. Dans le panneau du personnage, la barre d'humeur garde sa place et une jauge « Révision » (icône de clé, couleur métal) s'ajoute sous les besoins. En retard de révision, elle passe en état critique avec les mêmes hachures.
- **Devenir l'IA de la maison** : plus de sprite. Le portrait devient un visage simple fait de deux yeux et d'un sourire en `#9FD3F2` sur un écran rond ardoise. Le Mouz reste dans le sélecteur de famille avec ce portrait. En jeu, sa présence se voit sur les objets qu'il pilote : un petit voyant bleu au coin du sprite et un halo pointillé bleu (même forme que l'anneau de sélection) quand il agit. Son panneau remplace les besoins par une liste de « routines » (allumer, régler, surveiller), chacune avec l'icône de l'objet. Dans l'écran de création, il n'apparaît pas au début : on y accède depuis le panneau d'un membre (« Transférer dans la maison »).

---

# Parties et sauvegardes (brief n° 3)

Planches : colonne « Parties et sauvegardes » du canvas (accueil sans partie et avec une partie, charger une partie dans tous ses états, menu en jeu, sauvegarder sous, messages de réussite et d'échec, composants, icônes). Planche de contrôle : `apercu_parties.png`.

Tout est dessiné avec la famille d'humains et la vue trois quarts.

## Accueil

- **Sans partie** : une petite scène de jardin vivante en fond (herbe, plantes, la famille qui se promène en vue trois quarts). Au centre, une carte de 440 px : portraits de la famille en ligne (56 px, chevauchement de 12 px), logo « Les Mouz » en Baloo 2 60/800, « Une maison de poche à construire », puis « Nouvelle partie » (principal). « Charger une partie » est inactif, avec « Aucune partie enregistrée pour l'instant. » en dessous, et il y a aussi « Quitter » (discret).
- **Avec une partie** : en fond, la vignette de la dernière partie **en grand** (la maison vue en trois quarts, à l'échelle 2) sous un voile `#2B2440` à 38 %. Le premier bouton devient « Continuer : La maison des Lambert » (principal, icône `continuer`), avec « Jour 3 · 18:40 · enregistrée il y a 5 min » juste en dessous. Viennent ensuite Nouvelle partie, Charger une partie (secondaires) et Quitter (discret). C'est ma proposition pour rendre l'accueil plus vivant : on retrouve sa maison avant même de cliquer.
- **Nouvelle partie** mène maintenant à la création de famille (lot 2 du brief n° 6). Le champ « Nom de la partie » quitte l'accueil pour l'écran Choisir le terrain : il y est prérempli à partir du nom de famille (« La maison des Lambert »).

## Charger une partie

- Barre de titre (940 × 52) : Retour, « Charger une partie » (Baloo 2 24/800), nombre de parties à droite. Dessous, la liste dans un panneau de 940 px.
- **Carte de partie** (916 de large, padding 12 14 12 12, rayon 14, écart 16) :
  - vignette 160 × 90 (image source 320 × 180), rayon 10 ;
  - nom Baloo 2 20/700 ; infos « Jour 3 · 18:40 · 18 800 Mz · 13 objets » en 13/700 avec les icônes horloge et pièce ; « Enregistrée il y a 5 min » en 12/600 ;
  - boutons de 36 de haut : Charger (principal), Renommer (secondaire), Supprimer (icône seule, `aria-label`, trait rouge).
- **En cours** : bord 3 px accent et étiquette « En cours ».
- **Renommage** : le nom devient un champ de 300 × 38 en focus, et les boutons deviennent OK / Annuler. Entrée valide, Échap annule. Si le nom est vide, OK reste inactif et le champ passe en erreur.
- **Suppression** : la carte passe sur fond `#F9D9D6` avec un bord `#B3261E`, puis « Supprimer définitivement ? », Supprimer (destructif) et Garder.
- **Partie abîmée** (la sauvegarde ne se lit plus) : vignette hachurée avec une alerte, étiquette « Abîmée », « Cette sauvegarde ne se lit plus. » en `#B3261E`. Si le jeu a gardé une copie de secours, on propose « Restaurer la copie » (je suggère de garder une copie `.bak` à chaque sauvegarde). Sinon, seulement Supprimer.
- **Liste vide** : une illustration (terrain et panneau), « Aucune partie enregistrée », une phrase d'aide et « Nouvelle partie ».

## Menu en jeu

- Un voile `#2B2440` à 55 % sur le jeu, et une carte de 376 px au centre : nom de la partie (Baloo 2 24/800), « Jour 3 · 18:40 · 18 800 Mz ».
- Boutons de 320 de large : Reprendre (principal, raccourci « Échap »), Sauvegarder (« Ctrl S »), Sauvegarder sous…, Charger une partie…, puis un séparateur, et Menu principal et Quitter le jeu en boutons discrets.
- **Sauvegarder sous…** : la carte affiche le champ « Nom de la copie » (prérempli « … (copie) », en focus) avec l'aide « La partie en cours reste ouverte. », puis Retour / Enregistrer.
- **Raccourci** : petite pastille à droite du bouton, 11/800, padding 1 × 6, rayon 6, bord 1,5 px de la couleur du texte.

## Message de confirmation

- En bas au centre, à 24 px du bord : fond blanc, bord 2 px, rayon 14, padding 10 × 14, ombre découpée, `role="status"`.
- **Succès** (« Partie enregistrée », « Copie enregistrée : nom ») : rond de 24 px `#0B6E52` avec une coche. Il reste 2 s et arrive en glissant de 8 px vers le haut.
- **Échec** (« La sauvegarde a échoué ») : rond `#B3261E` avec une alerte, la raison en 12/600 (« Disque plein ou dossier protégé. ») et un bouton « Réessayer ». Je propose qu'il reste 6 s ou jusqu'au clic : en 2 s, on n'a pas le temps de lire et de réagir.

## Composants communs

- **Champ de texte** : 44 de haut, rayon 10, bord 2 px `#E3D5C0`. Focus : bord accent + halo 3 px accent à 25 %. Erreur : bord `#B3261E` et message 12/700 avec l'icône alerte (« Le nom ne peut pas être vide. »).
- **Boutons** : principal (`#3D3357`, texte `#FFF8EE`), secondaire (bord 2 px `#E3D5C0`), destructif (`#B3261E`, texte blanc), discret (sans bord), inactif (`#E3D5C0`, texte `#5E5675`). Tous font 44 de haut (36 dans les cartes de partie), avec un rayon de 12.

## Icônes

`sauvegarder`, `charger`, `renommer`, `supprimer`, `menu`, `quitter`, `continuer`, en versions encre et blanc.

## Lot 3 · La cuisine

Planche : « Lot 3 · Cuisine » sur le canvas (une cuisine par collection, puis les 10 objets dans leurs 4 vues). Planche de contrôle : `apercu_cuisine.png`. Elle remplace l'ancienne planche vue de dessus du même nom.

133 fichiers dans `svg/sprites/`, nommés `<clé>_<collection>_<vue>[_actif].svg`. Les vues Nature du frigo, de la table et de la chaise, livrées au lot 1, sont redessinées avec le même moteur. Elles sont identiques en forme et en taille.

| Clé | Nom | Emprise | Hauteur | Sprite bas/haut | Sprite gauche/droite | Miroir | En marche |
|---|---|---|---|---|---|---|---|
| `frigo` | Frigo | 1 × 1 | 60 px | 32 × 92 | 32 × 92 | oui | — |
| `cuisiniere` | Cuisinière | 1 × 1 | 34 px | 32 × 66 | 32 × 66 | oui | oui |
| `evier` | Évier | 2 × 1 | 37 px | 64 × 69 | 32 × 101 | non (fichier droite livré) | — |
| `plan_travail` | Plan de travail | 3 × 1 | 27 px | 96 × 59 | 32 × 123 | non (fichier droite livré) | — |
| `table` | Table | 2 × 2 | 27 px | 64 × 91 | 64 × 91 | oui | — |
| `chaise` | Chaise | 1 × 1 | 34 px | 32 × 66 | 32 × 66 | oui | — |
| `micro_ondes` | Micro-ondes (sur meuble bas) | 1 × 1 | 42 px | 32 × 74 | 32 × 74 | oui | oui |
| `machine_cafe` | Machine à café (sur meuble bas) | 1 × 1 | 45 px | 32 × 77 | 32 × 77 | oui | oui |
| `lave_vaisselle` | Lave-vaisselle | 1 × 1 | 27 px | 32 × 59 | 32 × 59 | oui | oui |
| `poubelle` | Poubelle | 1 × 1 | 23 px | 32 × 55 | 32 × 55 | oui | — |

- **Miroir** : la plupart des objets sont symétriques, donc `droite` = `gauche` retourné. L'évier (cuve à gauche, égouttoir à droite) et le plan de travail (planche, bol, fruits) ne le sont pas : leur fichier `droite` est livré.
- **Micro-ondes et machine à café** : une case seule n'a pas de plan de travail. Je les ai donc posés sur un petit meuble bas de 27 px, assorti à la collection. Le micro-ondes monte à 42 px, la machine à café à 45 px.
- **En marche** (`_actif`, dans toutes les vues livrées) : cuisinière (feux rouges, porte du four orange), micro-ondes (vitre allumée et plat qui tourne), machine à café (voyant bleu et vapeur au-dessus de la tasse), lave-vaisselle (voyant vert).
- **Places à table** : les deux couverts restent face à face dans les 4 vues, en Nature (rectangulaire), en Rétro (ronde, pieds compas) et en Moderne (plateau blanc, pieds métal fins).

### Ce qui distingue les collections en trois quarts

| | Nature | Rétro | Moderne |
|---|---|---|---|
| Caissons | bois clair, poignées en bois | teck, boutons laiton ronds | blanc, poignées-barres métal |
| Plans de travail | lin `#EDE3D3` | crème `#F3E3C3` | ardoise `#4A5568` |
| Électroménager | crème, aimant feuille | crème et teal, bandeau brique | gris clair et noir, écran |
| Coins | rayon ×1 | rayon ×1,8 | rayon ×0,35 |
| Sièges | bois et coussin lin | assise ronde moutarde, pieds compas | coque blanche, dossier ardoise, pieds métal |

### Ordre d'affichage à l'intérieur d'un sprite

Les sprites restent des volumes complets (règle du lot 1). En les dessinant, j'ai appliqué un ordre plus strict : un volume posé sur un autre (micro-ondes sur son meuble, coussin sur une assise) est toujours dessiné après lui. Sinon, l'ordre suit le bas de l'emprise. Pour le jeu, rien ne change : on trie toujours les sprites par le bas de leur emprise.

## Lot 4 · La chambre et la salle de bain

Planche : « Lot 4 · Chambre et salle de bain » sur le canvas (une chambre et une salle de bain par collection, puis les 15 objets dans leurs 4 vues). Planches de contrôle : `apercu_chambre.png` et `apercu_salle_de_bain.png`. Elles remplacent les anciennes planches vue de dessus du même nom.

### Chambre

| Clé | Nom | Emprise | Hauteur | Sprite bas/haut | Sprite gauche/droite | Miroir | En marche |
|---|---|---|---|---|---|---|---|
| `lit` | Lit double | 2 × 3 | 34 px | 64 × 130 | 96 × 98 | oui | — |
| `armoire` | Armoire | 2 × 1 | 63 px | 64 × 95 | 32 × 127 | oui | — |
| `table_nuit` | Table de nuit | 1 × 1 | 25 px | 32 × 57 | 32 × 57 | oui | — |
| `bureau` | Bureau | 2 × 1 | 31 px | 64 × 63 | 32 × 95 | non (fichier droite livré) | — |
| `lit_simple` | Lit simple | 1 × 2 | 34 px | 32 × 98 | 64 × 66 | oui | — |
| `commode` | Commode | 2 × 1 | 46 px | 64 × 78 | 32 × 110 | non (fichier droite livré) | — |
| `coiffeuse` | Coiffeuse avec miroir | 2 × 1 | 58 px | 64 × 90 | 32 × 122 | non (fichier droite livré) | — |
| `lampe_chevet` | Lampe de chevet (sur guéridon) | 1 × 1 | 37 px | 32 × 69 | 32 × 69 | oui | oui |

### Salle de bain

| Clé | Nom | Emprise | Hauteur | Sprite bas/haut | Sprite gauche/droite | Miroir | En marche |
|---|---|---|---|---|---|---|---|
| `douche` | Douche | 2 × 2 | 62 px | 64 × 126 | 64 × 126 | non (fichier droite livré) | oui |
| `baignoire` | Baignoire | 3 × 2 | 27 px | 96 × 91 | 64 × 123 | non (fichier droite livré) | — |
| `toilettes` | Toilettes | 1 × 1 | 34 px | 32 × 66 | 32 × 66 | oui | — |
| `lavabo` | Lavabo | 1 × 1 | 35 px | 32 × 67 | 32 × 67 | oui | — |
| `miroir_mural` | Miroir et meuble | 2 × 1 | 60 px | 64 × 92 | 32 × 124 | non (fichier droite livré) | — |
| `machine_laver` | Machine à laver | 1 × 1 | 30 px | 32 × 62 | 32 × 62 | oui | oui |
| `panier_linge` | Panier à linge | 1 × 1 | 22 px | 32 × 54 | 32 × 54 | oui | — |

- **Lit double, Nature** : c'est le témoin du lot 1, inchangé. Le lit simple reprend sa construction avec un seul oreiller. En Rétro, le lit est sur pieds compas avec des pommeaux laiton. En Moderne, il est bas, en ardoise, avec un plaid plié au pied.
- **Lampe de chevet** : posée seule, elle n'aurait rien sous elle. Je l'ai donc mise sur un petit guéridon, comme le micro-ondes du lot 3 : rond en bois (Nature), sur pieds compas (Rétro), cube blanc (Moderne). Allumée, l'abat-jour devient jaune clair et un halo s'ajoute derrière.
- **Douche** : receveur au sol, paroi carrelée et pommeau au fond. Nature et Rétro ont un rideau sur le côté gauche, Moderne une paroi vitrée à droite. En marche : jet d'eau et vapeur. Pose-la dos au mur.
- **Machine à laver** en marche : hublot bleu avec eau qui tourne, voyant vert.
- **Miroirs** (coiffeuse, miroir et meuble) : de face, on voit le verre et son reflet. De dos, le dos du cadre. De côté, une simple tranche.
- **Pas de miroir** pour le bureau, la commode, la coiffeuse, la douche, la baignoire et le miroir et meuble : la vue `droite` est livrée.

## Lot 5 · Le salon et la déco

Planche : « Lot 5 · Salon et déco » sur le canvas (un salon par collection, puis les 13 objets). Planches de contrôle : `apercu_salon.png` et `apercu_deco.png`, qui remplacent elles aussi les anciennes.

### Salon

| Clé | Nom | Emprise | Hauteur | Sprite bas/haut | Sprite gauche/droite | Miroir | En marche |
|---|---|---|---|---|---|---|---|
| `canape` | Canapé | 3 × 2 | 32 px | 96 × 96 | 64 × 128 | oui | — |
| `tele` | Meuble TV | 3 × 1 | 44 px | 96 × 76 | 32 × 140 | oui | oui |
| `bibliotheque` | Bibliothèque | 3 × 1 | 60 px | 96 × 92 | 32 × 156 | oui | — |
| `lampe_pied` | Lampe sur pied | 1 × 1 | 61 px | 32 × 93 | 32 × 93 | oui | oui |
| `fauteuil` | Fauteuil | 1 × 1 | 31 px | 32 × 63 | 32 × 63 | oui | — |
| `table_basse` | Table basse | 2 × 1 | 19 px | 64 × 51 | 32 × 83 | non (fichier droite livré) | — |
| `cheminee` | Cheminée | 2 × 1 | 64 px | 64 × 96 | 32 × 128 | oui | oui |
| `console_jeux` | Console de jeux (sur meuble bas) | 1 × 1 | 18 px | 32 × 50 | 32 × 50 | non (fichier droite livré) | — |
| `chaine_hifi` | Chaîne hi-fi | 1 × 1 | 34 px | 32 × 66 | 32 × 66 | oui | oui |

### Déco

| Clé | Nom | Emprise | Hauteur | Sprite bas/haut | Sprite gauche/droite | Miroir | En marche |
|---|---|---|---|---|---|---|---|
| `plante` | Plante en pot | 1 × 1 | 34.0 px | 32 × 66.0 | 32 × 66.0 | oui | — |
| `tapis` | Tapis | 6 × 4 | 0 px | 192 × 128 | 128 × 192 | plat (voir plus bas) | — |
| `aquarium` | Aquarium | 2 × 1 | 48 px | 64 × 80 | 32 × 112 | oui | — |
| `horloge` | Horloge comtoise | 1 × 1 | 64 px | 32 × 96 | 32 × 96 | oui | — |

- **Canapé, meuble TV et plante, Nature** : ce sont les témoins du lot 1, inchangés. Les versions Rétro et Moderne sont nouvelles. Rétro : canapé moutarde sur pieds compas, télé cathodique crème avec antennes sur un buffet en teck. Moderne : canapé bas et anguleux sur pieds métal, écran plat sur un meuble noir.
- **En marche** : télé (écran allumé et lueur sur le meuble), lampe sur pied (abat-jour ou globe allumé, halo), cheminée (flammes et lueur au sol), chaîne hi-fi (écran allumé et notes de musique au-dessus).
- **Console de jeux** : posée sur un petit meuble bas, avec ses deux manettes devant. Les manettes n'étant pas symétriques, la vue `droite` est livrée.
- **Cheminée** : le conduit monte jusqu'à 64 px, la hauteur d'un mur plein. Pose-la contre un mur.
- **Tapis** : objet plat, sans hauteur. Seules deux vues sont livrées, `bas` et `gauche` (le tapis tourné d'un quart de tour). Comme le motif est symétrique, `haut` = `bas` et `droite` = `gauche` (marqués `identique_a` dans tokens.json). Le jeu le dessine toujours avant tout le reste de la pièce.

### Mur du bas dans les scènes d'exemple

Dans les scènes des lots 4 et 5, le mur du bas de la maison est baissé. Plein, il cachait les deux dernières rangées de meubles. C'est la règle que je propose pour le jeu : le mur le plus proche de la caméra est baissé dès qu'un personnage ou un meuble se trouve derrière lui.

### Fichiers

339 fichiers dans `svg/sprites/`, nommés `<clé>_<collection>_<vue>[_actif].svg`. Les tailles, hauteurs et décalages de chaque vue sont dans `tokens.json`, sous `vue_trois_quarts.objets`.

### Témoins du lot 1 redessinés

Huit fichiers Nature du lot 1 changent : `lit_nature_bas`, `lit_nature_haut`, `tele_nature_bas` (et `_actif`), `tele_nature_gauche` (et `_actif`), `tele_nature_haut_actif` et `canape_nature_gauche`. Les formes, couleurs et tailles ne bougent pas. Seul l'ordre de dessin change, avec la règle « posé dessus, dessiné après » du lot 3. L'ancien ordre cachait l'écran de la télé derrière son meuble, le revers de la couette du lit et les coussins du canapé vu de côté.

## Lot 6 · Les loisirs et le jardin

Planche : « Lot 6 · Loisirs et jardin » sur le canvas (une pièce de loisirs et un jardin par collection, puis les 12 objets dans leurs 4 vues). Planches de contrôle : `apercu_loisirs.png` et `apercu_jardin.png`. Elles remplacent les anciennes planches vue de dessus.

135 fichiers dans `svg/sprites/`, même nommage que les lots précédents.

### Loisirs

| Clé | Nom | Emprise | Hauteur | Sprite bas/haut | Sprite gauche/droite | Miroir | En marche |
|---|---|---|---|---|---|---|---|
| `ordinateur` | Ordinateur (sur bureau) | 2 × 1 | 50 px | 64 × 82 | 32 × 114 | non (fichier droite livré) | oui |
| `piano` | Piano | 2 × 1 | 52 px | 64 × 84 | 32 × 116 | oui | — |
| `chevalet` | Chevalet de peinture | 1 × 1 | 48 px | 32 × 80 | 32 × 80 | oui | — |
| `tapis_yoga` | Tapis de yoga | 1 × 2 | 6 px | 32 × 70 | 64 × 38 | oui | — |
| `table_jeux` | Table de jeux | 2 × 2 | 32 px | 64 × 96 | 64 × 96 | oui | — |
| `telescope` | Télescope | 1 × 1 | 48 px | 32 × 80 | 32 × 80 | non (fichier droite livré) | — |

### Jardin

| Clé | Nom | Emprise | Hauteur | Sprite bas/haut | Sprite gauche/droite | Miroir | En marche |
|---|---|---|---|---|---|---|---|
| `barbecue` | Barbecue | 1 × 1 | 48 px | 32 × 80 | 32 × 80 | oui | oui |
| `hamac` | Hamac | 3 × 1 | 38 px | 96 × 70 | 32 × 134 | oui | — |
| `balancoire` | Balançoire | 2 × 1 | 48 px | 64 × 80 | 32 × 112 | oui | — |
| `potager` | Potager | 2 × 2 | 28 px | 64 × 92 | 64 × 92 | oui | — |
| `salon_jardin` | Salon de jardin | 2 × 2 | 28 px | 64 × 92 | 64 × 92 | oui | — |
| `arbre` | Arbre | 2 × 2 | 82 px | 64 × 146 | 64 × 146 | oui | — |

- **Ordinateur** : comme le micro-ondes au lot 3, il est livré avec son bureau. La tour est posée à gauche, l'écran au fond, le clavier et la souris devant. En Rétro, c'est un écran cathodique crème. Allumé : écran bleu avec fenêtres, voyant vert sur la tour. Comme la tour est d'un seul côté, la vue `droite` est livrée.
- **Table de jeux** : deux chaises face à face, chacune avec son dossier côté extérieur. Le dossier de la chaise du fond dépasse de la table, donc les deux places restent visibles dans les 4 vues.
- **Salon de jardin** : même principe, une chaise devant, une derrière. Table ronde en Nature et Rétro, carrée en Moderne.
- **Tapis de yoga** : à plat, avec un bout roulé de 6 px au fond. Ce bout change d'une vue à l'autre, donc les 4 vues sont livrées. Il se trie comme les tapis : toujours dessous.
- **Pieds, cordes et tubes** (chevalet, télescope, barbecue, balançoire, hamac) : ils sont dessinés comme des segments entre deux points de l'objet, et non comme des boîtes. Chaque vue garde ainsi les bons angles : le chevalet penche vers le fond, le télescope vise le ciel derrière.
- **Hamac** : la toile pend entre les deux poteaux, 10 px de creux au milieu. Vu de côté, on la voit de bout.
- **Arbre** : 2 × 2 cases, le plus grand objet du jeu. Nature : feuillu rond. Rétro : arbre fruitier avec oranges. Moderne : cyprès étroit. Son ombre au sol est plus large que son emprise.
- **Barbecue** en marche : braises et viande sur la grille, fumée au-dessus.

### En marche : même taille de sprite

Un sprite `_actif` a maintenant toujours la même taille que l'objet éteint. La fumée du barbecue et les notes de la chaîne hi-fi tiennent dans une marge déjà réservée en haut de la version éteinte. Le jeu peut donc passer d'un état à l'autre sans recaler l'objet.

Ça change les 9 fichiers de la chaîne hi-fi éteinte du lot 5 : ils passent de 66 à 78 px de haut (hauteur 46 au lieu de 34), comme la version allumée. `tokens.json` est mis à jour. Les autres objets en marche des lots 3 à 5 avaient déjà la même taille dans les deux états.

## Lot 7 · Poses et finitions

Deux planches sur le canvas : « Lot 7 · Poses, places et vignettes » et « Lot 7 · Une maison par collection ». Planches de contrôle : `apercu_poses.png` (les 4 membres dans chaque pose), `apercu_places.png` (chaque objet occupé, dans ses 4 vues et ses 3 collections) et `apercu_maisons.png` (la planche finale).

### Poses

| Pose | Utilisée pour | Fichiers |
|---|---|---|
| assis | chaise, fauteuil, canapé, toilettes, table de jeux, salon de jardin | nouveaux calques de corps |
| en tailleur (`tailleur`) | tapis de yoga | nouveaux calques de corps + ombre plus large |
| à genoux (`genoux`) | potager | nouveaux calques de corps |
| allongé | lit, lit simple, baignoire, hamac | aucun : les calques debout « bas », tournés |

- **Fichiers** : 784 calques dans `svg/personnages/`, même découpage qu'au lot 2. Le nom est `corps_<sexe>_<âge>_<tenue>_<direction>_<pose>_<calque>.svg`, avec `pose` = `assis`, `tailleur` ou `genoux`, et `direction` = `bas`, `haut` ou `gauche` (`droite` = miroir). L'ombre de la pose en tailleur, plus large, est dans `ombre_<sexe>_<âge>_tailleur.svg`.
- **Tête et cheveux** : ils gardent leurs fichiers du lot 2. Le jeu les descend de `tete_dy` px (tableau ci-dessous).
- **Point d'ancrage** : toujours (16, 48) dans l'image 32 × 64. Pour ces trois poses, c'est le sol sous les hanches, et non plus sous les pieds. Assis, les pieds dépassent vers l'avant. En tailleur, les jambes croisées sont devant. À genoux, les tibias partent vers l'arrière.
- **Allongé** : je n'ai pas fait de nouveaux calques. Une personne allongée sur le dos, vue d'au-dessus, a la même silhouette que debout vue de face. Le jeu prend donc les calques debout « bas » (sans ombre) et les tourne autour du centre de la tête (`pivot`) : 0°, 90°, 180° ou 270°, dans le sens horaire.

| Âge | Hauteur des hanches assis | `tete_dy` assis | `tete_dy` tailleur | `tete_dy` genoux | Pivot allongé (y) |
|---|---|---|---|---|---|
| enfant | 3 px | 4 | 6 | 4 | 23.6 |
| ado | 6 px | 6 | 11 | 6 | 14.0 |
| adulte | 8 px | 7 | 14 | 7 | 8.5 |
| aine | 7 px | 7 | 13 | 7 | 10.3 |

### Places sur les objets

| Clé | Objet | Pose | Places |
|---|---|---|---|
| `chaise` | Chaise | assis | 1 |
| `fauteuil` | Fauteuil | assis | 1 |
| `canape` | Canapé | assis | 3 |
| `toilettes` | Toilettes | assis | 1 |
| `table_jeux` | Table de jeux | assis | 2 |
| `salon_jardin` | Salon de jardin | assis | 2 |
| `lit` | Lit double | allongé | 2 |
| `lit_simple` | Lit simple | allongé | 1 |
| `baignoire` | Baignoire | allongé | 1 |
| `hamac` | Hamac | allongé | 1 |
| `tapis_yoga` | Tapis de yoga | en tailleur | 1 |
| `potager` | Potager | à genoux | 1 |

`tokens.json` › `vue_trois_quarts.places` › `<clé>` › `<collection>` › `<vue>` donne une liste, une entrée par place :

- `pose`, et `direction` du personnage dans cette vue. Par exemple, sur la chaise vue de dos, le personnage est en direction `haut`.
- `decalage` : position du coin haut-gauche de l'image 32 × 64 du personnage, par rapport au coin haut-gauche du sprite de l'objet, **par âge**. Un enfant assis a les hanches plus bas qu'un adulte.
- pour `allonge` : `rotation`, `tete` (où poser le pivot, dans le sprite de l'objet) et `pivot` par âge.
- `devant` : nom du calque de premier plan, ou `null`.

Exemple, chaise Nature vue de face : `{"pose": "assis", "direction": "bas", "decalage": {"enfant": [0, -8], "ado": [0, -5], "adulte": [0, -3], "aine": [0, -4]}, "devant": null}`.

### Calques de premier plan (`_devant_<n>`)

Un objet est un seul sprite. Mais quand quelqu'un s'y installe, une partie de l'objet doit passer devant lui : le dossier d'une chaise vue de dos, la couette d'un lit, la table quand on est assis derrière, l'eau du bain. Pour ça, j'ai livré 126 calques `svg/sprites/<clé>_<collection>_<vue>_devant_<n>.svg` (`n` = numéro de la place, à partir de 1). Ils ont la même taille que le sprite de l'objet et se posent au même endroit.

Ordre d'affichage : **sprite de l'objet → personnage → calque devant**. L'ensemble se trie comme l'objet seul.

- **Lits** : la couette et son revers sont toujours devant. Seule la tête dépasse, sur l'oreiller.
- **Baignoire** : de l'eau translucide (82 %) couvre le corps sous les épaules.
- **Hamac** : rien devant, on est allongé sur la toile.
- **Objets en miroir** : la vue `droite` reprend la vue `gauche` retournée, comme pour les sprites. Les décalages sont recalculés (`miroir_de` dans tokens.json) et le calque devant `gauche` se retourne avec.

### Vignettes du catalogue

Elles passent à la vue bas : 150 fichiers `svg/vignettes/<clé>_<collection>.svg`, 104 × 72 (la taille de l'image de la vignette), fond transparent. L'objet est centré et mis à l'échelle pour tenir dans 96 × 64, sans dépasser ×2. Comme les sprites sont hauts, la plupart restent entre ×0,7 et ×1. Seules la table basse et la console de jeux sont agrandies (×1,25). Les plus grands sont réduits : lit et douche ×0,5, tapis ×0,5, arbre ×0,42. L'échelle de chaque objet est dans `tokens.json` › `vignettes_catalogue.echelle`.

### Planche finale

Une maison par collection, sur 22 × 15 cases : salon, cuisine, chambre des parents, chambre des enfants, salle de bain et jardin. Le mur du fond est plein, les autres sont baissés. La famille de 4 est installée avec les règles ci-dessus : Léa sur le canapé, Samir à table, Théo à l'ordinateur, Nina dans son lit. Les lampes, la télé, la cuisinière et l'ordinateur sont allumés.

## Brief n° 7 · Les étages et l'escalier

Planche : « Brief 7 · Étages et escalier » sur le canvas. Planche de contrôle : `apercu_etages.png`. On y voit une maison Nature sur deux niveaux, avec salon et cuisine en bas, deux chambres et une salle de bain en haut, et l'escalier dans l'entrée. Elle est vue au rez-de-chaussée (Léa dans l'escalier), au 1er étage, puis au 1er étage en mode Construire. Chaque vue a sa barre du haut avec le sélecteur d'étage.

Toutes les mesures sont dans `tokens.json` › `etages`.

### 1. L'escalier droit

- **Forme** : emprise 1 × 3 cases. 8 marches de 12 px de profondeur (giron) et 8 px de haut : il monte de 64 px, la hauteur d'un mur plein. La face avant est la marche du bas. Le dessous est fermé : chaque marche est un bloc plein jusqu'au fond.
- **Rampe** : du côté gauche de l'escalier. C'est le côté vu de face en vue `gauche`, ce qui permet de livrer `droite` en miroir. La main courante passe à 20 px au-dessus du nez des marches.
- **Collections** : Nature (bois clair, contremarches lin, balustres bois), Rétro (teck, tapis d'escalier orange avec barres laiton, balustres laiton), Moderne (marches gris clair et contremarches noires, rampe à câbles métal).
- **Fichiers** : `escalier_<collection>_<bas|haut|gauche>.svg` dans `svg/sprites/` (`droite` = miroir de `gauche`), et `svg/vignettes/escalier_<collection>.svg` (104 × 72).
- **Tailles** : bas et haut 32 × 182, gauche 96 × 118 (hauteur 86 avec la rampe). L'ancrage est en bas de l'emprise, comme les autres objets.
- **Vue haut** : le dos de l'escalier est un seul panneau plein. Au-dessus, on voit la rampe et les marches qui s'éloignent.

**Ligne des marches** (`ligne_marches`, en px dans l'image, pour chaque vue) : `depart` (au sol, devant la première marche), `marches` (8 points, le milieu de chaque marche, là où se posent les pieds) et `arrivee` (sur l'étage, derrière la dernière marche). Le point d'ancrage du Mouz (16, 48) suit ces points. Exemple, vue `bas` en Nature : départ [16, 190], 1re marche [16, 168.0], 8e [16, 28.0], arrivée [16, 14].

**Ce qui passe devant le Mouz** (24 calques) :
- vue `bas` : rien, le Mouz est toujours devant ;
- vue `haut` : on regarde l'escalier de dos, donc les marches au-dessus du Mouz sont plus près de la caméra. `escalier_<collection>_haut_devant_<n>.svg` contient les marches au-dessus de la marche `n` (de 1 à 7). On dessine escalier → Mouz → calque ;
- vue `gauche` : la rampe passe devant (`escalier_<collection>_gauche_devant.svg`) ; en `droite`, le même calque retourné.

### 2. Le bord d'un étage

Toutes ces pièces se dessinent **dans la case vide**, à côté de la case de sol, jamais sur le sol. (X, Y) est le coin haut-gauche de la case de sol, en pixels. Teinte unique, qui va avec les 11 sols : tranche `#CDBEA9`, bande vue de dessus `#E3D7C6`, arête éclairée `#F1E8DA`, contour `#3D3357`. Fichiers dans `svg/murs/`.

| Pièce | Taille | Position | Quand |
|---|---|---|---|
| `dalle_bord_s` | 32 × 8 | (X, Y + 32) | sous la case de sol, si la case au sud est vide |
| `dalle_bord_n` | 32 × 2 | (X, Y − 1) | sur l'arête nord de la case de sol, si la case au nord est vide |
| `dalle_bord_o` | 8 × 32 | (X − 8, Y) | à gauche de la case de sol, si la case à l'ouest est vide |
| `dalle_bord_e` | 8 × 32 | (X + 32, Y) | à droite de la case de sol, si la case à l'est est vide |
| `dalle_angle_sortant_so` | 8 × 8 | (X − 8, Y + 32) | coin sud-ouest d'un sol : vide au sud, à l'ouest et au sud-ouest |
| `dalle_angle_sortant_se` | 8 × 8 | (X + 32, Y + 32) | coin sud-est d'un sol : vide au sud, à l'est et au sud-est |
| `dalle_angle_rentrant_no` | 8 × 8 | (X, Y) | case VIDE avec du sol au nord et à l'ouest |
| `dalle_angle_rentrant_ne` | 8 × 8 | (X + 24, Y) | case VIDE avec du sol au nord et à l'est |
| `dalle_ombre_s` | 32 × 10 | (X + 3, Y + 40) | sur l'étage du dessous, sous chaque bord sud |
| `dalle_ombre_e` | 6 × 32 | (X + 40, Y + 3) | sur l'étage du dessous, à droite de chaque bord est |

- **Ordre** : les ombres juste après le voile de l'étage du dessous, puis le sol de l'étage, puis les bords, puis les murs et objets de l'étage.
- **Ombre portée** : `#2B2440` à 12 %, découpée, décalée de 3 px comme les autres ombres. Elle tombe au sud et à l'est, la lumière venant d'en haut à gauche.

**Garde-corps** : je le propose, dans les 3 collections (`svg/murs/garde_corps_<collection>_<h|v|poteau>.svg`). Bois (Nature), laiton et teck (Rétro), verre et métal (Moderne). Il fait 22 px de haut et se pose sur la ligne du bord, comme un mur. Le jeu le place automatiquement autour de la cage d'escalier, sauf du côté de l'arrivée, et au bord des trous. Pas de garde-corps là où il y a déjà un mur.

| Pièce | Taille | Position (nœud X, Y) | Tri |
|---|---|---|---|
| `garde_corps_<collection>_h` | 32 × 26 | (X, Y − 2 − 22) | Y + 2 |
| `garde_corps_<collection>_v` | 4 × 54 | (X − 2, Y − 22) | Y + 32 |
| `garde_corps_<collection>_poteau` | 6 × 30 | (X − 3, Y − 3 − 24) | Y + 3 |

**Le vide en mode Construire** (`svg/sols/`, 32 × 32, par-dessus l'étage du dessous assombri) :
- `vide_constructible.svg` : au-dessus d'une pièce fermée, sans sol encore. Vert doux à 60 %, pointillé vert, petit « + ».
- `vide_interdit.svg` : partout ailleurs (jardin, cage d'escalier). Hachures légères à 22 % sur un voile à 10 %.

### 3. Les Mouz dans l'escalier

- **De profil** (escalier vu en `gauche` ou `droite`) : nouvelles images. Deux pour monter (pied avant sur la marche du dessus, puis passage), deux pour descendre (pied avant qui descend, puis passage). Les fichiers sont `corps_<sexe>_<âge>_<tenue>_gauche_<monter|descendre>_<1|2>_<calque>.svg` (352 calques, même découpage qu'au lot 2), avec `droite` en miroir. La tête et les cheveux gardent leurs fichiers : `tete_dy` vaut 0 pour l'image 1 et −1 pour l'image 2.
- **De face et de dos** (escalier vu en `bas` ou `haut`) : **les images de marche du lot 2 suffisent**. Une marche de face monte de 20 px à l'écran (12 de profondeur + 8 de hauteur), et le pas se voit à peine à cette échelle. Le Mouz saute d'un point de `ligne_marches` au suivant, en alternant `_marche_1` et `_marche_2`. En vue `bas`, il monte en direction `haut` (on voit son dos) et descend en direction `bas`. C'est l'inverse en vue `haut`.
- **Pas d'ombre** dans l'escalier : l'ombre au sol n'a pas de sens sur des marches.
- **Étage regardé** : un Mouz dans l'escalier fait partie de l'étage du bas jusqu'à la dernière marche. Au 1er étage, on le voit donc assombri dans la cage d'escalier.

### 4. L'interface

- **Sélecteur d'étage** : dans la barre du haut, juste après les onglets Vivre / Construire / Acheter. C'est une pastille `papier_2` de 44 px de haut, avec le bouton descendre, le nom de l'étage (Baloo 2, 17 px, 800) et le bouton monter. Trois points empilés montrent l'étage regardé parmi les trois. Les boutons font 32 × 32, rayon 9 :
  - normal : transparent ;
  - survol : blanc, anneau `accent` 2 px ;
  - pressé : fond `contour`, icône `papier` ;
  - désactivé : opacité 35 % (descendre au rez-de-chaussée, monter au 2e).
- **Version compacte** : la même pastille avec seulement « RDC », « 1er » ou « 2e » (18 px) entre les deux boutons.
- **Icônes** : `etage_monter`, `etage_descendre` et `escalier`, en encre et en blanc, dans `svg/icones/`.
- **Voile des étages du dessous** : uni, `#2B2440`, sans flou ni désaturation. 45 % pour l'étage juste en dessous, 60 % pour deux étages plus bas (au 2e étage, le rez-de-chaussée). Il couvre tout l'étage du dessous ; l'étage regardé se dessine ensuite par-dessus.
- **Repère d'étage sur les portraits** : une pastille `contour` de 18 px de haut, avec le texte `papier` 11 px 800 (« RDC », « 1er », « 2e »). Elle se pose à −6, −6 du coin haut-gauche du portrait, avec un liseré `papier` de 2 px. Elle s'affiche seulement quand le Mouz n'est pas à l'étage regardé. Pour un Mouz dans l'escalier, elle s'affiche toujours, avec la petite icône escalier et l'étage vers lequel il va.
