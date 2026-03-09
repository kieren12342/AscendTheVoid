extends Node2D

@onready var card_container: HBoxContainer = $UI/Root/HandArea/CardContainer
@onready var hp_bar: ProgressBar = $UI/Root/PlayerArea/PlayerRow/ChampionInfo/HPBar
@onready var hp_label: Label = $UI/Root/PlayerArea/PlayerRow/ChampionInfo/HPLabel
@onready var block_label: Label = $UI/Root/PlayerArea/PlayerRow/ChampionInfo/BlockLabel
@onready var energy_label: Label = $UI/Root/PlayerArea/PlayerRow/EnergyBlock/EnergyLabel
@onready var end_turn_btn: Button = $UI/Root/PlayerArea/PlayerRow/EnergyBlock/EndTurnButton

var card_scene = preload("res://scenes/CardUI.tscn")
var _dragged_card = null
var _drag_origin: Vector2 = Vector2.ZERO
var _player_block: int = 0

func _ready() -> void:
	end_turn_btn.pressed.connect(_on_end_turn)
	InputManager.drag_started.connect(_on_drag_started)
	InputManager.drag_moved.connect(_on_drag_moved)
	InputManager.drag_ended.connect(_on_drag_ended)
	EventBus.hand_updated.connect(_refresh_hand)
	EventBus.energy_changed.connect(_refresh_energy)
	EventBus.champion_hp_changed.connect(_refresh_hp)
	EventBus.block_applied.connect(_refresh_block)
	_start_combat()

func _start_combat() -> void:
	GameManager.start_run("rift_walker", 12345)
	GameManager.start_turn()

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
	GameManager.end_turn()
	_player_block = 0
	block_label.text = "🛡 0"
	await get_tree().create_timer(0.3).timeout
	GameManager.start_turn()

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

func _intent_text(intent: Dictionary) -> String:
	match intent.get("type", ""):
		"ATTACK": return "⚔ %d" % intent.get("damage", 0)
		"DEFEND": return "🛡 %d" % intent.get("block", 0)
		"BUFF":   return "✨ Buff"
		"DEBUFF": return "💀 Debuff"
		_:        return "?"
