extends Node2D

@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var explosion: AudioStreamPlayer = $Explosion

@export var knock_force: int = 100
@export var player_damage: int = 50
@export var monster_damage: int = 50

func _ready() -> void:
	particles.emitting = true
	explosion.play()
	# Perform damage check immediately
	apply_damage_to_players_and_monsters()

	# Destroy explosion node after animation finishes
	await get_tree().create_timer(0.5).timeout
	queue_free()

func apply_damage_to_players_and_monsters():
	var space_state = get_world_2d().direct_space_state
	var shape = collision_shape_2d.shape

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = collision_shape_2d.global_transform
	params.collide_with_bodies = true

	var results = space_state.intersect_shape(params)
	for hit in results:
		if hit.has("collider"):
			# Check if the collider is a Player or Monster and apply effects
			if hit.collider.is_in_group("Player"):
				hit.collider.take_damage(player_damage)  # Player takes damage from explosion
				hit.collider.apply_knockback(global_position, knock_force)  # Apply knockback to the player
			elif hit.collider.is_in_group("Monster"):
				hit.collider.take_damage(monster_damage)  # monster takes damage
				hit.collider.apply_knockback(global_position, knock_force)  # Apply knockback to the monster
