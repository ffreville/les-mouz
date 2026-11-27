class_name PlacementBar
extends PanelContainer
## Barre de placement au doigt (téléphone), en bas de l'écran, quand un objet est en main en mode
## Acheter (ou déplacé avec l'outil Déplacer) : Tourner, Poser, Revendre (objet déplacé), Annuler.
## Elle remplace R, le clic, Suppr et Échap. L'objet suit le doigt posé sur la maison.

const BUTTON_HEIGHT := 44.0

var _buy: BuyController
var _sell := Button.new()


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -12
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	row.add_child(_button("Tourner", "tourner", &"SecondaryButton", func() -> void: _buy.turn()))
	row.add_child(_button("Poser", "valider", &"PrimaryButton", func() -> void: _buy.place()))
	_sell = _button("Revendre", "vendre", &"SecondaryButton", func() -> void: _buy.sell_moving())
	row.add_child(_sell)
	row.add_child(_button("Annuler", "annuler", &"QuietButton", func() -> void: _buy.drop()))


func setup(buy: BuyController) -> void:
	_buy = buy
	_buy.holding_changed.connect(_on_holding_changed)


func _on_holding_changed(holding: bool) -> void:
	visible = holding
	_sell.visible = holding and _buy.is_moving()


func _button(text: String, icon: String, variation: StringName, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = load("res://assets/icons/%s/%s.svg" % ["white" if variation == &"PrimaryButton" else "ink", icon])
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.pressed.connect(action)
	return button
