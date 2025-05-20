extends Area2D

@export var checkpoint_position: Vector2  # You can set this in the Inspector

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("Player"):
		Global.checkpoint_position = global_position
		body.set_checkpoint(Global.checkpoint_position)
		print("Checkpoint reached at: ", Global.checkpoint_position)
