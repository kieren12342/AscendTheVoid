extends Control

signal resume_requested
signal main_menu_requested

func _ready() -> void:
	$Overlay/Panel/VBox/ResumeButton.pressed.connect(_on_resume)
	$Overlay/Panel/VBox/MainMenuButton.pressed.connect(_on_main_menu)
	$Overlay/Panel/VBox/QuitButton.pressed.connect(_on_quit)

func _on_resume() -> void:
	get_tree().paused = false
	queue_free()

func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ChampionSelect.tscn")

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume()
