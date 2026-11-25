class_name WallpaperPatch
extends Node2D
## Un pan de papier peint posé sur un segment de mur (voir WallView), trié avec lui.

var definition: WallpaperDefinition
var width := 32.0
var height := 50.0
## Haut du pan, par rapport au point de tri (négatif : au-dessus).
var top := -60.0


func _draw() -> void:
	if definition != null and height > 0.0:
		definition.draw(self, Rect2(0, top, width, height))
