extends Node

var cards: Array = []
var relics: Array = []
var enemies: Array = []
var events: Array = []

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://cache")
	cards  = _load_json("res://data/cards.json",   "user://cache/cards.cache.res")
	relics = _load_json("res://data/relics.json",  "user://cache/relics.cache.res")
	enemies = _load_json("res://data/enemies.json", "user://cache/enemies.cache.res")
	events = _load_json("res://data/events.json",  "user://cache/events.cache.res")
	print("[DataLoader] Ready. Cards:%d Relics:%d Enemies:%d Events:%d" % [
		cards.size(), relics.size(), enemies.size(), events.size()])

func _load_json(json_path: String, cache_path: String) -> Array:
	if ResourceLoader.exists(cache_path):
		var cached = ResourceLoader.load(cache_path)
		if cached != null and cached is CachedData:
			return cached.data
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Cannot open: " + json_path)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not parsed is Array:
		push_error("[DataLoader] Invalid JSON: " + json_path)
		return []
	var cache := CachedData.new()
	cache.data = parsed
	ResourceSaver.save(cache, cache_path)
	return parsed

func get_card(id: String) -> Dictionary:
	for c in cards:
		if c.get("id", "") == id:
			return c
	return {}

func get_enemy(id: String) -> Dictionary:
	for e in enemies:
		if e.get("id", "") == id:
			return e
	return {}
