extends Control

@onready var high_score_label: Label = $"CanvasLayer/Score Board/VBoxContainer/HBoxContainer/HighScore Label"
@onready var current_score_label: Label = $"CanvasLayer/Score Board/VBoxContainer/HBoxContainer2/CurrentScoreLabel"

func _process(_delta):
	update_score_display()

func update_score_display():
	# Always show current score
	current_score_label.text = str(Global.kills)
	
	# Check and update high score if current score exceeds it
	if Global.kills > Global.high_score:
		Global.high_score = Global.kills
	
	# Update high score label
	high_score_label.text = str(Global.high_score)

func _on_go_back_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
