extends CanvasLayer

@onready var drop: TouchScreenButton = $Control/Drop

func _on_drop_pressed() -> void:
	drop.modulate.a = 0.5

func _on_drop_released() -> void:
	drop.modulate.a = 1.0

func _on_settings_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/ingame_settings.tscn")
