extends Node

const SAVE_DIR  := "user://save/"
const SAVE_PATH := "user://save/run_save.json"


func save_run() -> void:
	_ensure_save_dir()
	var data := {
		"run_seed":            GameManager.run_seed,
		"current_champion_id": GameManager.current_champion_id,
		"current_act":         GameManager.current_act,
		"current_floor":       GameManager.current_floor,
		"max_hp":              GameManager.max_hp,
		"current_hp":          GameManager.current_hp,
		"gold":                GameManager.gold,
		"potions":             GameManager.potions.duplicate(),
		"relics":              GameManager.relics.duplicate(),
		"deck":                GameManager.deck.duplicate(),
		"hand":                GameManager.hand.duplicate(),
		"draw_pile":           GameManager.draw_pile.duplicate(),
		"discard_pile":        GameManager.discard_pile.duplicate(),
		"exhaust_pile":        GameManager.exhaust_pile.duplicate(),
		"current_energy":      GameManager.current_energy,
		"max_energy":          GameManager.max_energy,
		"player_statuses":     GameManager.player_statuses.duplicate(),
		"is_run_active":       GameManager.is_run_active,
		"ascension_level":     GameManager.ascension_level,
	}
	data["checksum"] = _compute_checksum(data)

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open save file for writing")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("SaveSystem: run saved to ", SAVE_PATH)


func load_run() -> bool:
	if not has_save():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: could not open save file for reading")
		return false
	var json_text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)
	if data == null or not data is Dictionary:
		push_error("SaveSystem: corrupted save – invalid JSON")
		return false

	var stored_checksum: String = data.get("checksum", "")
	var data_without_checksum := data.duplicate()
	data_without_checksum.erase("checksum")
	if _compute_checksum(data_without_checksum) != stored_checksum:
		push_error("SaveSystem: corrupted save – checksum mismatch")
		return false

	GameManager.run_seed            = data.get("run_seed", 0)
	GameManager.current_champion_id = data.get("current_champion_id", "")
	GameManager.current_act         = data.get("current_act", 1)
	GameManager.current_floor       = data.get("current_floor", 0)
	GameManager.max_hp              = data.get("max_hp", 80)
	GameManager.current_hp          = data.get("current_hp", 80)
	GameManager.gold                = data.get("gold", 99)
	GameManager.potions             = data.get("potions", [])
	GameManager.relics              = data.get("relics", [])
	GameManager.deck                = data.get("deck", [])
	GameManager.hand                = data.get("hand", [])
	GameManager.draw_pile           = data.get("draw_pile", [])
	GameManager.discard_pile        = data.get("discard_pile", [])
	GameManager.exhaust_pile        = data.get("exhaust_pile", [])
	GameManager.current_energy      = data.get("current_energy", 3)
	GameManager.max_energy          = data.get("max_energy", 3)
	GameManager.player_statuses     = data.get("player_statuses", {})
	GameManager.is_run_active       = data.get("is_run_active", false)
	GameManager.ascension_level     = data.get("ascension_level", 0)

	GameManager.rng = RandomNumberGenerator.new()
	GameManager.rng.seed = GameManager.run_seed

	print("SaveSystem: run loaded successfully")
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func clear_run_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
		print("SaveSystem: save cleared")


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _compute_checksum(data: Dictionary) -> String:
	var keys := data.keys()
	keys.sort()
	var parts: Array = []
	for k in keys:
		parts.append(str(k) + "=" + str(data[k]))
	return str(parts.hash())