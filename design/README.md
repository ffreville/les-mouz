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
