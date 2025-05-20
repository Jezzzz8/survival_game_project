extends Node

var high_score: int = 0
var kills: int = 0

# player variable
var checkpoint_position: Vector2 = Vector2(576, 320)  # Default starting checkpoint
var life: int = 3
var is_game_over: bool = false
var player_hp: int = 100
var player_max_hp: int = 100
var player_direction: String = "front"
var player_animation: String = "front idle"
var player_bomb_cd: float = 0.0
var player_current_position: Vector2

# monster variable
var monster_hp: int = 50
var monster_max_hp: int = 50

var monster_speed: int = 30
var monster_default_speed: int = 30

var monster_attack_force: int = 100
var monster_default_attack_force: int = 100

var monster_contact_damage: int = 10
var monster_default_contact_damage: int = 10


func _ready():
	load_high_score()

func save_high_score():
	var file = FileAccess.open("user://high_score.save", FileAccess.WRITE)
	file.store_32(high_score)
	file.close()

func load_high_score():
	if FileAccess.file_exists("user://high_score.save"):
		var file = FileAccess.open("user://high_score.save", FileAccess.READ)
		high_score = file.get_32()
		file.close()
