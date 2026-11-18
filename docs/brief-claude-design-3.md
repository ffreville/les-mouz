# Brief n° 3 pour Claude Design : « Les Mouz », écrans des parties et des sauvegardes

Même direction artistique « Maison de poche » que les deux premiers lots (maquettes : https://claude.ai/artifact/UXdkDt3fTCFtjiGrQ62zEE) : même palette, Baloo 2 + Nunito, aplats, contour encre 2 px `#3D3357`, ombre découpée, jamais la couleur seule.

Le jeu gère maintenant **plusieurs parties enregistrées**. Les écrans ci-dessous existent déjà, construits avec les composants actuels (panneaux papier, boutons des maquettes précédentes), mais ils n'ont pas été dessinés. J'aimerais qu'ils aient la même qualité que le reste.

## Ce qui existe aujourd'hui

1. **Écran d'accueil** (au lancement) : fond d'herbe, carte centrale avec les deux Mouz, le logo « Les Mouz », la phrase « Une maison de poche à construire », puis les boutons :
   - « Continuer : *nom de la dernière partie* » (bouton principal, encre) ;
   - « Nouvelle partie » → la carte affiche un champ « Nom de la partie » (prérempli « La maison de Pépin et Myrtille »), la phrase « Un terrain vide et 20 000 Mz pour construire », et les boutons Retour / Commencer ;
   - « Charger une partie » ;
   - « Quitter ».
2. **Écran Charger une partie** (depuis l'accueil et depuis le menu en jeu) : une liste de cartes, une par partie :
   - vignette du terrain vu d'en haut (320 × 180, affichée en 160 × 90) ;
   - nom de la partie (et « (en cours) » pour la partie ouverte, carte encadrée d'accent) ;
   - « Jour 3 · 18:40 · 18 800 Mz · 13 objets » ;
   - « Enregistrée il y a 5 min » ;
   - boutons Charger / Renommer / Supprimer. « Renommer » remplace les boutons par un champ de texte + OK / Annuler ; « Supprimer » par « Supprimer définitivement ? » + Supprimer (rouge) / Garder.
3. **Menu en jeu** (Échap, ou clic sur le logo) : voile sombre sur le jeu, carte centrale avec le nom de la partie, « Jour 3 · 18:40 · 18 800 Mz », puis Reprendre (principal), Sauvegarder (Ctrl+S), Sauvegarder sous…, Charger une partie…, Menu principal, Quitter le jeu. « Sauvegarder sous… » affiche un champ « Nom de la copie » + Retour / Enregistrer.
4. **Message de confirmation** en bas au centre : « Partie enregistrée », « Copie enregistrée : *nom* » ou « La sauvegarde a échoué », qui disparaît après 2 secondes.

## Ce que j'attends

- Les **maquettes 1280 × 720** de ces quatre écrans et de leurs états (accueil sans aucune partie, accueil avec une partie, liste vide, liste avec 4 parties dont une en cours, renommage en cours, confirmation de suppression, sauvegarde réussie et échouée).
- Une proposition pour rendre l'**accueil** plus vivant : par exemple la vignette de la dernière partie en grand derrière la carte, ou une petite scène de jardin avec les Mouz.
- Les **composants** avec toutes leurs mesures (comme dans les README précédents) : carte de partie, champ de texte (normal, focus, erreur si le nom est vide), bouton principal / secondaire / destructif, message de confirmation (succès, échec).
- Les **icônes** manquantes (24 × 24, versions `encre` et `blanc`) : sauvegarder, charger, renommer, supprimer, menu, quitter, continuer.
- Un état « **partie abîmée** » pour une carte dont la sauvegarde ne se lit plus (message et action possible).

## Format de livraison

Comme les fois précédentes, dans le dossier `design/` : SVG dans `svg/icones/encre/` et `svg/icones/blanc/`, mesures dans `README.md` et `tokens.json`, et une planche de contrôle PNG. Noms de fichiers en français, en minuscules, sans accents, avec des tirets bas.
