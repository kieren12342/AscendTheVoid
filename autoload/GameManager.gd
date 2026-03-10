# // CROSS-PLATFORM READY – Steam + mobile
extends Node

# GameManager — run state singleton. Tracks all state for an active run.

# --- Run identity ---
var run_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var champion_id: String = ""
var run_active: bool = false

# --- Progression ---
var act: int = 1
var floor_number: int = 0

# --- Economy ---
var gold: int = 0

# --- HP ---
var max_hp: int = 75
var current_hp: int = 75

# --- Energy ---
var base_energy: int = 3
var current_energy: int = 3

# --- Inventory ---
var potions: Array = []      # Max 3 slots
var relics: Array = []       # Array of relic id strings

# --- Deck / card piles ---
var deck: Array = []         # Full deck (CardData instances)
var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []

# --- Map ---
var map_data: Dictionary = {}

# --- Turn tracking ---
var _turn_number: int = 0
var _player_block: int = 0

# -----------------------------------------------------------------------

func _ready() -> void:
	EventBus.champion_died.connect(_on_champion_died)
	print("[GameManager] Ready. No active run.")

# -----------------------------------------------------------------------
# Run lifecycle
# -----------------------------------------------------------------------

func start_run(p_champion_id: String, seed: int = 0) -> void:
	champion_id = p_champion_id
	run_seed = seed if seed != 0 else int(Time.get_unix_time_from_system())
	rng.seed = run_seed
	run_active = true
	act = 1
	floor_number = 0
	gold = 0
	potions = []
	relics = []
	deck = []
	draw_pile = []
	hand = []
	discard_pile = []
	exhaust_pile = []
	map_data = {}
	_turn_number = 0
	_player_block = 0
	# Load champion defaults from data (sets base hp/energy/relic for legacy champions)
	_load_champion_defaults(p_champion_id)
	# Set champion HP based on selected champion (overrides defaults for new champions)
	var champion_hp: Dictionary = {
		"void_warden": 80,
		"shadow_lurker": 70,
		"plasma_weaver": 68,
		"rift_shaper": 72
	}
	if champion_hp.has(p_champion_id):
		max_hp = champion_hp[p_champion_id]
		current_hp = max_hp
	EventBus.run_started.emit(run_seed, champion_id)
	print("[GameManager] Run started. Champion: %s | Deck size: %d" % [champion_id, deck.size()])

func end_run(victory: bool) -> void:
	if not run_active:
		return
	run_active = false
	var score := _calculate_score(victory)
	EventBus.run_ended.emit(victory, score)
	SaveSystem.delete_save()
	print("[GameManager] Run ended. Victory: %s | Score: %d" % [str(victory), score])

func _on_champion_died() -> void:
	end_run(false)

func _calculate_score(victory: bool) -> int:
	var base := floor_number * 10
	if victory:
		base += 500
	base += gold / 10
	return base

# -----------------------------------------------------------------------
# Champion defaults loader (reads from data/cards.json seed)
# -----------------------------------------------------------------------

func _load_champion_defaults(p_champion_id: String) -> void:
	# Default stats — champion-specific overrides can be added here
	match p_champion_id:
		"rift_walker":
			max_hp = 80
			gold = 99
			base_energy = 3
			starting_relic_id = "void_shard"
		"void_herald":
			max_hp = 70
			gold = 99
			base_energy = 3
			starting_relic_id = "herald_crown"
		"entropy_weaver":
			max_hp = 75
			gold = 99
			base_energy = 3
			starting_relic_id = "loom_of_chaos"
		"null_sovereign":
			max_hp = 90
			gold = 99
			base_energy = 3
			starting_relic_id = "null_core"
		_:
			max_hp = 75
			gold = 99
			base_energy = 3
			starting_relic_id = ""
	current_hp = max_hp
	current_energy = base_energy
	# Add starter relic
	if starting_relic_id != "":
		add_relic(starting_relic_id)
	# Load starter deck from cards.json
	_load_starter_deck(p_champion_id)

# Expose so tests can call it too
var starting_relic_id: String = ""

func _load_starter_deck(p_champion_id: String) -> void:
	var file := FileAccess.open("res://data/cards.json", FileAccess.READ)
	if file == null:
		push_error("[GameManager] Could not open res://data/cards.json")
		return
	var json_text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null or not (parsed is Array):
		push_error("[GameManager] cards.json parse error")
		return
	var all_cards: Array = parsed
	# Starter deck: BASIC cards matching this champion_id or colorless (empty/"colorless")
	for entry in all_cards:
		if entry is Dictionary:
			var cid: String = entry.get("champion_id", "")
			var rarity: String = entry.get("rarity", "")
			if (cid == p_champion_id or cid == "" or cid == "colorless") and rarity == "BASIC":
				var card_data := _dict_to_card(entry)
				deck.append(card_data)
	# Fallback: if no champion-specific cards found, add 5 basic Strike cards
	if deck.is_empty():
		for _i in range(5):
			var fallback := CardData.new()
			fallback.id = "strike"
			fallback.card_name = "Strike"
			fallback.description = "Deal !D! damage."
			fallback.upgraded_description = "Deal !D! damage."
			fallback.card_type = CardData.CardType.ATTACK
			fallback.rarity = CardData.CardRarity.BASIC
			fallback.target = CardData.TargetType.SINGLE_ENEMY
			fallback.energy_cost = 1
			fallback.base_damage = 6
			fallback.champion_id = p_champion_id
			deck.append(fallback)

func _dict_to_card(d: Dictionary) -> CardData:
	var c := CardData.new()
	c.id = d.get("id", "")
	c.card_name = d.get("card_name", "")
	c.description = d.get("description", "")
	c.upgraded_description = d.get("upgraded_description", "")
	c.card_type = _parse_card_type(d.get("card_type", "ATTACK"))
	c.rarity = _parse_card_rarity(d.get("rarity", "COMMON"))
	c.target = _parse_target_type(d.get("target", "SINGLE_ENEMY"))
	c.energy_cost = d.get("energy_cost", 1)
	c.upgraded_energy_cost = d.get("upgraded_energy_cost", -1)
	c.exhausts = d.get("exhausts", false)
	c.ethereal = d.get("ethereal", false)
	c.innate = d.get("innate", false)
	c.champion_id = d.get("champion_id", "")
	c.base_damage = d.get("base_damage", 0)
	c.base_block = d.get("base_block", 0)
	c.base_magic_number = d.get("base_magic_number", 0)
	c.upgraded_damage = d.get("upgraded_damage", -1)
	c.upgraded_block = d.get("upgraded_block", -1)
	c.upgraded_magic_number = d.get("upgraded_magic_number", -1)
	var raw_tags = d.get("tags", [])
	for t in raw_tags:
		c.tags.append(str(t))
	return c

func _parse_card_type(s: String) -> CardData.CardType:
	match s:
		"ATTACK": return CardData.CardType.ATTACK
		"SKILL": return CardData.CardType.SKILL
		"POWER": return CardData.CardType.POWER
		"CURSE": return CardData.CardType.CURSE
		"STATUS": return CardData.CardType.STATUS
	return CardData.CardType.ATTACK

func _parse_card_rarity(s: String) -> CardData.CardRarity:
	match s:
		"BASIC": return CardData.CardRarity.BASIC
		"COMMON": return CardData.CardRarity.COMMON
		"UNCOMMON": return CardData.CardRarity.UNCOMMON
		"RARE": return CardData.CardRarity.RARE
		"SPECIAL": return CardData.CardRarity.SPECIAL
	return CardData.CardRarity.COMMON

func _parse_target_type(s: String) -> CardData.TargetType:
	match s:
		"SINGLE_ENEMY": return CardData.TargetType.SINGLE_ENEMY
		"ALL_ENEMIES": return CardData.TargetType.ALL_ENEMIES
		"SELF": return CardData.TargetType.SELF
		"NONE": return CardData.TargetType.NONE
	return CardData.TargetType.SINGLE_ENEMY

# -----------------------------------------------------------------------
# Gold
# -----------------------------------------------------------------------

func gain_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold, amount)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold, -amount)
	return true

# -----------------------------------------------------------------------
# HP
# -----------------------------------------------------------------------

func heal(amount: int) -> void:
	var prev := current_hp
	current_hp = min(current_hp + amount, max_hp)
	var healed := current_hp - prev
	if healed > 0:
		EventBus.champion_healed.emit(healed)
	EventBus.champion_hp_changed.emit(current_hp, max_hp)

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	EventBus.champion_hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		EventBus.champion_died.emit()

# -----------------------------------------------------------------------
# Relics
# -----------------------------------------------------------------------

func add_relic(relic_id: String) -> void:
	relics.append(relic_id)
	EventBus.relic_obtained.emit(relic_id)

func has_relic(relic_id: String) -> bool:
	return relic_id in relics

# -----------------------------------------------------------------------
# Deck management
# -----------------------------------------------------------------------

func add_card_to_deck(card_data: CardData) -> void:
	deck.append(card_data)

func remove_card_from_deck(card_data: CardData) -> void:
	deck.erase(card_data)

# -----------------------------------------------------------------------
# Floor / Act progression
# -----------------------------------------------------------------------

func next_floor() -> void:
	floor_number += 1
	# Act transitions: floors 1-16 act 1, 17-33 act 2, 34-50 act 3, 51+ act 4
	var new_act := 1
	if floor_number >= 51:
		new_act = 4
	elif floor_number >= 34:
		new_act = 3
	elif floor_number >= 17:
		new_act = 2
	if new_act != act:
		var old_act := act
		act = new_act
		EventBus.act_completed.emit(old_act)
		EventBus.act_started.emit(act)

# -----------------------------------------------------------------------
# Card pile / draw mechanics
# -----------------------------------------------------------------------

func shuffle_deck() -> void:
	# Fisher-Yates with seeded RNG
	var pile := draw_pile
	var n := pile.size()
	for i in range(n - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pile[i]
		pile[i] = pile[j]
		pile[j] = tmp
	EventBus.deck_shuffled.emit()

func draw_cards(count: int) -> void:
	for _i in range(count):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			# Reshuffle discard into draw
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			shuffle_deck()
		if draw_pile.is_empty():
			break
		var card: CardData = draw_pile.pop_back()
		hand.append(card)
		EventBus.card_drawn.emit(card)
	EventBus.hand_updated.emit(hand)

func play_card(card_index: int, targets: Array) -> bool:
	if card_index < 0 or card_index >= hand.size():
		return false
	var card: CardData = hand[card_index]
	if current_energy < card.get_cost():
		return false
	current_energy -= card.get_cost()
	hand.remove_at(card_index)
	EventBus.card_played.emit(card, targets)
	EventBus.energy_changed.emit(current_energy, base_energy)
	if card.exhausts:
		exhaust_pile.append(card)
		EventBus.card_exhausted.emit(card)
	else:
		discard_pile.append(card)
		EventBus.card_discarded.emit(card)
	EventBus.hand_updated.emit(hand)
	return true

func discard_hand() -> void:
	for card in hand:
		# Ethereal cards exhaust instead of discard
		if card.ethereal:
			exhaust_pile.append(card)
			EventBus.card_exhausted.emit(card)
		else:
			discard_pile.append(card)
			EventBus.card_discarded.emit(card)
	hand.clear()
	EventBus.hand_updated.emit(hand)

# -----------------------------------------------------------------------
# Turn management
# -----------------------------------------------------------------------

func start_turn() -> void:
	_turn_number += 1
	_player_block = 0
	current_energy = base_energy
	EventBus.energy_changed.emit(current_energy, base_energy)
	# Reset draw pile from full deck at the start of combat (first turn)
	if draw_pile.is_empty() and discard_pile.is_empty() and hand.is_empty():
		draw_pile = deck.duplicate()
		shuffle_deck()
	draw_cards(5)
	EventBus.turn_started.emit(_turn_number, true)

func end_turn() -> void:
	discard_hand()
	EventBus.turn_ended.emit(true)

# -----------------------------------------------------------------------
# RNG helper
# -----------------------------------------------------------------------

func rng_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)
