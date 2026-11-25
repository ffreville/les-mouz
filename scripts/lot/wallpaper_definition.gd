class_name WallpaperDefinition
extends Resource
## Un papier peint : couleur de fond, motif et sa couleur, prix par segment de mur.
## Il habille la face visible des murs du haut d'une pièce (vue trois quarts).

## Motifs connus : uni, rayures, pois, losanges, carreaux.
const PATTERNS: Array[StringName] = [&"uni", &"rayures", &"pois", &"losanges", &"carreaux"]
## Pas du motif, en pixels.
const STEP := 8.0

@export var id: StringName = &"papier"
@export var display_name: String = "Papier peint"
@export var color: Color = Color("#EFE6D6")
@export var pattern: StringName = &"uni"
@export var pattern_color: Color = Color("#D8C9AE")
@export var price_per_segment: int = 20


## Dessine le papier peint dans `rect` sur `canvas` (pan de mur, vignette du catalogue).
func draw(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, color)
	match pattern:
		&"rayures":
			var x := rect.position.x + 2.0
			while x < rect.end.x:
				canvas.draw_rect(Rect2(x, rect.position.y, minf(3.0, rect.end.x - x), rect.size.y), pattern_color)
				x += STEP
		&"pois":
			var row := 0
			var y := rect.position.y + STEP / 2.0
			while y < rect.end.y:
				var x := rect.position.x + (STEP / 2.0 if row % 2 == 0 else STEP)
				while x < rect.end.x:
					canvas.draw_circle(Vector2(x, y), 1.4, pattern_color)
					x += STEP
				y += STEP / 1.5
				row += 1
		&"losanges":
			var y := rect.position.y + STEP / 2.0
			while y < rect.end.y:
				var x := rect.position.x + STEP / 2.0
				while x < rect.end.x:
					canvas.draw_colored_polygon(PackedVector2Array([Vector2(x, y - 2.5), Vector2(x + 2.5, y),
							Vector2(x, y + 2.5), Vector2(x - 2.5, y)]), pattern_color)
					x += STEP
				y += STEP
		&"carreaux":
			var x := rect.position.x + STEP / 2.0
			while x < rect.end.x:
				canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), pattern_color, 1.5)
				x += STEP
			var y := rect.position.y + STEP / 2.0
			while y < rect.end.y:
				canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), pattern_color, 1.5)
				y += STEP
