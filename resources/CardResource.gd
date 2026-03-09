class_name CardResource
extends Resource

@export var card_id: String = ""
@export var card_name: String = ""
@export var description: String = ""
@export var upgraded_description: String = ""
@export var cost: int = 1
@export var card_type: String = "attack"
@export var card_rarity: String = "common"
@export var champion_id: String = "any"
@export var is_upgraded: bool = false
@export var is_ethereal: bool = false
@export var is_exhaust: bool = false
@export var is_innate: bool = false
@export var is_retain: bool = false
@export var tags: Array[String] = []
@export var artwork_path: String = ""
@export var effect_script: String = ""