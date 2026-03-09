extends Node

# ── Run Identity ─────────────────────────────────────────────
var run_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ── Champion ─────────────────────────────────────────────────
var current_champion_id: String = ""
var champion_data: Dictionary = {}

# ── Run Progress ─────────────────────────────────────────────
var current_act: int = 1
var current_floor: int = 0
var map_data: Dictionary = {}

# ── Player State ─────────────────────────────────────────────
var max_hp: int = 80
var current_hp: int = 80
var gold: int = 99
var potions: Array = []
var relics: Array = []
var deck: Array = []

# ── Combat State ─────────────────────────────────────────────
var hand: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var current_energy: int = 3
var max_energy: int = 3

# ── Status Tracking ──────────────────────────────────────────
var player_statuses: Dictionary = {}

# ── Run Flags ────────────────────────────────────────────────
var is_run_active: bool = false
var ascension_level: int = 0

# ── Internal Data Cache ──────────────────────────────────────
var _all_cards: Dictionary = {}
var _all_relics: Dictionary = {}
var _all_champions: Dictionary = {}


func _ready() -> void:
	_load_data()


func _load_data() -> void:
	_all_cards = _load_json_dict("res://data/cards.json", "card_id")
	_all_relics = _load_json_dict("res://data/relics.json", "relic_id")
	_all_champions = _load_json_dict("res://data/champions.json", "champion_id")


func _load_json_dict(path: String, key_field: String) -> Dictionary:
	var result: Dictionary = {}
	if not FileAccess.file_exists(path):
		push_warning("GameManager: data file not found: " + path)
		return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameManager: could not open " + path)
		return result
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed is Array:
		push_error("GameManager: invalid JSON array in " + path)
		return result
	for entry in parsed:
		if entry is Dictionary and entry.has(key_field):
			result[entry[key_field]] = entry
	return result


func start_new_run(champion_id: String, seed_value: int = 0) -> void:
	if seed_value == 0:
		run_seed = randi()
	else:
		run_seed = seed_value
	rng = RandomNumberGenerator.new()
	rng.seed = run_seed

	current_champion_id = champion_id
	current_act = 1
	current_floor = 0
	map_data = {}
	player_statuses = {}
	hand = []
draw_pile = []
discard_pile = []
	exhaust_pile = []
potions = []
	relics = []
dek = []

	if not _all_champions.has(champion_id):
		push_error("GameManager: unknown champion_id: " + champion_id)
		return
	champion_data = _all_champions[champion_id]

	max_hp = champion_data.get("starting_hp", 80)
	current_hp = max_hp
	gold = champion_data.get("starting_gold", 99)
	max_energy = 3
	current_energy = max_energy

	var start_relic: String = champion_data.get("starting_relic_id", "")
	if start_relic != "":
		add_relic(start_relic)

	var starter_cards: Array = champion_data.get("starter_deck", [])
	for card_id in starter_cards:
		deck.append(card_id)

	is_run_active = true

	EventBus.run_started.emit(run_seed, champion_id)
	print("GameManager: run started | champion=%s seed=%d hp=%d deck=%d cards" % [
		champion_id, run_seed, current_hp, deck.size()
	])


func end_run(victory: bool) -> void:
	is_run_active = false
	EventBus.run_ended.emit(victory)
	SaveSystem.clear_run_save()


func change_act(new_act: int) -> void:
	current_act = new_act
	EventBus.act_changed.emit(new_act)


func add_card_to_deck(card_id: String) -> void:
	deck.append(card_id)
	EventBus.card_added_to_deck.emit(card_id)


func remove_card_from_deck(card_id: String) -> bool:
	var idx := deck.find(card_id)
	if idx == -1:
		return false
	deck.remove_at(idx)
	EventBus.card_removed_from_deck.emit(card_id)
	return true


func add_relic(relic_id: String) -> void:
	relics.append(relic_id)
	EventBus.relic_obtained.emit(relic_id)


func add_potion(potion_id: String) -> bool:
	if potions.size() >= 3:
		return false
	potions.append(potion_id)
	EventBus.potion_obtained.emit(potion_id)
	return true


func use_potion(slot: int) -> void:
	if slot < 0 or slot >= potions.size():
		return
	var pid: String = potions[slot]
	potions.remove_at(slot)
	EventBus.potion_used.emit(pid)


func modify_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	EventBus.gold_changed.emit(gold)


func modify_hp(amount: int) -> void:
	current_hp = clamp(current_hp + amount, 0, max_hp)
	EventBus.player_hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		EventBus.player_died.emit()


func get_rng_value() -> float:
	return rng.randf()


func get_rng_int(from: int, to: int) -> int:
	return rng.randi_range(from, to)


func get_card_data(card_id: String) -> Dictionary:
	return _all_cards.get(card_id, {})


func get_relic_data(relic_id: String) -> Dictionary:
	return _all_relics.get(relic_id, {})