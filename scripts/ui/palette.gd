extends Node
## Autoload « Palette » : couleurs et mesures de la direction artistique « Maison de poche ».
## Source : design/tokens.json et design/README.md.
## Les couleurs propres à un besoin, un objet ou un personnage sont dans leurs Resources (data/).

# --- Interface ---------------------------------------------------------------
const ENCRE := Color("#2B2440")
const ENCRE_DOUCE := Color("#5E5675")
const CONTOUR := Color("#3D3357")
const PAPIER := Color("#FFF8EE")
const PAPIER_2 := Color("#F6EBDD")
const TRAIT := Color("#E3D5C0")
const PISTE := Color("#EFE4D4")
const ACCENT := Color("#E8794A")
const ACCENT_TEXTE := Color("#A8461F")
const ACCENT_DOUX := Color("#FDE7DB")
const CRITIQUE := Color("#B3261E")
const CRITIQUE_DOUX := Color("#F9D9D6")
const OMBRE := Color(0.169, 0.141, 0.251, 0.12)

# --- Maison ------------------------------------------------------------------
const JARDIN := Color("#A7C796")
const JARDIN_POINT := Color("#98BC86")
const MUR := Color("#5B4E72")
const SEUIL := Color("#C9A27E")
## Épaisseur des murs, en pixels.
const EPAISSEUR_MUR := 8.0

# --- Mesures de l'interface --------------------------------------------------
const RAYON_PANNEAU := 16
const RAYON_MENU := 14
const RAYON_ELEMENT := 12
const RAYON_BOUTON := 8
const RAYON_BARRE := 5
const MARGE_PANNEAU := 16

# --- États des besoins -------------------------------------------------------
const SEUIL_CRITIQUE := 20.0
const SEUIL_BAS := 40.0


## « critique », « bas » ou « normal » selon la valeur d'un besoin (0 à 100).
static func etat_besoin(valeur: float) -> String:
	if valeur < SEUIL_CRITIQUE:
		return "critique"
	if valeur < SEUIL_BAS:
		return "bas"
	return "normal"


## Humeur en mots : Grognon, Bof, Content, Radieux.
static func mot_humeur(valeur: float) -> String:
	if valeur < 30.0:
		return "Grognon"
	if valeur < 50.0:
		return "Bof"
	if valeur < 70.0:
		return "Content"
	return "Radieux"


## Palier de relation : Ennemis, Froids, Neutres, Copains, Inséparables.
static func palier_relation(valeur: float) -> String:
	if valeur < -50.0:
		return "Ennemis"
	if valeur < -10.0:
		return "Froids"
	if valeur <= 10.0:
		return "Neutres"
	if valeur <= 50.0:
		return "Copains"
	return "Inséparables"
