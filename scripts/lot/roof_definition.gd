class_name RoofDefinition
extends Resource
## Un style de toit (toute la maison le partage) : couleurs des pans et prix par case couverte.
## Le toit lui-même est calculé tout seul (voir RoofView). Ses motifs, dessinés par Claude Design
## (brief n° 8), sont dans `assets/toits/` : `toit_<style>_<sud|nord|est|ouest>.svg` (32 × 32, dans le
## repère du sol), `_faitage` (32 × 9, à répéter), `_gouttiere` (32 × 6, sauf le chaume).

const PATTERN := "res://assets/toits/toit_%s_%s.svg"
const THUMBNAIL := "res://assets/vignettes/toit_%s.svg"

@export var id: StringName = &"toit"
@export var display_name: String = "Toit"
## Pan au soleil (sud), pan nord, pan éclairé (ouest), pan à l'ombre (est).
@export var color: Color = Color("#C4664A")
@export var top_color: Color = Color("#9E4D37")
@export var light_color: Color = Color("#D27A5C")
@export var dark_color: Color = Color("#9E4D37")
## Lignes du matériau (rangs, joints) et arêtiers.
@export var line_color: Color = Color("#8E4330")
## Couleur du faîtage, sous son trait encre.
@export var ridge_color: Color = Color("#9E4D37")
@export var price_per_cell: int = 6


## Motif d'un pan (`sud`, `nord`, `est`, `ouest`) ou d'un filet (`faitage`, `gouttiere`) ; null s'il manque.
func pattern(part: String) -> Texture2D:
	var path := PATTERN % [id, part]
	return load(path) if ResourceLoader.exists(path) else null


## Vignette du style pour l'outil Toit (104 × 72) ; null s'il n'y en a pas.
func thumbnail() -> Texture2D:
	var path := THUMBNAIL % id
	return load(path) if ResourceLoader.exists(path) else null
