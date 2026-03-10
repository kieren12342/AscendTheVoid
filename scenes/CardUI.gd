extends PanelContainer

var card_data = null
var card_index: int = 0

@onready var cost_label: Label = $VBox/CostLabel
@onready var name_label: Label = $VBox/NameLabel
@onready var type_label: Label = $VBox/TypeLabel
@onready var desc_label: Label = $VBox/DescLabel

func setup(data, index: int = 0) -> void:
	card_data = data
	card_index = index
	cost_label.text = str(data.get_cost())
	name_label.text = data.card_name
	type_label.text = CardData.CardType.keys()[data.card_type]
	desc_label.text = data.get_display_description()
	match data.card_type:
		CardData.CardType.ATTACK:
			self_modulate = Color(1.0, 0.7, 0.7)
		CardData.CardType.SKILL:
			self_modulate = Color(0.7, 0.85, 1.0)
		CardData.CardType.POWER:
			self_modulate = Color(0.85, 0.7, 1.0)
		_:
			self_modulate = Color(0.9, 0.9, 0.9)
	_apply_drop_shadow()

func _apply_drop_shadow() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_offset = Vector2(2, 4)
	add_theme_stylebox_override("panel", style)

func lift() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1).set_ease(Tween.EASE_OUT)

func drop() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN)
