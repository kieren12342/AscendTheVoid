extends Control

@onready var name_label: Label = $PanelContainer/VBoxContainer/EventNameLabel
@onready var desc_label: Label = $PanelContainer/VBoxContainer/EventDescLabel
@onready var choices_container: VBoxContainer = $PanelContainer/VBoxContainer/ChoicesContainer

var _event_data: Dictionary = {}
var _on_complete: Callable

func setup(event_data: Dictionary, on_complete: Callable) -> void:
	_event_data = event_data
	_on_complete = on_complete

func _ready() -> void:
	name_label.text = _event_data.get("name", "Unknown Event")
	desc_label.text = _event_data.get("description", "")
	_build_choices()

func _build_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()
	var choices: Array = _event_data.get("choices", [])
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice.get("text", "???")
		btn.custom_minimum_size = Vector2(400, 60)
		btn.theme_override_font_sizes["font_size"] = 14
		var idx := i
		btn.pressed.connect(func(): _on_choice(idx))
		choices_container.add_child(btn)

func _on_choice(choice_idx: int) -> void:
	var choices: Array = _event_data.get("choices", [])
	if choice_idx >= choices.size():
		return
	var effects: Array = choices[choice_idx].get("effects", [])
	for effect in effects:
		_apply_effect(effect)
	EventBus.event_choice_made.emit(_event_data.get("id",""), choice_idx)
	_on_complete.call()
	queue_free()

func _apply_effect(effect: Dictionary) -> void:
	var etype: String = effect.get("type", "")
	var amount: int = effect.get("amount", 0)
	var eid: String = effect.get("id", "")
	match etype:
		"heal":
			GameManager.heal(amount)
		"heal_percent":
			GameManager.heal(int(GameManager.max_hp * amount / 100.0))
		"lose_hp":
			GameManager.take_damage(amount)
		"gain_gold":
			GameManager.gain_gold(amount)
		"spend_gold":
			GameManager.spend_gold(amount)
		"max_hp_up":
			GameManager.max_hp += amount
			GameManager.current_hp = min(GameManager.current_hp + amount, GameManager.max_hp)
			EventBus.champion_hp_changed.emit(GameManager.current_hp, GameManager.max_hp)
		"max_hp_down":
			GameManager.max_hp = max(GameManager.max_hp - amount, 1)
			GameManager.current_hp = min(GameManager.current_hp, GameManager.max_hp)
			EventBus.champion_hp_changed.emit(GameManager.current_hp, GameManager.max_hp)
		"gain_relic":
			RelicManager.add_relic(eid)
		"gain_strength":
			StatusManager.apply_to_player("strength", amount)
		"gain_card", "remove_card", "upgrade_card":
			pass  # Placeholder for card collection management (future prompt)
		"gain_potion":
			pass  # Placeholder for potion system
