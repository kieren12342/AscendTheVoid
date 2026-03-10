extends Node2D

@onready var map_vbox: VBoxContainer = $UI/Root/MapScroll/MapVBox
@onready var act_label: Label = $UI/Root/ActLabel
@onready var node_info_label: Label = $UI/Root/NodeInfoLabel
@onready var relic_bar: Label = $UI/Root/RelicBar

const NODE_COLORS := {
	"BATTLE": Color(0.8, 0.2, 0.2),
	"ELITE":  Color(0.6, 0.1, 0.8),
	"REST":   Color(0.2, 0.7, 0.3),
	"SHOP":   Color(0.9, 0.7, 0.1),
	"EVENT":  Color(0.2, 0.5, 0.9),
	"BOSS":   Color(1.0, 0.0, 0.0),
}
const NODE_ICONS := {
	"BATTLE": "⚔",
	"ELITE":  "💀",
	"REST":   "🏕",
	"SHOP":   "🛒",
	"EVENT":  "❓",
	"BOSS":   "👁",
}

func _ready() -> void:
	EventBus.map_node_selected.connect(_on_node_selected)
	# Give starter relic if no relics yet
	if RelicManager.active_relics.is_empty():
		var starter_relics := {
			"void_warden": "void_crystal",
			"shadow_lurker": "shadow_pendant",
			"plasma_weaver": "plasma_shard",
			"rift_shaper": "rift_lens",
		}
		var starter := starter_relics.get(GameManager.champion_id, "burning_blood")
		RelicManager.add_relic(starter)
	var map := MapGenerator.generate(GameManager.run_seed)
	_build_map_ui(map)

func _build_map_ui(map: Dictionary) -> void:
	for child in map_vbox.get_children():
		child.queue_free()

	# Update relic display
	var relic_names := RelicManager.active_relics.map(func(r): return r.get("name", r.get("id", "Unknown")))
	if relic_names.is_empty():
		relic_bar.text = "Relics: None"
	else:
		relic_bar.text = "Relics: " + ", ".join(relic_names)

	var floors: Array = map.get("floors", [])
	# Render floors bottom-to-top (floor 0 at bottom)
	for f in range(floors.size() - 1, -1, -1):
		var floor_nodes: Array = floors[f]
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		for node_data in floor_nodes:
			var btn := Button.new()
			var ntype: String = node_data.get("type", "BATTLE")
			btn.text = "%s\n%s" % [NODE_ICONS.get(ntype, "?"), ntype]
			btn.custom_minimum_size = Vector2(120, 80)   # >= 120px — thumb friendly
			btn.theme_override_font_sizes["font_size"] = 14

			var available: bool = node_data.get("available", false)
			var visited: bool = node_data.get("visited", false)

			if visited:
				btn.modulate = Color(0.5, 0.5, 0.5)
				btn.disabled = true
			elif available:
				btn.modulate = NODE_COLORS.get(ntype, Color.WHITE)
				btn.disabled = false
			else:
				btn.modulate = Color(0.3, 0.3, 0.3)
				btn.disabled = true

			# Capture loop vars for closure
			var floor_idx := f
			var col_idx := node_data.get("col", 0)
			btn.pressed.connect(func(): _on_map_node_pressed(floor_idx, col_idx))
			hbox.add_child(btn)

		map_vbox.add_child(hbox)

func _on_map_node_pressed(floor_idx: int, col_idx: int) -> void:
	MapGenerator.select_node(floor_idx, col_idx)
	# Rebuild map UI to reflect new availability
	_build_map_ui(MapGenerator.map_data)
	var floors: Array = MapGenerator.map_data.get("floors", [])
	if floor_idx < 0 or floor_idx >= floors.size() or col_idx >= floors[floor_idx].size():
		return
	var node_data: Dictionary = floors[floor_idx][col_idx]
	var ntype: String = node_data.get("type", "BATTLE")
	node_info_label.text = "Selected: %s %s" % [NODE_ICONS.get(ntype, "?"), ntype]
	# Navigate to appropriate scene
	await get_tree().create_timer(0.3).timeout
	match ntype:
		"BATTLE", "ELITE", "BOSS":
			get_tree().change_scene_to_file("res://scenes/Battle.tscn")
		"REST":
			GameManager.heal(int(GameManager.max_hp * 0.3))
			node_info_label.text = "Rested — healed 30%% HP ❤"
		"EVENT":
			var events := DataLoader.events
			if events.size() > 0:
				var event_data: Dictionary = events.pick_random()
				var event_scene = preload("res://scenes/EventScreen.tscn")
				var event_instance = event_scene.instantiate()
				event_instance.setup(event_data, func(): pass)
				$UI.add_child(event_instance)
		"SHOP":
			var shop_scene = preload("res://scenes/ShopScreen.tscn")
			var shop_instance = shop_scene.instantiate()
			shop_instance.setup(func(): pass)
			$UI.add_child(shop_instance)

func _on_node_selected(_node_data: Dictionary) -> void:
	pass  # handled in _on_map_node_pressed
