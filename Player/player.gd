extends CharacterBody2D

signal player_died # Signal to announce the player\'s death
signal health_changed(new_health: int) # Signal to announce health changes in player health

var bullet_path = preload("res://Player/bullet2.tscn")
var speed = 200
@export var health = 10
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Animation variables
var original_scale = Vector2(0.087, 0.087)
var idle_animation_speed = 1.0
var moving_animation_speed = 5.0
var current_animation_time = 0.0
var animation_duration = 1.0

func _ready():
	animated_sprite_2d.scale = original_scale

func _physics_process(delta: float) -> void:
	# Stop all processing if the player is dead
	if health <= 0:
		return

	var input_direction = Vector2.ZERO

	if Input.is_action_pressed("right"):
		input_direction.x += 1
		animated_sprite_2d.flip_h = false
	if Input.is_action_pressed("left"):
		input_direction.x -= 1
		animated_sprite_2d.flip_h = true

	if Input.is_action_pressed("down"):
		input_direction.y += 1
	if Input.is_action_pressed("up"):
		input_direction.y -= 1

	velocity = input_direction.normalized() * speed
	move_and_slide()

	# Animation logic...
	if velocity.length() == 0:
		current_animation_time += delta * idle_animation_speed
		var t = fmod(current_animation_time, animation_duration) / animation_duration
		var scale_x_factor = 1.0 + sin(t * PI * 2) * 0.05
		var scale_y_factor = 1.0 - sin(t * PI * 2) * 0.05
		animated_sprite_2d.scale.x = original_scale.x * scale_x_factor
		animated_sprite_2d.scale.y = original_scale.y * scale_y_factor
	else:
		current_animation_time += delta * moving_animation_speed
		var t = fmod(current_animation_time, animation_duration) / animation_duration
		var target_scale_x = original_scale.x * (1.0 + sin(t * PI * 2) * 0.05)
		var target_scale_y = original_scale.y * (1.0 - sin(t * PI * 2) * 0.05)
		var target_scale = Vector2(target_scale_x, target_scale_y)
		animated_sprite_2d.scale = animated_sprite_2d.scale.lerp(target_scale, 0.5)

func fire():
	if health <= 0:
		return
	var bullet = bullet_path.instantiate()
	bullet.dir = rotation
	bullet.pos = $Node2D.global_position
	bullet.rota = global_rotation
	get_parent().add_child(bullet)

func player_takes_damage(amount):
	if health <= 0: # Don\'t take more damage if already dead
		return
	health -= amount
	emit_signal("health_changed", health)
	print("Player health: ", health)
	if health <= 0:
		player_death()

func player_death():
	emit_signal("player_died") # Announce death to other nodes
	queue_free() # Remove the player from the scene
