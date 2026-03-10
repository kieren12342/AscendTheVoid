extends Control

@onready var gold_label: Label = $Layout/GoldLabel
@onready var item_row: HBoxContainer = $Layout/ItemRow
@onready var leave_btn: Button = $Layout/LeaveButton

var _on_complete: Callable

func setup(on_complete: Callable) -> void:
	_on_complete = on_complete

func _ready() -> void:
	leave_btn.pressed.connect(_on_leave)
	_refresh_gold()
	_build_shop()

func _refresh_gold() -> void:
	gold_label.text = "💰 Gold: %d" % GameManager.gold

func _build_shop() -> void:
	for child in item_row.get_children():
		child.queue_free()

	# Offer 3 random relics for purchase
	var available_relics := DataLoader.relics.filter(
		func(r): return not RelicManager.has_relic(r.get("id",""))
	)
	available_relics.shuffle()
	var shop_relics := available_relics.slice(0, min(3, available_relics.size()))

	for relic in shop_relics:
		var price := _relic_price(relic.get("rarity","COMMON"))
		var btn := Button.new()
		btn.text = "%s\n%s\n💰 %d Gold" % [
			relic.get("name","?"),
			relic.get("description",""),
			price
		]
		btn.custom_minimum_size = Vector2(160, 130)
		btn.theme_override_font_sizes["font_size"] = 11
		btn.disabled = GameManager.gold < price
		var rid: String = relic.get("id","")
		var p := price
		btn.pressed.connect(func(): _buy_relic(rid, p))
		item_row.add_child(btn)

	# HP potion
	var potion_btn := Button.new()
	potion_btn.text = "❤ HP Potion\nRestore 20 HP\n💰 50 Gold"
	potion_btn.custom_minimum_size = Vector2(160, 130)
	potion_btn.theme_override_font_sizes["font_size"] = 11
	potion_btn.disabled = GameManager.gold < 50
	potion_btn.pressed.connect(_buy_hp_potion)
	item_row.add_child(potion_btn)

func _relic_price(rarity: String) -> int:
	match rarity:
		"COMMON": return 75
		"UNCOMMON": return 110
		"RARE": return 150
		"BOSS": return 200
		_: return 100

func _buy_relic(relic_id: String, price: int) -> void:
	if GameManager.spend_gold(price):
		RelicManager.add_relic(relic_id)
		_refresh_gold()
		_build_shop()

func _buy_hp_potion() -> void:
	if GameManager.spend_gold(50):
		GameManager.heal(20)
		_refresh_gold()
		_build_shop()

func _on_leave() -> void:
	_on_complete.call()
	queue_free()
