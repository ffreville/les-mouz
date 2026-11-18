extends Node
## Autoload « Wallet » : l'argent du foyer (en Mz).
## Toute dépense ou recette passe par ici et émet EventBus.money_changed.

const SETTINGS_PATH := "res://data/settings/economy_settings.tres"

var settings: EconomySettings
var funds: int = 0


# Chargé dès la création pour être disponible avant tout autre _ready().
func _init() -> void:
	settings = load(SETTINGS_PATH)
	funds = settings.start_funds


func can_afford(amount: int) -> bool:
	return amount <= funds


## Paie `amount`. Renvoie false (sans rien payer) si l'argent manque.
func pay(amount: int) -> bool:
	if amount > funds:
		return false
	_change(-amount)
	return true


func receive(amount: int) -> void:
	_change(amount)


## Ajoute ou retire un montant sans condition (annulation d'une action de l'éditeur).
func adjust(delta: int) -> void:
	_change(delta)


## Remplace le solde (chargement d'une sauvegarde).
func set_funds(value: int) -> void:
	_change(value - funds)


## Note le prix payé et le jour d'achat d'un élément posé.
func stamp(item: Purchase, price: int) -> void:
	item.price = price
	item.bought_day = GameClock.get_day()


## Ce que rapporte la revente d'un élément : prix plein le jour même, une part ensuite.
func resale_value(item: Purchase) -> int:
	var ratio := settings.refund_same_day if item.bought_day == GameClock.get_day() else settings.refund_later
	return roundi(item.price * ratio)


func _change(delta: int) -> void:
	if delta == 0:
		return
	funds += delta
	EventBus.money_changed.emit(funds, delta)
