extends Control

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var floor_label: Label = $Panel/VBox/FloorLabel
@onready var damage_label: Label = $Panel/VBox/DamageLabel
@onready var cards_label: Label = $Panel/VBox/CardsLabel
@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var play_again_btn: Button = $Panel/VBox/PlayAgainButton

func _ready() -> void:
	play_again_btn.pressed.connect(_on_play_again)
	title_label.text = "Run Over"
	floor_label.text = "Floor Reached: %d" % GameManager.floor_number
	damage_label.text = "Total Damage Dealt: %d" % AchievementManager.run_damage_dealt
	cards_label.text = "Cards Played: %d" % AchievementManager.run_cards_played
	gold_label.text = "Gold Collected: %d" % GameManager.gold

func _on_play_again() -> void:
	AchievementManager.reset_run_stats()
	get_tree().change_scene_to_file("res://scenes/ChampionSelect.tscn")
