class_name ColorSwatches
extends HFlowContainer
## Rangée de pastilles de couleur nommées (peau, cheveux, tenue). La choisie a un anneau.

signal picked(color: Color)

var _dots: Array[ColorDot] = []


func _init(colors: Dictionary, diameter := 26.0) -> void:
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)
	for color_name in colors:
		var dot := ColorDot.new(colors[color_name], diameter, color_name)
		dot.pressed.connect(_on_pressed.bind(dot))
		add_child(dot)
		_dots.append(dot)


## Marque la pastille la plus proche de `color` (sans émettre de signal).
func select(color: Color) -> void:
	for dot in _dots:
		dot.selected = dot.color.is_equal_approx(color)


func _on_pressed(dot: ColorDot) -> void:
	select(dot.color)
	picked.emit(dot.color)
