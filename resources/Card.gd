# CardData resource — one instance per card in the deck.
class_name CardData
extends Resource

enum CardType { ATTACK, SKILL, POWER, CURSE, STATUS }
enum CardRarity { BASIC, COMMON, UNCOMMON, RARE, SPECIAL }
enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SELF, NONE }

@export var id: String = ""
@export var card_name: String = ""
@export var description: String = ""           # Raw template e.g. "Deal !D! damage."
@export var upgraded_description: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var rarity: CardRarity = CardRarity.COMMON
@export var target: TargetType = TargetType.SINGLE_ENEMY
@export var energy_cost: int = 1
@export var upgraded_energy_cost: int = -1     # -1 = no change
@export var is_upgraded: bool = false
@export var exhausts: bool = false
@export var ethereal: bool = false             # Exhaust at end of turn if in hand
@export var innate: bool = false               # Always in opening hand
@export var champion_id: String = ""           # "" = colorless

# Numeric values (used in description substitution)
@export var base_damage: int = 0
@export var base_block: int = 0
@export var base_magic_number: int = 0         # Flexible third number
@export var upgraded_damage: int = -1
@export var upgraded_block: int = -1
@export var upgraded_magic_number: int = -1

# Tags for synergy detection
@export var tags: Array[String] = []

func get_display_description() -> String:
	var desc := upgraded_description if (is_upgraded and upgraded_description != "") else description
	var d := upgraded_damage if (is_upgraded and upgraded_damage >= 0) else base_damage
	var b := upgraded_block if (is_upgraded and upgraded_block >= 0) else base_block
	var m := upgraded_magic_number if (is_upgraded and upgraded_magic_number >= 0) else base_magic_number
	desc = desc.replace("!D!", str(d))
	desc = desc.replace("!B!", str(b))
	desc = desc.replace("!M!", str(m))
	return desc

func get_cost() -> int:
	if is_upgraded and upgraded_energy_cost >= 0:
		return upgraded_energy_cost
	return energy_cost

func duplicate_card() -> CardData:
	return duplicate(true) as CardData
