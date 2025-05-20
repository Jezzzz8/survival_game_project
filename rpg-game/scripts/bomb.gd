extends Area2D

const Explosion = preload("res://scenes/explosion.tscn")
var explosion_timer: float = 3.0

func _process(delta: float) -> void:
	explosion_timer -= delta
	if explosion_timer <= 0:
		explode()

func explode():
	var explosion = Explosion.instantiate()
	explosion.global_position = global_position  # Set the explosion position
	get_tree().current_scene.add_child(explosion)  # Add explosion to the scene
	queue_free()  # Remove the bomb after it explodes
