# Brief pour Claude Design — « Les Mouz »

Je développe **Les Mouz**, un petit jeu de simulation de vie en 2D vue de dessus (Godot 4, GDScript). Pour l'instant, tout est en formes de couleur unies. J'ai besoin d'une **direction artistique originale** et de **maquettes d'interface** que je pourrai ensuite reproduire dans Godot.

## Le jeu en bref

- Une maison vue de dessus, sur une grille de cases de 32 px : salon, cuisine, chambre, salle de bain, séparés par des murs avec des portes.
- Deux personnages (les « Mouz ») qui vivent dedans. On en sélectionne un d'un clic pour le contrôler.
- Chaque Mouz a 5 besoins de 0 à 100 : **Faim, Énergie, Hygiène, Social, Plaisir**, plus une **humeur** générale.
- Des objets interactifs : frigo, lit, douche, canapé + TV, bibliothèque. Un clic sur un objet ouvre un **menu contextuel** avec ses actions (« Manger », « Dormir », « Se laver », « Regarder la TV », « Lire »).
- Les actions choisies s'ajoutent à une **file d'actions** visible à l'écran, chacune annulable.
- Un clic sur l'autre Mouz propose « Discuter ». Une **relation** de −100 à 100 évolue entre eux.
- Une **horloge** (jour + heure) et des boutons de vitesse **Pause / x1 / x2 / x3**.
- Une case à cocher « Autonomie » pour laisser le Mouz décider seul.

## Ce que j'attends

1. **Direction artistique** : une identité propre et chaleureuse, lisible en vue de dessus. Pas de copie du style des Sims ni d'un autre jeu existant. Propose une palette (sols par pièce, murs, objets, personnages, interface) avec les codes hexadécimaux.
2. **Maquette de l'écran de jeu** (1280 × 720) montrant la maison entière, les deux Mouz, et le HUD complet :
   - en haut : horloge + boutons de vitesse + case « Autonomie » ;
   - à gauche ou en bas : portrait/nom du Mouz sélectionné, 5 barres de besoins + humeur ;
   - à droite : file d'actions (icône, nom, progression, bouton ✕) ;
   - un panneau compact de relation entre les deux Mouz.
3. **Composants d'interface isolés** : barre de besoin (états normal, bas, critique), menu contextuel ouvert sur un objet, élément de la file d'actions (en attente, en cours), boutons de vitesse (normal, actif, survol).
4. **Objets et personnages vus de dessus** : un visuel simple pour chacun des 5 objets et pour un Mouz (avec une variante de couleur pour le second). Ils doivent rester lisibles à 32–64 px.
5. **Icônes** pour les 5 besoins et pour les actions.

## Contraintes

- 2D vue de dessus stricte (pas d'isométrique), alignée sur une grille de 32 px.
- Formes simples et aplats, faciles à reproduire avec des Polygon2D / StyleBoxFlat dans Godot ou à exporter en SVG.
- Texte de l'interface en français, police lisible à petite taille (Google Fonts acceptées).
- Les couleurs des besoins doivent rester distinguables pour les daltoniens (ne pas reposer uniquement sur rouge/vert).
- Indique les tailles, marges, rayons d'angle et couleurs de chaque composant pour que je puisse les reproduire fidèlement.
