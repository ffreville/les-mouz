# Brief n° 9 pour Claude Design : les coups durs, les saisons et la météo

Même direction artistique « Maison de poche » (`design/README.md`) et mêmes règles de la **vue trois quarts** que les briefs n° 6 à 8 :
- cases de 32 × 32 px ;
- ce qui a de la hauteur monte vers le haut de l'écran (1 m ≈ 32 px), avec l'ancrage en bas de l'emprise ;
- contour encre 2 px `#3D3357` (détails 1,5 px), aplats sans dégradé, ombre découpée ;
- 4 vues nommées selon le côté où regarde la face avant ;
- noms de fichiers en français, minuscules, sans accents, avec des tirets bas.

La livraison se fait dans `design/` comme d'habitude : sprites, sols, personnages, icônes, `README.md`, `tokens.json` et une planche PNG.

Tout ce qui suit marche déjà dans le jeu avec des dessins provisoires (formes simples, teintes posées par-dessus). Les noms de fichiers ci-dessous sont **ceux que le jeu cherche** : dès qu'un fichier existe, il remplace le dessin provisoire.

## 1. Les coups durs

### Ce que fait le jeu

- **Le feu.** En cuisinant mal, ou sur un appareil usé, la cuisinière ou le barbecue prend feu. Les flammes gagnent les meubles voisins. Un Mouz peut « Éteindre le feu », sinon les pompiers viennent et envoient leur facture. Ce qui a brûlé tombe en panne. Pendant un orage, la foudre peut aussi enflammer un arbre.
- **L'inondation.** Une machine à laver ou un lave-vaisselle usé fuit et laisse des flaques autour de lui. On clique sur une flaque pour l'« Éponger ».
- **Le cambriolage.** La nuit, un cambrioleur arrive par la rue, va jusqu'à un objet (télé, ordinateur, console, lampe…), le prend et repart. Une alarme le fait fuir.
- **La catégorie « Sécurité »** du catalogue (Acheter) contient le détecteur de fumée, l'extincteur et l'alarme.

### À dessiner

- **Flammes** : `sprites/feu_1.svg`, `feu_2.svg` et `feu_3.svg`. Ce sont 3 images qui bouclent (une flamme qui danse, un peu de fumée au-dessus), de 32 px de large et d'environ 48 px de haut.
  - Le jeu en pose une par case de largeur de l'objet.
  - Il place le bas de l'image à 30 % de la hauteur de l'objet en partant de son sommet, pour que les flammes sortent du dessus du meuble.
  - Elles doivent rester lisibles sur une cuisinière, un canapé et un arbre.
- **Détecteur de fumée** : 1 × 1, posé contre un mur. Il occupe sa case : dessine-le sur une petite console ou un pied, à hauteur de plafond.
- **Extincteur** : 1 × 1, rouge, sur son support.
- **Alarme antivol** : 1 × 1, un boîtier à clavier sur un pied ou une console, avec un voyant.
- Pour ces trois objets, il faut :
  - les **3 collections** (Nature, Rétro, Moderne) et les **4 vues** : `<id>_<collection>_<haut|bas|gauche>.svg`, et `_droite` seulement si l'objet n'est pas symétrique ;
  - l'image vue de dessus `<id>_<collection>.svg` (32 × 32) ;
  - les vignettes du catalogue `vignettes/<id>_<collection>.svg` (104 × 72).
  - Les identifiants sont `detecteur_fumee`, `extincteur` et `alarme`.
- **Flaque** : `sprites/flaque.svg`, 32 × 32, vue à plat sur le sol, sans contour épais. Elle doit se lire sur du parquet, du carrelage et de l'herbe.
- **Le cambrioleur** : un accessoire posé par-dessus un Mouz adulte en pull foncé.
  - C'est un bonnet noir avec un masque sur les yeux, et un sac sur l'épaule.
  - Un calque par vue : `personnages/accessoire_cambrioleur_adulte_<bas|haut|gauche>.svg`, en couleurs (pas de teinte), au cadre et à l'ancrage des calques du corps (32 × 64, pieds à 48 px du haut).
  - Il doit aller aux deux sexes. La vue `droite` est la vue `gauche` retournée.
- **Icônes** 24 × 24, encre et blanc :
  - `securite` (catégorie du catalogue) ;
  - `eteindre_feu` (action) ;
  - `eponger` (action) ;
  - `feu`.

## 2. Les saisons et la météo

### Ce que fait le jeu

- **Le calendrier.** L'année a 4 saisons de 7 jours : printemps, été, automne, hiver. Le temps change toutes les 6 heures : soleil, nuageux, pluie, orage, neige (l'hiver) ou canicule (l'été). L'horloge affiche la saison, une icône du temps et la température, et son infobulle donne les prévisions.
- **Le ciel.** Il s'assombrit sous les nuages et la pluie. La pluie et les flocons tombent à l'écran (le jeu les dessine lui-même), et l'orage fait des éclairs.
- **Le sol.** L'herbe change de teinte selon la saison. La neige tient au sol et couvre tout ce qui est dehors (herbe, terrasse, allées), puis fond quand elle s'arrête.
- **Le bonhomme de neige.** Avec assez de neige, un Mouz peut faire un bonhomme de neige dans le jardin. Le jeu le fait monter de bas en haut pendant les 45 minutes de l'action, et il fond avec la neige.

### À dessiner

- **Herbe des saisons** : `floors/herbe_ete.svg` (herbe sèche, blonde), `floors/herbe_automne.svg` (herbe rousse, quelques feuilles tombées) et `floors/herbe_hiver.svg` (herbe terne, givrée). Ce sont des tuiles de 32 × 32, raccordables, sans contour, dans l'esprit de la tuile d'herbe actuelle (le printemps garde celle-ci).
- **Neige au sol** : `floors/neige.svg`, une tuile de 32 × 32 raccordable, blanche avec quelques creux bleutés. Le jeu la pose par-dessus le sol avec plus ou moins de transparence selon l'épaisseur : elle doit rester belle à moitié transparente.
- **L'arbre en saisons** : `sprites/arbre_<collection>_<vue>_<saison>.svg`, pour `printemps` (en fleurs), `ete` (feuillage plein), `automne` (feuillage roux et doré) et `hiver` (branches nues avec un peu de neige). Les 3 collections et les vues existantes de l'arbre (`haut`, `bas`, `gauche`), au même cadre que l'arbre actuel.
- **Bonhomme de neige** : `sprites/bonhomme_neige_nature_bas.svg` (1 × 1, environ 32 × 64, de face : trois boules, chapeau, écharpe, nez en carotte, bras en branches). Il est dessiné à la verticale. Une vue `_gauche` est bienvenue.
- **Icônes** 24 × 24, encre et blanc :
  - le temps : `soleil`, `nuages`, `pluie`, `orage`, `neige`, `canicule` ;
  - les saisons : `printemps`, `ete`, `automne`, `hiver` ;
  - l'action : `bonhomme_neige`.

## 3. La planche de contrôle

`design/apercu_coups_durs_saisons.png` doit montrer :
- une cuisine en feu (la cuisinière et le plan de travail voisin), un Mouz qui l'éteint à côté de l'extincteur, et le détecteur au mur ;
- une buanderie avec des flaques autour de la machine à laver ;
- le cambrioleur de nuit dans le salon, près de la télé, avec l'alarme au mur ;
- le même jardin (arbre, potager, terrasse, piscine) aux 4 saisons, avec la neige au sol en hiver et un bonhomme de neige.
