class_name RelicData
extends Resource

enum RelicRarity { STARTER, COMMON, UNCOMMON, RARE, BOSS, SHOP, EVENT }

@export var id: String = ""
@export var relic_name: String = ""
@export var description: String = ""
@export var flavor_text: String = ""
@export var rarity: RelicRarity = RelicRarity.COMMON
@export var champion_id: String = ""           # "" = shared
@export var counter: int = 0                   # Runtime counter (charges, etc.)
@export var active: bool = true

func on_obtain() -> void:
	pass  # Override in subclass or handle via EventBus + id lookup

func on_trigger(context: Dictionary) -> void:
	pass
