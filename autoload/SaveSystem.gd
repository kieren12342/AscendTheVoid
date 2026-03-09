extends Node

# SaveSystem — saves and loads run state to/from disk as JSON.

const SAVE_PATH := "user://ascend_save.json"
const SETTINGS_PATH := "user://settings.json"

func _ready() -> void:
	print("[SaveSystem] Ready. Save exists: %s" % str(has_save()))

# -----------------------------------------------------------------------
# Run save / load
# -----------------------------------------------------------------------

func save_run() -> void:
	var gm := GameManager
	var data := {
		"run_seed": gm.run_seed,
		"champion_id": gm.champion_id,
		"act": gm.act,
		"floor_number": gm.floor_number,
		"gold": gm.gold,
		"max_hp": gm.max_hp,
		"current_hp": gm.current_hp,
		"base_energy": gm.base_energy,
		"potions": gm.potions.duplicate(),
		"relics": gm.relics.duplicate(),
		"deck": _serialize_card_array(gm.deck),
		"draw_pile": _serialize_card_array(gm.draw_pile),
		"hand": _serialize_card_array(gm.hand),
		"discard_pile": _serialize_card_array(gm.discard_pile),
		"exhaust_pile": _serialize_card_array(gm.exhaust_pile),
	}
	var json_text := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveSystem] Could not open save file for writing.")
		return
	file.store_string(json_text)
	file.close()

func load_run() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveSystem] Could not open save file for reading.")
		return false
	var json_text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null or not (parsed is Dictionary):
		push_error("[SaveSystem] Save file is corrupt.")
		return false
	var data: Dictionary = parsed
	var gm := GameManager
	gm.run_seed = int(data.get("run_seed", 0))
	gm.rng.seed = gm.run_seed
	gm.champion_id = str(data.get("champion_id", ""))
	gm.act = int(data.get("act", 1))
	gm.floor_number = int(data.get("floor_number", 0))
	gm.gold = int(data.get("gold", 0))
	gm.max_hp = int(data.get("max_hp", 75))
	gm.current_hp = int(data.get("current_hp", 75))
	gm.base_energy = int(data.get("base_energy", 3))
	gm.potions = _to_array(data.get("potions", []))
	gm.relics = _to_array(data.get("relics", []))
	gm.deck = _deserialize_card_array(_to_array(data.get("deck", [])))
	gm.draw_pile = _deserialize_card_array(_to_array(data.get("draw_pile", [])))
	gm.hand = _deserialize_card_array(_to_array(data.get("hand", [])))
	gm.discard_pile = _deserialize_card_array(_to_array(data.get("discard_pile", [])))
	gm.exhaust_pile = _deserialize_card_array(_to_array(data.get("exhaust_pile", [])))
	gm.run_active = true
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# -----------------------------------------------------------------------
# Settings save / load
# -----------------------------------------------------------------------

func save_settings(settings: Dictionary) -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveSystem] Could not open settings file for writing.")
		return
	file.store_string(JSON.stringify(settings, "\t"))
	file.close()

func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return {}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

# -----------------------------------------------------------------------
# Serialisation helpers
# -----------------------------------------------------------------------

func _serialize_card_array(cards: Array) -> Array:
	var out := []
	for card in cards:
		if card is CardData:
			out.append({"id": card.id, "upgraded": card.is_upgraded})
	return out

func _deserialize_card_array(raw: Array) -> Array:
	# Load full card definitions from cards.json then stamp upgrade flag.
	var card_db := _load_card_db()
	var out := []
	for entry in raw:
		if entry is Dictionary:
			var cid: String = str(entry.get("id", ""))
			var upgraded: bool = bool(entry.get("upgraded", false))
			if cid in card_db:
				var card: CardData = card_db[cid].duplicate_card()
				card.is_upgraded = upgraded
				out.append(card)
	return out

var _card_db_cache: Dictionary = {}

func _load_card_db() -> Dictionary:
	if not _card_db_cache.is_empty():
		return _card_db_cache
	var file := FileAccess.open("res://data/cards.json", FileAccess.READ)
	if file == null:
		push_error("[SaveSystem] Could not open res://data/cards.json")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Array):
		return {}
	for entry in (parsed as Array):
		if entry is Dictionary:
			var c: CardData = GameManager._dict_to_card(entry)
			_card_db_cache[c.id] = c
	return _card_db_cache

func _to_array(v: Variant) -> Array:
	if v is Array:
		return v
	return []
