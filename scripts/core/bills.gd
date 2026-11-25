class_name Bills
extends Node
## Les factures de la maison (enfant du monde).
##  - Tous les BILL_INTERVAL jours, à BILL_HOUR, une facture arrive : un forfait plus un
##    pourcentage de la valeur de la maison (murs, sols, portes, fenêtres, objets).
##  - Elle est à payer dans les DUE_DAYS jours (bouton « Factures » en haut de l'écran).
##  - Passé ce délai, elle est majorée de LATE_FEE et l'électricité est coupée : les objets
##    électriques ne servent plus et les lampes s'éteignent, jusqu'à ce que tout soit payé.

## Les factures ont changé (arrivée, paiement, coupure).
signal changed

const BILL_INTERVAL := 3
const BILL_HOUR := 8
const DUE_DAYS := 3
const BASE_AMOUNT := 50
## Part de la valeur de la maison facturée à chaque fois.
const VALUE_RATE := 0.015
const LATE_FEE := 0.10
## Objets qui ne marchent plus quand l'électricité est coupée.
const ELECTRIC := [&"frigo", &"cuisiniere", &"micro_ondes", &"machine_cafe", &"lave_vaisselle",
		&"machine_laver", &"tele", &"ordinateur", &"console_jeux", &"chaine_hifi", &"lampe_chevet",
		&"lampe_pied", &"aquarium"]

## Factures à payer : { "amount": int, "day": jour d'arrivée, "due": jour limite, "late": bool }.
var pending: Array[Dictionary] = []
## Électricité coupée (une facture est en retard). Aussi lisible sans le monde : `Bills.cut`.
var power_cut := false
static var cut := false
## Dernier jour où une facture est arrivée.
var last_bill_day := 0

var world: World


func setup(p_world: World) -> void:
	world = p_world
	cut = false
	GameClock.minute_changed.connect(_on_minute_changed)


## Valeur de la maison : ce qu'ont coûté ses murs, sols, ouvertures et objets.
func house_value() -> int:
	var total := 0
	for wall in world.lot.walls.values():
		total += wall.price
	for floor_piece in world.lot.floors.values():
		total += floor_piece.price
	for opening in world.lot.openings:
		total += opening.price
	for paper in world.lot.wallpapers.values():
		total += paper.price
	for fence in world.lot.fences.values():
		total += fence.price
	for placed in world.lot.objects:
		total += placed.price
	return total


## Montant de la prochaine facture.
func next_amount() -> int:
	return BASE_AMOUNT + int(round(house_value() * VALUE_RATE))


func total_due() -> int:
	var total := 0
	for bill in pending:
		total += int(bill["amount"])
	return total


## Paie toutes les factures si l'argent suffit ; rétablit l'électricité.
func pay_all() -> bool:
	var total := total_due()
	if total == 0 or not Wallet.pay(total):
		return false
	pending.clear()
	if power_cut:
		_set_power_cut(false)
		EventBus.notice.emit("Factures payées : l'électricité est rétablie.")
	else:
		EventBus.notice.emit("Factures payées : %s." % Palette.format_mz(total))
	changed.emit()
	return true


## Pourquoi l'objet `object_id` ne peut pas servir ("" s'il le peut).
func problem_for(object_id: StringName) -> String:
	return "électricité coupée" if power_cut and object_id in ELECTRIC else ""


func _on_minute_changed(day: int, hour: int, _minute: int) -> void:
	if hour < BILL_HOUR:
		return
	if day % BILL_INTERVAL == 0 and day != last_bill_day:
		last_bill_day = day
		var amount := next_amount()
		pending.append({"amount": amount, "day": day, "due": day + DUE_DAYS, "late": false})
		EventBus.bill_received.emit(amount)
		EventBus.notice.emit("Nouvelle facture : %s, à payer avant le jour %d." % [Palette.format_mz(amount), day + DUE_DAYS])
		changed.emit()
	for bill in pending:
		if not bill["late"] and day >= int(bill["due"]):
			bill["late"] = true
			bill["amount"] = int(round(int(bill["amount"]) * (1.0 + LATE_FEE)))
			if not power_cut:
				_set_power_cut(true)
				EventBus.notice.emit("Facture en retard : l'électricité est coupée !")
			changed.emit()


## Coupe ou rétablit le courant : les objets électriques se redessinent (éteints) et ceux
## qu'on utilisait s'arrêtent.
func _set_power_cut(value: bool) -> void:
	power_cut = value
	cut = value
	for smart_object in world.smart_objects:
		if smart_object.definition.id in ELECTRIC:
			smart_object.queue_redraw()
	if value:
		for character in world.people:
			for action in character.queue.items.duplicate():
				if action.target_object != null and problem_for(action.target_object.definition.id) != "":
					character.queue.cancel(action)
	EventBus.power_cut_changed.emit(value)


func to_dict() -> Dictionary:
	return {"pending": pending.duplicate(true), "power_cut": power_cut, "last_bill_day": last_bill_day}


func restore(data: Dictionary) -> void:
	pending.clear()
	for bill in data.get("pending", []):
		pending.append({"amount": int(bill.get("amount", 0)), "day": int(bill.get("day", 0)),
				"due": int(bill.get("due", 0)), "late": bool(bill.get("late", false))})
	last_bill_day = int(data.get("last_bill_day", 0))
	_set_power_cut(bool(data.get("power_cut", false)))
	changed.emit()
