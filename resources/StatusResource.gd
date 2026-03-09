class_name StatusResource
extends Resource

@export var status_id: String = ""
@export var status_name: String = ""
@export var description: String = ""
@export var is_debuff: bool = false
@export var is_stackable: bool = true
@export var icon_path: String = ""
@export var tick_type: String = "turn_end_tick"
@export var effect_script: String = ""