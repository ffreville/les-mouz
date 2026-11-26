class_name BillsButton
extends Button
## Bouton « Factures » de la barre du haut, à côté de l'argent. Caché quand il n'y a rien à payer.
## Rouge quand une facture est en retard (électricité coupée). Un clic ouvre le détail
## et propose de tout payer.

const ICON := preload("res://assets/icons/ink/alerte.svg")

var _bills: Bills


func _ready() -> void:
	theme_type_variation = &"SecondaryButton"
	focus_mode = Control.FOCUS_NONE
	icon = ICON
	add_theme_font_size_override("font_size", 13)
	custom_minimum_size.y = 36
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	visible = false
	pressed.connect(_open_menu)


func setup(bills: Bills) -> void:
	_bills = bills
	_bills.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var total := _bills.total_due()
	visible = total > 0
	var count := _bills.pending.size()
	text = Palette.format_mz(total)
	var late := _bills.power_cut
	add_theme_color_override("font_color", Palette.CRITIQUE if late else Palette.ENCRE)
	add_theme_color_override("icon_normal_color", Palette.CRITIQUE if late else Palette.ENCRE)
	tooltip_text = "%d facture%s à payer%s" % [count, "s" if count > 1 else "",
			" : électricité coupée !" if late else ""]


func _open_menu() -> void:
	var options: Array = []
	for bill in _bills.pending:
		options.append({
			"label": "%s%s · reçue jour %d · %s" % [String(bill.get("label", "")) + " : " if bill.get("label", "") != "" else "",
					Palette.format_mz(int(bill["amount"])), int(bill["day"]),
					"en retard (+10 %)" if bill["late"] else "avant le jour %d" % int(bill["due"])],
			"disabled": true,
		})
	var total := _bills.total_due()
	var affordable := Wallet.can_afford(total)
	options.append({
		"label": "Tout payer (%s)" % Palette.format_mz(total) if affordable else "Pas assez d'argent (%s)" % Palette.format_mz(total),
		"icon": load("res://assets/icons/ink/mz.svg"),
		"disabled": not affordable,
		"callback": _bills.pay_all,
	})
	var screen_position := get_global_rect().position + Vector2(0, size.y)
	EventBus.context_menu_requested.emit("Factures", options, screen_position)
