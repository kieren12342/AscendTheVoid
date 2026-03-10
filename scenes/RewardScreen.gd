extends Control

@onready var relic_row: HBoxContainer = $Panel/Layout/RelicRow
@onready var skip_btn: Button = $Panel/Layout/SkipButton
@onready var title_label: Label = $Panel/Layout/TitleLabel

var _offered_relics: Array = []
var _on_complete: Callable

func setup(offered_relic_ids: Array, on_complete: Callable) -> void:
	_offered_relics = offered_relic_ids
	_on_complete = on_complete

func _ready() -> void:
	skip_btn.pressed.connect(_on_skip)
	_build_relic_choices()

func _build_relic_choices() -> void:
	for child in relic_row.get_children():
		child.queue_free()
	for relic_id in _offered_relics:
		var relic_data := DataLoader.get_relic(relic_id)
		if relic_data.is_empty():
			continue
		var btn := Button.new()
		var rarity: String = relic_data.get("rarity", "COMMON")
		btn.text = "%s\n%s\n[%s]" % [
			relic_data.get("name", relic_id),
			relic_data.get("description", ""),
			rarity
		]
		btn.custom_minimum_size = Vector2(180, 120)
		btn.theme_override_font_sizes["font_size"] = 12
		var rid := relic_id
		btn.pressed.connect(func(): _pick_relic(rid))
		relic_row.add_child(btn)

func _pick_relic(relic_id: String) -> void:
	RelicManager.add_relic(relic_id)
	_on_complete.call()
	queue_free()

func _on_skip() -> void:
	_on_complete.call()
	queue_free()
