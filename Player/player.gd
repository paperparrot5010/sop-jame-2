extends CharacterBody2D
var bullet_path = preload("res://Player/bullet2.tscn")
var speed = 200
@export var health = 10
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Animation variables
var original_scale = Vector2(0.087, 0.087) # Assuming this is the original scale
var idle_animation_speed = 1.0 # Speed of the squish/stretch animation when idle
var moving_animation_speed = 5.0 # Speed of the squish/stretch animation when moving
var current_animation_time = 0.0
var animation_duration = 1.0 # Duration of one full squish/stretch cycle

func _ready():
	animated_sprite_2d.scale = original_scale

func _physics_process(delta: float) -> void:

	#look_at(get_global_mouse_position())
	#if Input.is_action_just_pressed("shoot"):
		#fire()
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

	# Squish and stretch animation logic
	if velocity.length() == 0: # Only animate when idle
		current_animation_time += delta * idle_animation_speed
		var t = fmod(current_animation_time, animation_duration) / animation_duration

		# Simple sine wave for squish and stretch
		var scale_x_factor = 1.0 + sin(t * PI * 2) * 0.05 # Adjusted for smaller intensity
		var scale_y_factor = 1.0 - sin(t * PI * 2) * 0.05 # Adjusted for smaller intensity

		animated_sprite_2d.scale.x = original_scale.x * scale_x_factor
		animated_sprite_2d.scale.y = original_scale.y * scale_y_factor
	else:
		# Animate faster when moving
		current_animation_time += delta * moving_animation_speed
		var t = fmod(current_animation_time, animation_duration) / animation_duration

		# Simple sine wave for squish and stretch (can be adjusted for moving animation)
		var target_scale_x = original_scale.x * (1.0 + sin(t * PI * 2) * 0.05)
		var target_scale_y = original_scale.y * (1.0 - sin(t * PI * 2) * 0.05)
		var target_scale = Vector2(target_scale_x, target_scale_y)

		animated_sprite_2d.scale = animated_sprite_2d.scale.lerp(target_scale, 0.5)


func fire():
	var bullet = bullet_path.instantiate()
	bullet.dir = rotation
	bullet.pos = $Node2D.global_position
	bullet.rota = global_rotation
	get_parent().add_child(bullet)
func player_death():
	queue_free()
	
func player_takes_damage(amount):
	health -= amount
	print (health)
	if health <= 0:
		player_death()
	
