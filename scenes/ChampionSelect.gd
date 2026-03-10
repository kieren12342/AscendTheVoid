extends Control

@onready var title_label: Label = $Layout/TitleLabel
@onready var seed_label: Label = $Layout/SeedLabel

const CHAMPIONS := [
	{
		"id": "void_warden",
		"name": "Void Warden",
		"desc": "Tanky warrior.\nHigh block, draws power from surviving hits.",
		"icon": "🛡",
		"hp": 80,
		"color": Color(0.3, 0.5, 0.9)
	},
	{
		"id": "shadow_lurker",
		"name": "Shadow Lurker",
		"desc": "Poison assassin.\nApplies debuffs and deals damage over time.",
		"icon": "🗡",
		"hp": 70,
		"color": Color(0.5, 0.2, 0.7)
	},
	{
		"id": "plasma_weaver",
		"name": "Plasma Weaver",
		"desc": "Energy mage.\nBuilds up power and unleashes explosive combos.",
		"icon": "⚡",
		"hp": 68,
		"color": Color(0.2, 0.8, 0.9)
	},
	{
		"id": "rift_shaper",
		"name": "Rift Shaper",
		"desc": "Card manipulator.\nDraws extra cards and bends reality.",
		"icon": "🌀",
		"hp": 72,
		"color": Color(0.9, 0.4, 0.2)
	}
]

func _ready() -> void:
	var new_seed := randi()
	seed_label.text = "Seed: %d" % new_seed

	var champion_row: HBoxContainer = $Layout/ChampionRow
	var slots := ["Champion1", "Champion2", "Champion3", "Champion4"]

	for i in range(CHAMPIONS.size()):
		var champ_data := CHAMPIONS[i]
		var slot: VBoxContainer = champion_row.get_node(slots[i])
		var btn: Button = slot.get_node("SelectBtn")
		var name_lbl: Label = slot.get_node("NameLabel")
		var desc_lbl: Label = slot.get_node("DescLabel")

		btn.text = "%s\n%s" % [champ_data.icon, champ_data.name]
		btn.modulate = champ_data.color
		name_lbl.text = "%s\n❤ %d HP" % [champ_data.name, champ_data.hp]
		desc_lbl.text = champ_data.desc

		var champ_id: String = champ_data.id
		var seed_val: int = new_seed
		btn.pressed.connect(func(): _select_champion(champ_id, seed_val))

func _select_champion(champion_id: String, seed_val: int) -> void:
	GameManager.start_run(champion_id, seed_val)
	get_tree().change_scene_to_file("res://scenes/Map.tscn")
