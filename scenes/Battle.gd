extends Node2D

@onready var card_container: HBoxContainer = $UI/Root/HandArea/ScrollContainer/CardContainer
@onready var hp_bar: ProgressBar = $UI/Root/PlayerArea/PlayerRow/ChampionInfo/HPBar
@onready var hp_label: Label = $UI/Root/PlayerArea/PlayerRow/ChampionInfo/HPLabel
@onready var block_label: Label = $UI/Root/PlayerArea/PlayerRow/ChampionInfo/BlockLabel
@onready var energy_label: Label = $UI/Root/PlayerArea/PlayerRow/EnergyBlock/EnergyLabel
@onready var end_turn_btn: Button = $UI/Root/PlayerArea/PlayerRow/EnergyBlock/EndTurnButton
@onready var overlay_label: Label = $UI/Root/OverlayLabel

var card_scene = preload("res://scenes/CardUI.tscn")
var _dragged_card = null
var _drag_origin: Vector2 = Vector2.ZERO
var _player_block: int = 0

# Enemy state
var _enemy_data: Dictionary = {}
var _enemy_hp: int = 0
var _enemy_max_hp: int = 0
var _enemy_block: int = 0
var _enemy_current_intent: Dictionary = {}
var _combat_over: bool = false

func _ready() -> void:
	end_turn_btn.pressed.connect(_on_end_turn)
	InputManager.drag_started.connect(_on_drag_started)
	InputManager.drag_moved.connect(_on_drag_moved)
	InputManager.drag_ended.connect(_on_drag_ended)
	EventBus.hand_updated.connect(_refresh_hand)
	EventBus.energy_changed.connect(_refresh_energy)
	EventBus.champion_hp_changed.connect(_refresh_hp)
	EventBus.block_applied.connect(_refresh_block)
	EventBus.card_played.connect(_on_card_played)
	EventBus.champion_died.connect(_on_defeat)
	_start_combat()

func _start_combat() -> void:
	GameManager.start_run("rift_walker", 0)
	# Pick a random Act 1 non-boss enemy from DataLoader
	var candidates: Array = []
	for enemy in DataLoader.enemies:
		if enemy.get("act", 0) == 1 and not enemy.get("is_boss", false):
			candidates.append(enemy)
	if candidates.is_empty():
		candidates = DataLoader.enemies
	var idx: int = GameManager.rng.randi_range(0, candidates.size() - 1)
	_enemy_data = candidates[idx]
	_enemy_max_hp = GameManager.rng.randi_range(
		_enemy_data.get("max_hp_min", 20),
		_enemy_data.get("max_hp_max", 30)
	)
	_enemy_hp = _enemy_max_hp
	_enemy_block = 0
	_enemy_current_intent = _pick_enemy_intent()
	_refresh_enemy_ui()
	GameManager.start_turn()

func _pick_enemy_intent() -> Dictionary:
	var intents: Array = _enemy_data.get("intents", [])
	if intents.is_empty():
		return {"type": "ATTACK", "damage": 5}
	return intents[GameManager.rng.randi_range(0, intents.size() - 1)]

func _refresh_enemy_ui() -> void:
	var slot1: VBoxContainer = $UI/Root/EnemyArea/EnemyRow/EnemySlot1
	slot1.get_node("NameLabel").text = _enemy_data.get("enemy_name", "Enemy")
	slot1.get_node("IntentLabel").text = _intent_text(_enemy_current_intent)
	var enemy_hp_bar: ProgressBar = slot1.get_node("EnemyHPBar")
	enemy_hp_bar.max_value = _enemy_max_hp
	enemy_hp_bar.value = _enemy_hp
	slot1.get_node("EnemyHPLabel").text = "%d / %d" % [_enemy_hp, _enemy_max_hp]
	slot1.get_node("EnemyBlockLabel").text = "🛡 %d" % _enemy_block

func _intent_text(intent: Dictionary) -> String:
	match intent.get("type", ""):
		"ATTACK":        return "⚔ %d" % intent.get("damage", 0)
		"DEFEND":        return "🛡 %d" % intent.get("block", 0)
		"ATTACK_DEFEND": return "⚔%d 🛡%d" % [intent.get("damage", 0), intent.get("block", 0)]
		"BUFF":          return "✨ Buff"
		"DEBUFF":        return "💀 Debuff"
		_:               return "?"

func _on_card_played(card: CardData, _targets: Array) -> void:
	match card.card_type:
		CardData.CardType.ATTACK:
			var damage: int = card.base_damage
			var leftover: int = max(damage - _enemy_block, 0)
			_enemy_block = max(_enemy_block - damage, 0)
			_enemy_hp -= leftover
			if _enemy_hp <= 0:
				_enemy_hp = 0
				_on_victory()
		CardData.CardType.SKILL, CardData.CardType.POWER:
			var new_block: int = GameManager._player_block + card.base_block
			GameManager._player_block = new_block
			EventBus.block_applied.emit("player", new_block)
	_refresh_enemy_ui()

func _refresh_hand(hand: Array) -> void:
	for child in card_container.get_children():
		child.queue_free()
	for i in hand.size():
		var card_ui = card_scene.instantiate()
		card_container.add_child(card_ui)
		card_ui.setup(hand[i], i)

func _refresh_energy(current: int, maximum: int) -> void:
	energy_label.text = "⚡ %d / %d" % [current, maximum]

func _refresh_hp(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "%d / %d HP" % [current, maximum]

func _refresh_block(_target: String, amount: int) -> void:
	_player_block = amount
	block_label.text = "🛡 %d" % _player_block

func _on_end_turn() -> void:
	if _combat_over:
		return
	end_turn_btn.disabled = true
	GameManager.end_turn()
	# Enemy turn
	var intent_type: String = _enemy_current_intent.get("type", "")
	if intent_type == "ATTACK" or intent_type == "ATTACK_DEFEND":
		var damage: int = _enemy_current_intent.get("damage", 0)
		var leftover: int = max(damage - GameManager._player_block, 0)
		GameManager._player_block = max(GameManager._player_block - damage, 0)
		if leftover > 0:
			GameManager.take_damage(leftover)
	if intent_type == "DEFEND" or intent_type == "ATTACK_DEFEND":
		_enemy_block += _enemy_current_intent.get("block", 0)
	await get_tree().create_timer(0.4).timeout
	if _combat_over:
		return
	_enemy_block = 0
	_enemy_current_intent = _pick_enemy_intent()
	_refresh_enemy_ui()
	end_turn_btn.disabled = false
	GameManager.start_turn()
	_player_block = 0
	block_label.text = "🛡 0"

func _on_victory() -> void:
	_combat_over = true
	end_turn_btn.disabled = true
	overlay_label.text = "⚔ VICTORY!"
	overlay_label.modulate = Color.GREEN
	overlay_label.visible = true

func _on_defeat() -> void:
	_combat_over = true
	end_turn_btn.disabled = true
	overlay_label.text = "💀 DEFEAT"
	overlay_label.modulate = Color.RED
	overlay_label.visible = true

func _on_drag_started(pos: Vector2, _source: String) -> void:
	for card in card_container.get_children():
		if card.get_global_rect().has_point(pos):
			_dragged_card = card
			_drag_origin = card.global_position
			card.z_index = 10
			return

func _on_drag_moved(pos: Vector2, _source: String) -> void:
	if _dragged_card:
		_dragged_card.global_position = pos - _dragged_card.size / 2.0

func _on_drag_ended(pos: Vector2, _source: String) -> void:
	if _dragged_card == null:
		return
	var play_threshold = get_viewport().get_visible_rect().size.y * 0.65
	if pos.y < play_threshold:
		var idx = _dragged_card.card_index
		if not GameManager.play_card(idx, []):
			_snap_back()
	else:
		_snap_back()
	if _dragged_card:
		_dragged_card.z_index = 0
		_dragged_card = null

func _snap_back() -> void:
	if _dragged_card:
		var tween = create_tween()
		tween.tween_property(_dragged_card, "global_position", _drag_origin, 0.15) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
