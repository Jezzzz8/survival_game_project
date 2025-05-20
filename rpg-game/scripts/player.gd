extends CharacterBody2D

const Bomb = preload("res://scenes/bomb.tscn")
const EXPLOSION = preload("res://scenes/explosion.tscn")

@onready var dying_sound: AudioStreamPlayer = $DyingSound
@onready var explosion: AudioStreamPlayer = $Explosion
@onready var animated_sprite_2d = $AnimatedSprite2DPlayer2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2DPlayer
@onready var health_bar: ProgressBar = $PlayerHealthBar
@onready var plane_crash: AudioStreamPlayer = $PlaneCrash
@onready var plane_flying: AudioStreamPlayer = $PlaneFlying
@onready var death_icon: TextureRect = $"Death Icon"

@export var max_health: int = 100
@export var hp: int = 100  # Set the initial HP (can be adjusted based on your game)
@export var speed: float = 50

var life: int = 3
var current_direction: String = "front"
var can_drop: bool = true
var bomb_drop_timer: float = 0.0
var current_health: int = max_health
var respawn_point: Vector2 = Global.checkpoint_position
var is_dead: bool = false
var is_knocked_back: bool = false  # Flag to track knockback state
var knockback_timer: Timer  # Timer for knockback duration
var current_position: Vector2
var game_over: bool = false

# Add this once in _ready to ensure player is in the group
func _ready() -> void:
	add_to_group("Player")
	current_position = Global.player_current_position
	
	current_position = global_position
	
	global_position = current_position
	
	max_health = Global.player_max_hp
	hp = Global.player_hp
	
	life = Global.life
	
	game_over = Global.is_game_over
	
	death_icon.visible = false
	
	bomb_drop_timer = Global.player_bomb_cd
	can_drop = bomb_drop_timer <= 0
	current_direction = Global.player_direction
	animated_sprite_2d.play(Global.player_animation)
	
	health_bar.max_value = max_health
	health_bar.value = hp
	
	
	knockback_timer = Timer.new()
	knockback_timer.wait_time = 0.5
	knockback_timer.one_shot = true
	knockback_timer.connect("timeout", Callable(self, "_on_knockback_timeout"))
	add_child(knockback_timer)

func _physics_process(delta: float) -> void:
	get_input()
	player_animation()
	move_and_slide()  # No arguments now
	velocity = velocity.move_toward(Vector2.ZERO, speed * delta)  # Apply friction (optional)
	drop_bomb()
	update_bomb_timer(delta)
	apply_knockback_effect(delta)  # Apply knockback effect if needed
	
func apply_knockback(from_position: Vector2, force: float) -> void:
	if not is_knocked_back:  # Prevent knockback stacking
		var direction = (global_position - from_position).normalized()
		velocity += direction * force
		is_knocked_back = true  # Activate knockback state
		knockback_timer.start()  # Start the knockback timer

# This function will be called when the knockback timer times out
func _on_knockback_timeout() -> void:
	is_knocked_back = false  # End knockback state
	velocity = Vector2.ZERO  # Stop velocity after knockback

func apply_knockback_effect(delta: float):
	if is_knocked_back:
		velocity = velocity.move_toward(Vector2.ZERO, 50 * delta)  # Apply friction to knockback
		# You can add any other logic to handle the knockback state more smoothly

func get_input():
	if not is_knocked_back:  # Prevent input during knockback
		var input_direction = Input.get_vector("go_left", "go_right", "go_up", "go_down")
		if input_direction != Vector2.ZERO:
			velocity = input_direction * speed

func drop_bomb():
	if not is_knocked_back and Input.is_action_just_pressed("drop") and can_drop:
		var drop_offset = Vector2.ZERO

		match current_direction:
			"down": 
				drop_offset = Vector2(0, 22)
				animated_sprite_2d.play("front attack")
			"up": 
				drop_offset = Vector2(0, -22)
				animated_sprite_2d.play("back attack")
			"left": 
				drop_offset = Vector2(-22, 0)
				animated_sprite_2d.play("side attack")
			"right": 
				drop_offset = Vector2(22, 0)
				animated_sprite_2d.play("side attack")
		
		var bomb_pos = global_position + drop_offset
		
		# Bomb is now always placed without checking for collisions
		can_drop = false
		var bomb = Bomb.instantiate()
		bomb.global_position = bomb_pos
		get_tree().current_scene.add_child(bomb)
		bomb_drop_timer = 3

func update_bomb_timer(delta: float):
	if not can_drop:
		bomb_drop_timer -= delta
		if bomb_drop_timer <= 0:
			can_drop = true

# Function to apply damage to the player
func take_damage(amount: int) -> void:
	hp -= amount  # Decrease the player's health by the damage amount
	health_bar.value = hp
	Global.player_hp = hp
	if hp <= 0:
		_game_over()
		dying()  # Call die() if HP drops to 0 or below

# Player death logic
func dying():
	if is_dead:
		return
	is_dead = true
	
	life -= 1
	Global.life = life
	
	dying_sound.play()
	plane_flying.play()
	animated_sprite_2d.play("dying")
	set_physics_process(false)
	set_process(false)
	collision_shape_2d.disabled = true
	plane_crash.play()
	health_bar.visible = false
	death_icon.visible = true
	hp = Global.player_max_hp
	current_health = hp
	Global.player_hp = hp
	health_bar.value = hp
	await get_tree().create_timer(1.0).timeout
	
	var effect = EXPLOSION.instantiate()
	effect.global_position = global_position
	get_parent().add_child(effect)
	explosion.play()
	
	await animated_sprite_2d.animation_finished
	await get_tree().create_timer(2.0).timeout
	respawn()

func respawn() -> void:
	is_dead = false
	global_position = Global.checkpoint_position
	
	health_bar.visible = true
	death_icon.visible = false
	set_physics_process(true)
	set_process(true)
	collision_shape_2d.disabled = false
	current_direction = "front"
	animated_sprite_2d.play("front idle")

	# Optional: force re-trigger monster detection
	for body in get_tree().get_nodes_in_group("Enemy"):
		if body.has_method("_on_chase_area_body_entered"):
			body._on_chase_area_body_entered(self)

func set_checkpoint(_new_point: Vector2) -> void:
	respawn_point = Global.checkpoint_position

func _game_over():
	if game_over:
		return

	if life <= 0:
		await get_tree().create_timer(1).timeout
		
		game_over = true
		Global.is_game_over = game_over
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func player_animation():
	if velocity.length() == 0:
		match current_direction:
			"right":
				animated_sprite_2d.play("side idle")
				animated_sprite_2d.flip_h = false
			"left":
				animated_sprite_2d.play("side idle")
				animated_sprite_2d.flip_h = true
			"up":
				animated_sprite_2d.play("back idle")
			"down":
				animated_sprite_2d.play("front idle")
		return

	if velocity.y < 0:
		if velocity.x != 0:
			animated_sprite_2d.play("side walk")
			animated_sprite_2d.flip_h = velocity.x < 0
			current_direction = "left" if velocity.x < 0 else "right"
		else:
			animated_sprite_2d.play("back walk")
			current_direction = "up"
	elif velocity.y > 0:
		if velocity.x != 0:
			animated_sprite_2d.play("side walk")
			animated_sprite_2d.flip_h = velocity.x < 0
			current_direction = "left" if velocity.x < 0 else "right"
		else:
			animated_sprite_2d.play("front walk")
			current_direction = "down"
	elif velocity.x != 0:
		animated_sprite_2d.play("side walk")
		animated_sprite_2d.flip_h = velocity.x < 0
		current_direction = "left" if velocity.x < 0 else "right"
		
func save_player_state():
	Global.player_hp = hp
	Global.player_max_hp = max_health
	Global.player_direction = current_direction
	Global.player_animation = animated_sprite_2d.animation
	Global.player_bomb_cd = bomb_drop_timer
