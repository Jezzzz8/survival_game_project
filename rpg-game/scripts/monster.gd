extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2DMonster
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2DMonster
@onready var chase_area: Area2D = $DetectionArea2D
@onready var contact_area: Area2D = $ContactArea2D
@onready var detection_collision: CollisionShape2D = $DetectionArea2D/DetectionCollision
@onready var contact_collision: CollisionShape2D = $ContactArea2D/ContactCollision
@onready var plane_crash: AudioStreamPlayer = $PlaneCrash
@onready var plane_flying: AudioStreamPlayer = $PlaneFlying
@onready var monster_health_bar: ProgressBar = $MonsterHealthBar
@onready var death_icon: TextureRect = $"Death Icon"

@export var max_health: int = 50
@export var hp: int = 50
@export var speed: float = 20
@export var contact_damage: int = 10

var charge_time: float = 1.5
var attack_force: float = 100.0
var attack_duration: float = 1.0
var cooldown_time: float = 3.0
var respawn_point: Vector2
var current_health: int = 50
var player: Node = null
var current_facing: String = "front"
var state: String = "IDLE"
var charge_timer: float = 0.0
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var is_knocked_back: bool = false
var knockback_force: float = 100
var knockback_timer: Timer
var is_dead: bool = false
var has_damaged_this_attack: bool = false

func _ready() -> void:
	add_to_group("Enemy")
	respawn_point = global_position
	
	max_health = Global.monster_max_hp
	hp = Global.monster_hp
	attack_force = Global.monster_attack_force
	contact_damage = Global.monster_contact_damage
	speed = Global.monster_speed
	
	monster_health_bar.max_value = max_health
	monster_health_bar.value = hp
	
	death_icon.visible = false
	
	knockback_timer = Timer.new()
	knockback_timer.wait_time = 0.5
	knockback_timer.one_shot = true
	knockback_timer.connect("timeout", Callable(self, "_on_knockback_timeout")) 
	add_child(knockback_timer)
	
	chase_area.connect("body_entered", Callable(self, "_on_chase_area_body_entered"))
	chase_area.connect("body_exited", Callable(self, "_on_chase_area_body_exited"))
	
	# Connect ContactArea2D's body_entered signal to handle damage application
	contact_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))

func _physics_process(delta: float) -> void:
	if state in ["IDLE", "CHASE", "COOLDOWN", "CHARGING"]:
		contact_area.monitoring = false
	
	if not player:
		# Try to find player again if available
		for body in chase_area.get_overlapping_bodies():
			if body.is_in_group("Player"):
				player = body
				state = "CHASE"
				break

	if not player:
		return
	
	match state:
		"CHASE":
			var distance_to_player = global_position.distance_to(player.global_position)
			if distance_to_player < 20.0:  # Adjust this threshold as needed
				state = "CHARGING"
				plane_flying.play()
				charge_timer = charge_time
				velocity = Vector2.ZERO
				animated_sprite_2d.play(current_facing + " charge")
				return

			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			update_facing_direction()
			play_walk_animation()

		"CHARGING":
			velocity = Vector2.ZERO
			move_and_slide()
			animated_sprite_2d.play(current_facing + " charge")
			charge_timer -= delta
			if charge_timer <= 0:
				state = "ATTACKING"
				attack_timer = attack_duration
				var attack_dir = (player.global_position - global_position).normalized()
				velocity = attack_dir * attack_force
				animated_sprite_2d.play(current_facing + " attack")

		"ATTACKING":
			contact_area.monitoring = true  # Enable hitbox
			move_and_slide()
			attack_timer -= delta
			has_damaged_this_attack = false
			if attack_timer <= 0:
				state = "COOLDOWN"
				velocity = Vector2.ZERO
				contact_area.monitoring = false  # Disable hitbox
				animated_sprite_2d.play(current_facing + " idle")

		"COOLDOWN":
			move_and_slide()
			cooldown_timer -= delta
			if cooldown_timer <= 0:
				state = "CHASE"

func _on_chase_area_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and state in ["IDLE", "COOLDOWN"]:
		player = body
		state = "CHASE"

func _on_chase_area_body_exited(body: Node) -> void:
	if body == player:
		player = null
		state = "IDLE"
		animated_sprite_2d.play("front idle")

func update_facing_direction() -> void:
	var dir = player.global_position - global_position
	if abs(dir.x) > abs(dir.y):
		current_facing = "side"
		animated_sprite_2d.flip_h = dir.x > 0
	else:
		current_facing = "back" if dir.y < 0 else "front"
		animated_sprite_2d.flip_h = false

func play_walk_animation() -> void:
	if current_facing == "side":
		animated_sprite_2d.play("side walk")
	elif current_facing == "back":
		animated_sprite_2d.play("back walk")
	else:
		animated_sprite_2d.play("front walk")

# Handle body entering the contact area for applying damage
func _on_attack_area_body_entered(body: Node) -> void:
	if is_dead or state != "ATTACKING":
		return

	if body.is_in_group("Player") and not has_damaged_this_attack:
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
			has_damaged_this_attack = true
			contact_area.monitoring = false

# Handle knockback effect when the enemy is hit
func apply_knockback(from_position: Vector2, force: float) -> void:
	if not is_knocked_back:
		var direction = (global_position - from_position).normalized()
		velocity += direction * force
		is_knocked_back = true
		knockback_timer.start()

func _on_knockback_timeout() -> void:
	is_knocked_back = false
	velocity = Vector2.ZERO

# Handle taking damage
func take_damage(amount: int):
	hp -= amount
	monster_health_bar.value = hp
	Global.monster_hp = hp
	
	if hp <= 0:
		hp = 0
		is_dead = true
		Global.kills += 1
		speed += 1
		Global.monster_speed = speed
		attack_force += 1
		Global.monster_attack_force = attack_force
		contact_damage += 1
		Global.monster_contact_damage = contact_damage
		die()

func die():
	if not is_dead:
		return
	
	state = "DYING"
	plane_crash.play()
	plane_flying.play()
	detection_collision.disabled = true
	contact_collision.disabled = true
	
	if state == "DYING": 
		hp = Global.monster_max_hp
		current_health = hp
		Global.monster_hp = hp
		monster_health_bar.value = hp
		death_icon.visible = true
		monster_health_bar.visible = false
		await get_tree().create_timer(0.7).timeout
		animated_sprite_2d.play("die")
		
		
		await animated_sprite_2d.animation_finished
		set_physics_process(false)
		set_process(false)
		collision_shape_2d.disabled = true
	
	await get_tree().create_timer(2.0).timeout
	
	respawn()

func respawn() -> void:
	if not is_dead:
		return
	global_position = respawn_point
	
	is_dead = false  # Reset death state
	
	death_icon.visible = false
	monster_health_bar.visible = true
	set_physics_process(true)
	set_process(true)
	
	collision_shape_2d.disabled = false
	detection_collision.disabled = false
	contact_collision.disabled = false
	
	state = "IDLE"
	animated_sprite_2d.play("front idle")
	
	# Re-detect player if they're already inside the chase area
	for body in chase_area.get_overlapping_bodies():
		if body.is_in_group("Player"):
			player = body
			state = "CHASE"
			break
	
	if not chase_area.is_connected("body_entered", Callable(self, "_on_chase_area_body_entered")):
		chase_area.connect("body_entered", Callable(self, "_on_chase_area_body_entered"))
	
	
	if not chase_area.is_connected("body_exited", Callable(self, "_on_chase_area_body_exited")):
		chase_area.connect("body_exited", Callable(self, "_on_chase_area_body_exited"))
