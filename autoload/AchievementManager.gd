extends Node
# AchievementManager — tracks and unlocks achievements, and accumulates per-run stats.

const ACHIEVEMENT_DEFS := {
	"first_win":       {"name": "First Victory",      "goal": 1},
	"win_streak_3":    {"name": "On a Roll",           "goal": 3},
	"play_50_cards":   {"name": "Card Shark",          "goal": 50},
	"collect_5_relics":{"name": "Relic Hunter",        "goal": 5},
	"reach_boss":      {"name": "Boss Challenger",     "goal": 1},
}

var _achievements: Dictionary = {}

# Per-run stats (reset each run, not persisted)
var run_damage_dealt: int = 0
var run_cards_played: int = 0

func _ready() -> void:
	_load()

func reset_run_stats() -> void:
	run_damage_dealt = 0
	run_cards_played = 0

func check(achievement_id: String, increment: int = 1) -> void:
	if not ACHIEVEMENT_DEFS.has(achievement_id):
		return
	if not _achievements.has(achievement_id):
		_achievements[achievement_id] = {"unlocked": false, "progress": 0, "goal": ACHIEVEMENT_DEFS[achievement_id]["goal"]}
	var entry: Dictionary = _achievements[achievement_id]
	if entry["unlocked"]:
		return
	entry["progress"] = entry["progress"] + increment
	if entry["progress"] >= entry["goal"]:
		entry["unlocked"] = true
		var aname: String = ACHIEVEMENT_DEFS[achievement_id]["name"]
		print("[Achievement Unlocked] %s" % aname)
		EventBus.achievement_unlocked.emit(achievement_id)
	_save()

func is_unlocked(id: String) -> bool:
	if not _achievements.has(id):
		return false
	return _achievements[id].get("unlocked", false)

func _save() -> void:
	SaveSystem.save_key("achievements", _achievements)

func _load() -> void:
	var data = SaveSystem.load_key("achievements")
	if data is Dictionary:
		_achievements = data
