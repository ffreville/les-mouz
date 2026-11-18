class_name Purchase
extends Resource
## Ce qui a été payé pour un élément posé : sert à calculer la revente.

## Prix payé.
@export var price: int = 0
## Jour de jeu de l'achat (revente au prix plein le même jour).
@export var bought_day: int = 1
