extends Control

@onready var cat_laughing_meme_sound_effect: AudioStreamPlayer = $CatLaughingMemeSoundEffect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cat_laughing_meme_sound_effect.play()
	if Global.kills > Global.high_score:
		Global.high_score = Global.kills
		Global.save_high_score()

func _on_go_back_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
