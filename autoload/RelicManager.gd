extends Node
# RelicManager — manages active relics and fires trigger effects.

var active_relics: Array = []  # Array of relic Dictionary entries from DataLoader

func reset_for_run() -> void:
	active_relics = []

func add_relic(relic_id: String) -> void:
	var relic_data := DataLoader.get_relic(relic_id)
	if relic_data.is_empty():
		push_error("[RelicManager] Relic not found: " + relic_id)
		return
	active_relics.append(relic_data)
	EventBus.relic_obtained.emit(relic_id)
	print("[RelicManager] Obtained: %s" % relic_data.get("name", relic_id))
	# Fire immediate on_obtain effects
	var trigger: String = relic_data.get("trigger", "")
	if trigger == "on_obtain":
		_apply_effect(relic_data.get("effect", {}))

func has_relic(relic_id: String) -> bool:
	for r in active_relics:
		if r.get("id", "") == relic_id:
			return true
	return false

# Called at start of player turn
func on_turn_start() -> void:
	for relic in active_relics:
		var trigger: String = relic.get("trigger", "")
		var effect: Dictionary = relic.get("effect", {})
		if trigger == "on_turn_start":
			_apply_effect(effect)
	EventBus.relic_triggered.emit("on_turn_start", {})

# Called when a card is played
func on_card_played(card_data) -> void:
	for relic in active_relics:
		var trigger: String = relic.get("trigger", "")
		var effect: Dictionary = relic.get("effect", {})
		if trigger == "on_card_played":
			_apply_effect(effect)
	EventBus.relic_triggered.emit("on_card_played", {})

# Called on combat victory
func on_victory() -> void:
	for relic in active_relics:
		var trigger: String = relic.get("trigger", "")
		var effect: Dictionary = relic.get("effect", {})
		if trigger == "on_victory":
			_apply_effect(effect)
	EventBus.relic_triggered.emit("on_victory", {})

func _apply_effect(effect: Dictionary) -> void:
	var etype: String = effect.get("type", "")
	var amount: int = effect.get("amount", 0)
	match etype:
		"heal":
			GameManager.heal(amount)
		"gain_gold":
			GameManager.gain_gold(amount)
		"gain_energy":
			GameManager.current_energy = min(GameManager.current_energy + amount, GameManager.base_energy + 3)
			EventBus.energy_changed.emit(GameManager.current_energy, GameManager.base_energy)
		"gain_strength":
			StatusManager.apply_to_player("strength", amount)
		"gain_block":
			GameManager._player_block += amount
			EventBus.block_applied.emit("player", GameManager._player_block)
		"draw_card":
			GameManager.draw_cards(amount)
		"max_hp_up":
			GameManager.max_hp += amount
			GameManager.current_hp += amount
			EventBus.champion_hp_changed.emit(GameManager.current_hp, GameManager.max_hp)
