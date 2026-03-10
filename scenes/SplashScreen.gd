extends Control

func _ready() -> void:
	var logo: Label = $Background/LogoLabel
	var subtitle: Label = $Background/SubtitleLabel
	subtitle.modulate.a = 0.0

	# Animate logo color: void purple → white over 1.5s
	var tween := create_tween()
	tween.tween_property(logo, "modulate", Color(1, 1, 1, 1), 1.5).from(Color(0.4, 0.1, 0.8, 1.0))

	# Fade in subtitle after 0.5s
	await get_tree().create_timer(0.5).timeout
	var sub_tween := create_tween()
	sub_tween.tween_property(subtitle, "modulate:a", 1.0, 1.0)

	# After 2.5s total, go to ChampionSelect
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/ChampionSelect.tscn")
