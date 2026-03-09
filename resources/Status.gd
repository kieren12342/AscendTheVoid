class_name StatusData
extends Resource

enum StatusType { BUFF, DEBUFF, NEUTRAL }

@export var id: String = ""
@export var status_name: String = ""
@export var description: String = ""
@export var status_type: StatusType = StatusType.DEBUFF
@export var stacks: int = 0
@export var is_stackable: bool = true          # false = on/off (e.g. Artifact)
@export var tick_on_turn_end: bool = true      # Reduce stacks at end of turn
@export var reduces_to_zero: bool = true       # vs. counting up

# Recognised IDs the combat engine checks:
# "vulnerable", "weak", "frail", "strength", "dexterity",
# "poison", "burn", "artifact", "thorns", "metallicize",
# "plated_armor", "buffer", "intangible", "regenerate",
# "ritual", "draw_card", "next_turn_energy", "void_rift"
