# Brief n° 5 pour Claude Design : « Les Mouz », des humains et l'écran de création de famille

Même direction artistique « Maison de poche » que les lots précédents (maquettes : https://claude.ai/artifact/UXdkDt3fTCFtjiGrQ62zEE, référence complète dans `design/README.md`). > **Ce brief est le lot 2 du brief n° 6** : le jeu passe en vue trois quarts (`docs/brief-claude-design-6.md`). Les personnages se dessinent donc selon les règles de cette vue, validées au lot 1.

Mêmes règles : aplats, contour encre 2 px `#3D3357` (détails 1,5 px), pas de dégradé, grille de 32 px par case, Baloo 2 + Nunito, ombre découpée, jamais la couleur seule pour porter une information.

Deux grands changements :

1. **Les Mouz deviennent des humains.** Les petites boules à oreilles disparaissent. « Mouz » reste le nom qu'on donne aux habitants du jeu, mais ce sont maintenant des personnes : hommes et femmes, de plusieurs âges.
2. **Le joueur crée sa famille** avant de choisir son terrain. La famille compte de 1 à 4 personnes, avec un nom de famille et un prénom pour chacun.

## 1. Les personnages, en vue trois quarts

Dans le jeu, un personnage se tient sur **une case de 32 × 32** et monte vers le haut de l'écran (un adulte fait environ 48 px de haut, à confirmer au lot 1). Il est dessiné dans **4 directions** : `bas` (face à nous), `haut` (de dos), `gauche` et `droite` (`droite` peut être le miroir de `gauche`). On doit reconnaître d'un coup d'œil qui est qui, dans chaque direction.

### Des calques à assembler

Le joueur choisit l'apparence de chacun : les sprites doivent donc être **découpés en calques** que le jeu superpose et colore lui-même.

| Calque | Variantes | Couleur |
|---|---|---|
| Corps (épaules, bras, mains) | homme, femme, pour chaque tranche d'âge | peau (mains) + tenue (haut) |
| Tête | une par tranche d'âge | peau |
| Coiffure | au moins 6 coupes par sexe, adaptées à chaque âge (crâne dégarni, chignon, couettes…) | cheveux |
| Contour et détails | un par calque | encre, fixe |

- Les zones à colorer sont dessinées en **blanc pur** (`#FFFFFF`), chacune dans son propre fichier, pour que le jeu les teinte. Le contour encre et les petits détails fixes (ombre découpée, plis) sont dans un fichier séparé, posé par-dessus.
- Propose les **palettes de choix** : 6 à 8 teintes de peau (de très claire à très foncée), 8 couleurs de cheveux (dont gris et blanc pour les aînés, et 2 couleurs fantaisie), 10 couleurs de tenue prises dans la palette du jeu.
- Si une seule tenue par sexe et par âge suffit, garde-la simple ; si tu as le temps, 2 ou 3 formes de tenue (t-shirt, robe, salopette, veste…).
- Chaque calque existe dans les 4 directions, debout et en **marche** (2 images où les bras et les pieds alternent), nommées `_<direction>`, `_<direction>_marche_1` et `_<direction>_marche_2`.

### Les tranches d'âge

| Clé | Tranche | Hauteur à l'écran |
|---|---|---|
| `enfant` | Enfant | environ 32 px |
| `ado` | Adolescent | environ 42 px |
| `adulte` | Adulte | environ 48 px |
| `aine` | Aîné | environ 46 px, épaules un peu voûtées |

Pas de bébé pour l'instant. Propose une limite simple si besoin, par exemple « il faut au moins un adulte ou un aîné dans la famille », et montre l'état d'erreur correspondant.

### Les portraits

L'interface affiche des portraits (panneau du personnage en 64 px, sélecteur de personnage et panneau de relation en 32 px, écran de création en grand). Pour eux, une **vue de face, tête et épaules**, plus grande et plus détaillée que le sprite, avec les mêmes couleurs, pour qu'on fasse le lien. Fichiers séparés : `portrait_*`.

## 2. L'écran de création de famille

Le parcours d'une nouvelle partie devient : **Accueil → Nouvelle partie → Créer la famille → Choisir le terrain → jeu**.

Ce que l'écran doit permettre :

- **Nom de famille** (champ texte, prérempli au hasard, par exemple « Famille Lambert »). Il sert aussi de nom par défaut à la partie.
- **De 1 à 4 membres**, chacun sur une carte avec son portrait. Un emplacement vide « + Ajouter un membre » tant qu'on n'en a pas 4. Chaque carte peut être retirée (sauf la dernière).
- Pour le membre choisi :
  - **prénom** (champ texte, avec un bouton dé pour en tirer un au hasard) ;
  - **homme / femme** ;
  - **tranche d'âge** (enfant, ado, adulte, aîné) ;
  - **apparence** : peau, coupe de cheveux, couleur des cheveux, tenue, couleur de la tenue ;
  - un bouton **« Au hasard »** qui tire toute l'apparence d'un coup.
- Un grand **aperçu** du membre choisi : son portrait, et à côté le sprite du jeu, à taille réelle ×2, qui marche sur place en passant par ses 4 directions.
- Si tu le juges utile, le **lien** entre deux membres (couple, parent et enfant, frères et sœurs, colocataires). Il fixerait la relation de départ. Dis-moi si ça alourdit trop l'écran.
- Boutons **Retour** et **Choisir le terrain** (principal, désactivé tant qu'un prénom est vide, avec la raison affichée).

### Choisir le terrain

L'écran suivant présente **2 ou 3 terrains** sur des cartes : vignette vue d'en haut, nom, taille en cases, prix, et « Terrain vide » ou « Maison meublée ». La famille en haut de l'écran (portraits en ligne + nom), le solde de départ, et les boutons Retour / Emménager. Je fournirai les terrains : dessine les cartes avec des vignettes d'exemple.

## 3. Ce qui vient plus tard (à ne pas dessiner, mais à prévoir)

Ces mécaniques ne sont pas pour maintenant. Garde-les en tête pour que le système de personnages et l'écran de création puissent les accueillir sans tout refaire :

- **Vieillir** : les Mouz passeront d'une tranche d'âge à la suivante. Les calques doivent donc rester cohérents d'un âge à l'autre (même coupe de cheveux disponible à tous les âges quand c'est possible).
- **Devenir un robot** : un Mouz pourra se faire transformer en robot pour ne plus vieillir. En échange, il devra passer régulièrement en **révision**. Il gardera sans doute sa silhouette avec un aspect métallique et quelques détails mécaniques.
- **Devenir une IA** : un Mouz pourra quitter son corps pour devenir l'**IA de la maison** et piloter la domotique (allumer, régler, surveiller). Il n'aurait plus de sprite mais une présence dans les objets et l'interface.

Dans le README, une demi-page d'**idées visuelles** pour ces trois cas suffit : où ils trouveraient leur place dans l'écran de création et dans le panneau du personnage. Pas de sprites.

## Ce que j'attends

### Sprites et portraits

- Calques du corps, de la tête et des coiffures pour les 4 tranches d'âge et les 2 sexes, plus le calque de contour de chacun, dans `svg/personnages/` :
  - `corps_<sexe>_<age>.svg`, `corps_<sexe>_<age>_contour.svg`, et `_marche_1` / `_marche_2` si tu les fais ;
  - `tete_<age>.svg` ;
  - `cheveux_<coupe>_<age>.svg` ;
  - `portrait_…` sur le même principe.
- Un tableau des **ancrages** dans le README : où se pose chaque calque par rapport à la case, pour chaque direction, et dans quel ordre on les empile (la coiffure passe derrière la tête en vue `haut`, par exemple).
- Les palettes de peau, cheveux et tenues dans `tokens.json`.

### Interface

Avec les mesures de chaque composant, comme dans les README précédents :

- Maquettes 1280 × 720 de l'**écran de création** : famille d'un seul membre, famille complète de 4, un champ de prénom vide (erreur), la règle « au moins un adulte » non respectée.
- Maquette 1280 × 720 de l'écran **Choisir le terrain**.
- Composants : carte de membre (normale, choisie, vide « + Ajouter »), sélecteur à pastilles (peau, couleurs), sélecteur de coupe avec aperçu, interrupteur homme / femme, sélecteur d'âge, bouton dé, carte de terrain.
- Icônes 24 × 24 (trait 2 px, versions `encre` et `blanc`) : homme, femme, enfant, ado, adulte, aîné, hasard (dé), ajouter un membre, retirer, famille, terrain, emménager.
- Une planche montrant les **anciens écrans avec des humains** : le HUD en jeu (panneau du personnage, sélecteur, relation), l'étiquette de nom et l'anneau de sélection autour d'un humain, et une maison meublée avec une famille de 4 qui vit dedans.

Le brief n° 3 (accueil, chargement, menu en jeu) n'a pas encore été envoyé : si tu le reçois en même temps, dessine l'accueil avec la nouvelle famille d'humains plutôt qu'avec les anciens Mouz.

## Format de livraison

Comme les fois précédentes, dans le dossier `design/` : calques dans `svg/personnages/`, icônes dans `svg/icones/encre/` et `svg/icones/blanc/`, mesures et tableaux dans `README.md` et `tokens.json`, et des planches de contrôle PNG (`apercu_personnages.png` avec toutes les combinaisons âge × sexe dans quelques couleurs, `apercu_creation_famille.png`). Noms de fichiers en français, en minuscules, sans accents, avec des tirets bas.
