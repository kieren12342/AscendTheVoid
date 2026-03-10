extends Node

# ModifierSystem — calculates final damage and block values
# taking into account Strength, Dexterity, Weak, Vulnerable, Frail.

# Calculate final attack damage dealt BY the player TO an enemy.
# attacker_statuses: Dictionary of status_id -> stacks on the attacker
# defender_statuses: Dictionary of status_id -> stacks on the defender
func calc_player_damage(base: int, attacker_statuses: Dictionary, defender_statuses: Dictionary) -> int:
	var dmg := base
	# Strength adds flat damage
	dmg += attacker_statuses.get("strength", 0)
	# Weak reduces damage by 25%
	if attacker_statuses.get("weak", 0) > 0:
		dmg = int(dmg * 0.75)
	# Vulnerable increases damage taken by 50%
	if defender_statuses.get("vulnerable", 0) > 0:
		dmg = int(dmg * 1.5)
	return max(dmg, 0)

# Calculate final block gained BY the player.
func calc_player_block(base: int, player_statuses: Dictionary) -> int:
	var blk := base
	# Dexterity adds flat block
	blk += player_statuses.get("dexterity", 0)
	# Frail reduces block gain by 25%
	if player_statuses.get("frail", 0) > 0:
		blk = int(blk * 0.75)
	return max(blk, 0)

# Calculate final attack damage dealt BY an enemy TO the player.
func calc_enemy_damage(base: int, enemy_statuses: Dictionary, player_statuses: Dictionary) -> int:
	var dmg := base
	dmg += enemy_statuses.get("strength", 0)
	if enemy_statuses.get("weak", 0) > 0:
		dmg = int(dmg * 0.75)
	if player_statuses.get("vulnerable", 0) > 0:
		dmg = int(dmg * 1.5)
	return max(dmg, 0)

# Tick statuses at end of turn: reduce debuff stacks by 1 (min 0), apply poison/burn damage.
# Returns updated statuses Dictionary.
func tick_statuses(statuses: Dictionary, is_player: bool) -> Dictionary:
	var result := statuses.duplicate()
	# Poison: deal stacks damage, then reduce by 1
	if result.get("poison", 0) > 0:
		var poison_dmg: int = result["poison"]
		if is_player:
			GameManager.take_damage(poison_dmg)
		# caller handles enemy poison damage
		result["poison"] = max(result["poison"] - 1, 0)
	# Burn: deal stacks damage, then reduce by 1
	if result.get("burn", 0) > 0:
		var burn_dmg: int = result["burn"]
		if is_player:
			GameManager.take_damage(burn_dmg)
		# caller handles enemy burn damage
		result["burn"] = max(result["burn"] - 1, 0)
	# Tick timed debuffs
	for status_id in ["weak", "vulnerable", "frail"]:
		if result.get(status_id, 0) > 0:
			result[status_id] = result[status_id] - 1
	# Remove zeroed entries
	var to_remove := []
	for k in result:
		if result[k] <= 0:
			to_remove.append(k)
	for k in to_remove:
		result.erase(k)
	return result

# Apply a status to a statuses Dictionary (adds stacks).
func apply_status(statuses: Dictionary, status_id: String, stacks: int) -> Dictionary:
	var result := statuses.duplicate()
	result[status_id] = result.get(status_id, 0) + stacks
	EventBus.status_applied.emit("target", status_id, result[status_id])
	return result
