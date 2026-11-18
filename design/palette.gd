# Palette de « Les Mouz », générée depuis design/tokens.json.
# Utilisation : ajoute ce script en autoload nommé Palette, puis Palette.ENCRE, Palette.besoin("faim")...
extends Node

const ENCRE := Color("#2B2440")
const ENCRE_DOUCE := Color("#5E5675")
const CONTOUR := Color("#3D3357")
const PAPIER := Color("#FFF8EE")
const PAPIER_2 := Color("#F6EBDD")
const TRAIT := Color("#E3D5C0")
const ACCENT := Color("#E8794A")
const ACCENT_TEXTE := Color("#A8461F")
const ACCENT_DOUX := Color("#FDE7DB")
const CRITIQUE := Color("#B3261E")
const CRITIQUE_DOUX := Color("#F9D9D6")
const PISTE := Color("#EFE4D4")
const SALON := Color("#E8CBA4")
const SALON_LIGNE := Color("#DDBA8F")
const CUISINE := Color("#D3E7DD")
const CUISINE_2 := Color("#C6DFD2")
const CHAMBRE := Color("#DCCFEB")
const CHAMBRE_POINT := Color("#CDBDE2")
const SDB := Color("#D2E6F3")
const SDB_JOINT := Color("#BCD6E8")
const JARDIN := Color("#A7C796")
const JARDIN_POINT := Color("#98BC86")
const MUR := Color("#5B4E72")
const SEUIL := Color("#C9A27E")
const BOIS := Color("#A47E63")
const BOIS_FONCE := Color("#7C5D49")
const BOIS_LIGNE := Color("#8E6A51")
const CREME := Color("#F7F3EC")
const CREME_OMBRE := Color("#DCD5C8")
const TISSU := Color("#6FA3A0")
const TISSU_FONCE := Color("#5E918E")
const TISSU_CLAIR := Color("#8CC0BC")
const FAIENCE := Color("#EAF4FA")
const EAU := Color("#D2E8F5")
const EAU_TRAIT := Color("#A9CBE0")
const METAL := Color("#8E99A6")
const FEUILLE := Color("#7DB36A")
const FEUILLE_FONCE := Color("#4F8A43")
const TERRE_CUITE := Color("#C97B5A")
const TERREAU := Color("#6B4E3D")
const TAPIS := Color("#E7A88D")
const TAPIS_BORD := Color("#F3CDB9")
const PEPIN := Color("#F2A56B")
const MYRTILLE := Color("#A3B5EC")
const OREILLE := Color("#F6B8C4")
const TRUFFE := Color("#D9667E")

const BESOINS := {
	"faim": {"nom": "Faim", "couleur": Color("#D55E00"), "fond": Color("#FBE3D3")},
	"energie": {"nom": "Énergie", "couleur": Color("#E8B100"), "fond": Color("#FBF0C7")},
	"hygiene": {"nom": "Hygiène", "couleur": Color("#3E9BD6"), "fond": Color("#DCEDF8")},
	"social": {"nom": "Social", "couleur": Color("#C46BA0"), "fond": Color("#F4DFEC")},
	"plaisir": {"nom": "Plaisir", "couleur": Color("#0E9C74"), "fond": Color("#D3EFE5")},
	"humeur": {"nom": "Humeur", "couleur": Color("#6C5BB3"), "fond": Color("#E6E1F5")},
}

const SEUIL_CRITIQUE := 20
const SEUIL_BAS := 40
const CASE := 32
const MUR := 8

## Renvoie "critique", "bas" ou "normal" selon la valeur du besoin (0 à 100).
static func etat_besoin(valeur: float) -> String:
	if valeur < SEUIL_CRITIQUE:
		return "critique"
	if valeur < SEUIL_BAS:
		return "bas"
	return "normal"

static func besoin(cle: String) -> Dictionary:
	return BESOINS.get(cle, {})
