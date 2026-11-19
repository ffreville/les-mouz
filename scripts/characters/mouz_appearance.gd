class_name MouzAppearance
extends Resource
## Apparence d'un Mouz : sexe, âge, peau, coupe et couleur des cheveux, tenue.
## Sait lister les calques à superposer (sprite en jeu et portrait) avec leur teinte.
## Les zones à teinter sont blanches dans les SVG : le jeu les colore par `modulate`.

const FOLDER := "res://assets/personnages/"
const SEXES: Array[StringName] = [&"homme", &"femme"]
const AGES: Array[StringName] = [&"enfant", &"ado", &"adulte", &"aine"]
const AGE_NAMES := {&"enfant": "Enfant", &"ado": "Ado", &"adulte": "Adulte", &"aine": "Aîné"}
const SEX_NAMES := {&"homme": "Homme", &"femme": "Femme"}
const OUTFITS: Array[StringName] = [&"tshirt", &"pull", &"robe"]
const OUTFIT_NAMES := {&"tshirt": "T-shirt", &"pull": "Pull", &"robe": "Robe"}
const HAIR_STYLES: Array[StringName] = [&"court", &"rase", &"meche", &"boucles", &"afro", &"degarni",
		&"longs", &"carre", &"chignon", &"couettes", &"queue"]
const HAIR_NAMES := {&"court": "Court", &"rase": "Rasé", &"meche": "Mèche", &"boucles": "Boucles",
		&"afro": "Afro", &"degarni": "Dégarni", &"longs": "Longs", &"carre": "Carré",
		&"chignon": "Chignon", &"couettes": "Couettes", &"queue": "Queue"}
## Coupes proposées d'abord selon le sexe (toutes restent disponibles).
const HAIR_BY_SEX := {
	&"homme": [&"court", &"rase", &"meche", &"boucles", &"afro", &"degarni", &"queue"],
	&"femme": [&"longs", &"carre", &"chignon", &"couettes", &"queue", &"boucles", &"afro", &"meche"],
}
## Coupe qui n'existe pas à certains âges, et celle qui la remplace.
const HAIR_MIN_AGE := {&"degarni": &"adulte"}
const HAIR_FALLBACK := &"court"

const SKINS := {"porcelaine": Color("#FBE3D2"), "claire": Color("#F3CDB0"), "doree": Color("#E5B48C"),
		"miel": Color("#D39A6A"), "caramel": Color("#B77B4E"), "cannelle": Color("#97603A"),
		"cacao": Color("#764528"), "ebene": Color("#5A3420")}
const HAIR_COLORS := {"noir": Color("#3B2F35"), "brun": Color("#6B4532"), "blond": Color("#E2C178"),
		"roux": Color("#C8643B"), "gris": Color("#A8A6AE"), "blanc": Color("#EEECE6"),
		"rose": Color("#E58FB5"), "bleu": Color("#6FA8DC")}
const OUTFIT_COLORS := {"orange": Color("#E8794A"), "moutarde": Color("#E2A93B"), "sauge": Color("#8DB596"),
		"canard": Color("#6FA3A0"), "bleu": Color("#3E9BD6"), "pervenche": Color("#A3B5EC"),
		"prune": Color("#C46BA0"), "brique": Color("#B85C45"), "ardoise": Color("#4A5568"),
		"creme": Color("#F3E3C3")}
const PANTS_COLOR := Color("#4A5568")

@export var sex: StringName = &"femme"
@export var age: StringName = &"adulte"
@export var skin: Color = Color("#E5B48C")
@export var hair_style: StringName = &"longs"
@export var hair_color: Color = Color("#6B4532")
@export var outfit: StringName = &"tshirt"
@export var outfit_color: Color = Color("#8DB596")
@export var pants_color: Color = PANTS_COLOR


## Coupe réellement dessinée (le crâne dégarni n'existe qu'à partir d'adulte).
func effective_hair() -> StringName:
	return hair_style if hair_available(hair_style, age) else HAIR_FALLBACK


static func hair_available(style: StringName, p_age: StringName) -> bool:
	if not HAIR_MIN_AGE.has(style):
		return true
	return AGES.find(p_age) >= AGES.find(HAIR_MIN_AGE[style])


func describe() -> String:
	return "%s · %s" % [SEX_NAMES.get(sex, ""), AGE_NAMES.get(age, "")]


# --- Calques ------------------------------------------------------------------------

## Calques du sprite en jeu, du fond vers le dessus : [chemin, teinte, remonte_en_marche].
## `direction` : bas, haut ou gauche (droite = gauche retourné) ; `pose` : "", "marche_1", "marche_2",
## "assis", "tailleur", "genoux" ou "allonge".
func body_layers(direction: StringName, pose: String = "") -> Array:
	# Allongé : les calques debout de face, sans ombre (le corps les fait pivoter).
	var lying := pose == "allonge"
	if lying:
		direction = &"bas"
		pose = ""
	var hair := effective_hair()
	var body := "corps_%s_%s_%s_%s%s" % [sex, age, outfit, direction, ("_" + pose) if pose != "" else ""]
	var head := "tete_%s_%s" % [age, direction]
	var hair_base := "cheveux_%s_%s_%s" % [hair, age, direction]
	var layers: Array = []
	if not lying:
		var shadow := "ombre_%s_%s%s.svg" % [sex, age, "_tailleur" if pose == "tailleur" else ""]
		layers.append([FOLDER + shadow, Color.WHITE, false])
	if direction == &"bas":
		layers.append([FOLDER + hair_base + "_arriere.svg", hair_color, true])
		layers.append([FOLDER + hair_base + "_arriere_contour.svg", Color.WHITE, true])
	layers.append([FOLDER + body + "_pantalon.svg", pants_color, false])
	layers.append([FOLDER + body + "_peau.svg", skin, false])
	layers.append([FOLDER + body + "_tenue.svg", outfit_color, false])
	layers.append([FOLDER + body + "_contour.svg", Color.WHITE, false])
	layers.append([FOLDER + head + ".svg", skin, true])
	layers.append([FOLDER + head + "_contour.svg", Color.WHITE, true])
	layers.append([FOLDER + hair_base + ".svg", hair_color, true])
	layers.append([FOLDER + hair_base + "_contour.svg", Color.WHITE, true])
	return layers


## Calques du portrait de face (64 × 64) : [chemin, teinte].
func portrait_layers() -> Array:
	var hair := "portrait_cheveux_%s_%s" % [effective_hair(), age]
	var body := "portrait_corps_%s_%s_%s" % [sex, age, outfit]
	var head := "portrait_tete_%s" % age
	return [
		[FOLDER + hair + "_arriere.svg", hair_color],
		[FOLDER + hair + "_arriere_contour.svg", Color.WHITE],
		[FOLDER + body + "_peau.svg", skin],
		[FOLDER + body + "_tenue.svg", outfit_color],
		[FOLDER + body + "_contour.svg", Color.WHITE],
		[FOLDER + head + ".svg", skin],
		[FOLDER + head + "_contour.svg", Color.WHITE],
		[FOLDER + hair + ".svg", hair_color],
		[FOLDER + hair + "_contour.svg", Color.WHITE],
	]


# --- Hasard et sauvegarde -----------------------------------------------------------

## Tire toute l'apparence au hasard, en gardant le sexe et l'âge.
func randomize_look(rng: RandomNumberGenerator) -> void:
	skin = _pick(SKINS.values(), rng)
	var styles: Array = HAIR_BY_SEX[sex].filter(func(style: StringName) -> bool: return hair_available(style, age))
	hair_style = _pick(styles, rng)
	var colors: Array = [HAIR_COLORS["noir"], HAIR_COLORS["brun"], HAIR_COLORS["blond"], HAIR_COLORS["roux"]]
	if age == &"aine":
		colors = [HAIR_COLORS["gris"], HAIR_COLORS["blanc"]]
	elif rng.randf() < 0.1:
		colors = [HAIR_COLORS["rose"], HAIR_COLORS["bleu"]]
	hair_color = _pick(colors, rng)
	outfit = &"robe" if sex == &"femme" and rng.randf() < 0.35 else _pick([&"tshirt", &"pull"], rng)
	outfit_color = _pick(OUTFIT_COLORS.values(), rng)


static func _pick(values: Array, rng: RandomNumberGenerator) -> Variant:
	return values[rng.randi_range(0, values.size() - 1)]


func to_dict() -> Dictionary:
	return {
		"sex": String(sex), "age": String(age), "skin": skin.to_html(false),
		"hair_style": String(hair_style), "hair_color": hair_color.to_html(false),
		"outfit": String(outfit), "outfit_color": outfit_color.to_html(false),
		"pants_color": pants_color.to_html(false),
	}


static func from_dict(data: Dictionary) -> MouzAppearance:
	var look := MouzAppearance.new()
	look.sex = StringName(data.get("sex", "femme"))
	look.age = StringName(data.get("age", "adulte"))
	look.skin = Color(data.get("skin", "E5B48C"))
	look.hair_style = StringName(data.get("hair_style", "court"))
	look.hair_color = Color(data.get("hair_color", "6B4532"))
	look.outfit = StringName(data.get("outfit", "tshirt"))
	look.outfit_color = Color(data.get("outfit_color", "8DB596"))
	look.pants_color = Color(data.get("pants_color", "4A5568"))
	return look
