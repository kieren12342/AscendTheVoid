extends Node

# ── Run / Meta ──────────────────────────────────────────────
signal run_started(seed_value: int, champion_id: String)
signal run_ended(victory: bool)
signal act_changed(new_act: int)

# ── Map ─────────────────────────────────────────────────────
signal map_generated(map_data: Dictionary)
signal map_node_selected(node_data: Dictionary)

# ── Combat ───────────────────────────────────────────────────
signal combat_started(enemy_data: Array)
signal combat_ended(victory: bool)
signal turn_started(is_player_turn: bool)
signal turn_ended(is_player_turn: bool)

# ── Cards ────────────────────────────────────────────────────
signal card_played(card_id: String)
signal card_drawn(card_id: String)
signal card_discarded(card_id: String)
signal card_exhausted(card_id: String)
signal card_added_to_deck(card_id: String)
signal card_removed_from_deck(card_id: String)
signal hand_updated(hand: Array)
signal deck_shuffled()

# ── Energy ───────────────────────────────────────────────────
signal energy_changed(current: int, maximum: int)

# ── Player ───────────────────────────────────────────────────
signal player_hp_changed(current: int, maximum: int)
signal player_block_changed(value: int)
signal player_died()
signal gold_changed(amount: int)

# ── Enemies ──────────────────────────────────────────────────
signal enemy_hp_changed(enemy_id: int, current: int, maximum: int)
signal enemy_block_changed(enemy_id: int, value: int)
signal enemy_died(enemy_id: int)
signal enemy_intent_changed(enemy_id: int, intent: Dictionary)

# ── Statuses ─────────────────────────────────────────────────
signal status_applied(target: String, status_id: String, stacks: int)
signal status_removed(target: String, status_id: String)
signal status_ticked(target: String, status_id: String, stacks: int)

# ── Relics ───────────────────────────────────────────────────
signal relic_triggered(relic_id: String)
signal relic_obtained(relic_id: String)

# ── Potions ──────────────────────────────────────────────────
signal potion_obtained(potion_id: String)
signal potion_used(potion_id: String)

# ── Events ───────────────────────────────────────────────────
signal event_started(event_id: String)
signal event_choice_made(event_id: String, choice_index: int)
signal event_ended(event_id: String)

# ── Shop ─────────────────────────────────────────────────────
signal shop_entered()
signal item_purchased(item_type: String, item_id: String, cost: int)

# ── Rewards ──────────────────────────────────────────────────
signal reward_screen_opened(rewards: Array)
signal reward_claimed(reward: Dictionary)