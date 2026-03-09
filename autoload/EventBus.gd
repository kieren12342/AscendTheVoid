extends Node

# EventBus — global signal bus for decoupled communication between systems.

func _ready() -> void:
	print("[EventBus] Ready.")

# --- Card signals ---
signal card_played(card_data: CardData, targets: Array)
signal card_drawn(card_data: CardData)
signal card_discarded(card_data: CardData)
signal card_exhausted(card_data: CardData)
signal hand_updated(hand: Array)
signal deck_shuffled()

# --- Turn / Combat signals ---
signal turn_started(turn_number: int, is_player_turn: bool)
signal turn_ended(is_player_turn: bool)
signal combat_started(encounter: Dictionary)
signal combat_ended(victory: bool)
signal energy_changed(current: int, maximum: int)
signal block_applied(target: String, amount: int)
signal damage_dealt(source: String, target: String, amount: int)

# --- Status signals ---
signal status_applied(target: String, status_id: String, stacks: int)
signal status_ticked(target: String, status_id: String, stacks_remaining: int)
signal status_removed(target: String, status_id: String)

# --- Champion / HP signals ---
signal champion_hp_changed(current: int, maximum: int)
signal champion_died()
signal champion_healed(amount: int)

# --- Relic signals ---
signal relic_triggered(relic_id: String, context: Dictionary)
signal relic_obtained(relic_id: String)

# --- Potion signals ---
signal potion_used(potion_id: String, target: String)
signal potion_obtained(potion_id: String)

# --- Map signals ---
signal map_node_selected(node_data: Dictionary)
signal map_generated(map_data: Dictionary)
signal act_started(act_number: int)
signal act_completed(act_number: int)

# --- Run-meta signals ---
signal gold_changed(current: int, delta: int)
signal run_started(seed: int, champion_id: String)
signal run_ended(victory: bool, score: int)

# --- Shop signals ---
signal shop_entered()
signal shop_item_purchased(item_type: String, item_id: String, cost: int)

# --- Event signals ---
signal event_started(event_id: String)
signal event_choice_made(event_id: String, choice_index: int)
signal event_completed(event_id: String)

# --- Enemy signals ---
signal enemy_intent_updated(enemy_index: int, intent: Dictionary)
signal enemy_died(enemy_index: int, enemy_id: String)
signal enemy_hp_changed(enemy_index: int, current: int, maximum: int)
