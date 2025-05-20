extends Control

func _on_start_game_button_button_down() -> void:
	Global.kills = 0
	Global.life = 3
	Global.is_game_over = false
	Global.player_hp = Global.player_max_hp
	
	Global.monster_hp = Global.monster_max_hp
	Global.monster_speed = Global.monster_default_speed
	Global.monster_attack_force = Global.monster_default_attack_force
	Global.monster_contact_damage = Global.monster_default_contact_damage
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_score_board_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/score_board.tscn")

func _on_settings_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_exit_button_button_down() -> void:
	get_tree().quit()
