extends Node

# Runtime status stores — reset at start of each combat
var player_statuses: Dictionary = {}   # status_id -> stacks
var enemy_statuses: Array = [{}, {}, {}]  # one dict per enemy slot

func reset_for_combat() -> void:
	player_statuses = {}
	enemy_statuses = [{}, {}, {}]

func apply_to_player(status_id: String, stacks: int) -> void:
	player_statuses = ModifierSystem.apply_status(player_statuses, status_id, stacks)

func apply_to_enemy(slot: int, status_id: String, stacks: int) -> void:
	if slot < 0 or slot >= enemy_statuses.size():
		return
	enemy_statuses[slot] = ModifierSystem.apply_status(enemy_statuses[slot], status_id, stacks)

func get_player_status(status_id: String) -> int:
	return player_statuses.get(status_id, 0)

func get_enemy_status(slot: int, status_id: String) -> int:
	if slot < 0 or slot >= enemy_statuses.size():
		return 0
	return enemy_statuses[slot].get(status_id, 0)

# Call at end of player turn
func tick_player_end_of_turn() -> void:
	player_statuses = ModifierSystem.tick_statuses(player_statuses, true)

# Call at end of enemy turn for each active enemy slot.
# Returns the enemy's HP after poison and burn damage are applied.
func tick_enemy_end_of_turn(slot: int, enemy_current_hp: int) -> int:
	var poison_dmg: int = enemy_statuses[slot].get("poison", 0)
	var burn_dmg: int = enemy_statuses[slot].get("burn", 0)
	var total_dot: int = poison_dmg + burn_dmg
	enemy_statuses[slot] = ModifierSystem.tick_statuses(enemy_statuses[slot], false)
	return max(enemy_current_hp - total_dot, 0)