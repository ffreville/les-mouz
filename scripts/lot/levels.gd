class_name Levels
extends RefCounted
## Les niveaux d'une maison, et les « cases de navigation » qui les distinguent.
## Une case de navigation est un Vector2i dont la ligne est décalée de STRIDE par niveau :
## (x, y) au niveau n devient (x, y + n × STRIDE). Au rez-de-chaussée, c'est la case elle-même ;
## ainsi tout le code qui ne connaît qu'un niveau continue de marcher au rez-de-chaussée.

## Nombre de niveaux : rez-de-chaussée et deux étages.
const COUNT := 3
const STRIDE := 1000
const NAMES := ["Rez-de-chaussée", "1er étage", "2e étage"]
const SHORT_NAMES := ["RDC", "1er", "2e"]


static func nav(cell: Vector2i, level: int) -> Vector2i:
	return Vector2i(cell.x, cell.y + level * STRIDE)


static func level_of(nav_cell: Vector2i) -> int:
	return floori(float(nav_cell.y) / STRIDE)


static func flat(nav_cell: Vector2i) -> Vector2i:
	return Vector2i(nav_cell.x, posmod(nav_cell.y, STRIDE))


static func display_name(level: int) -> String:
	return NAMES[clampi(level, 0, COUNT - 1)]
