class_name ChampionData
extends Resource

@export var id: String = ""
@export var champion_name: String = ""
@export var lore: String = ""
@export var max_hp: int = 75
@export var starting_gold: int = 99
@export var base_energy: int = 3
@export var starting_relic_id: String = ""
@export var starting_deck_ids: Array[String] = []   # card IDs
@export var color: Color = Color.WHITE
