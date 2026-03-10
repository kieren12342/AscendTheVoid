extends Node2D

@onready var map_vbox: VBoxContainer = $UI/Root/MapScroll/MapVBox
@onready var act_label: Label = $UI/Root/ActLabel
@onready var node_info_label: Label = $UI/Root/NodeInfoLabel

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
	var map := MapGenerator.generate(GameManager.run_seed)
	_build_map_ui(map)

func _build_map_ui(map: Dictionary) -> void:
	for child in map_vbox.get_children():
		child.queue_free()

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
			# For now, heal 15 HP then return to map
			GameManager.heal(15)
			node_info_label.text = "Rested — healed 15 HP"
		"SHOP":
			node_info_label.text = "Shop coming soon!"
		"EVENT":
			node_info_label.text = "Event coming soon!"

func _on_node_selected(_node_data: Dictionary) -> void:
	pass  # handled in _on_map_node_pressed
