extends CharacterBody2D
signal died
@export var speed = 70.0
@export var health = 1 # Example health
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var damage_amount = 1
var player_node: Node2D = null
var crystal_scene = preload("res://Collectabel objects/crystal.tscn")

# Animation variables
var original_scale = Vector2(3.0, 3.0) # Corrected default scale for enemy
var moving_animation_speed = 0.75 # Adjusted speed of the squish/stretch animation when moving (slower)
var current_animation_time = 0.0
var animation_duration = 1.0 # Duration of one full squish/stretch cycle

func _ready():
	player_node = get_tree().get_first_node_in_group("PlayerGroup")
	if player_node == null:
		print("Enemy AI: Error: Player node not found in \"PlayerGroup\".")
		return
	else:
		print("Enemy AI: Player node found: ", player_node.name)

	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

	# Initialize original_scale based on the actual sprite scale if it\"s not 1.0, 1.0
	# For now, we\"ll assume 1.0, 1.0 as a placeholder or you can set it in the editor.
	# If your enemy sprite has a different default scale, adjust this line:
	# original_scale = animated_sprite_2d.scale

func _physics_process(_delta: float) -> void:
	animated_sprite_2d.play("Run")

	if player_node.global_position.x < global_position.x:
		animated_sprite_2d.flip_h = false
	else:
		animated_sprite_2d.flip_h = true
	
	if player_node == null:
		return

	navigation_agent.target_position = player_node.global_position

	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		# Reset scale when not moving (or reached target)
		animated_sprite_2d.scale = animated_sprite_2d.scale.lerp(original_scale, 0.1)
		current_animation_time = 0.0 # Reset animation time
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * speed
	move_and_slide()

	# Squish and stretch animation logic for moving enemy
	current_animation_time += _delta * moving_animation_speed
	var t = fmod(current_animation_time, animation_duration) / animation_duration

	# Simple sine wave for squish and stretch
	var scale_x_factor = 1.0 + sin(t * PI * 2) * 0.18 # Adjusted for increased intensity
	var scale_y_factor = 1.0 - sin(t * PI * 2) * 0.18 # Adjusted for increased intensity

	var target_scale_x = original_scale.x * scale_x_factor
	var target_scale_y = original_scale.y * scale_y_factor
	var target_scale = Vector2(target_scale_x, target_scale_y)

	animated_sprite_2d.scale = animated_sprite_2d.scale.lerp(target_scale, 0.5)

func take_damage(amount):
	health -= amount
	#print("Enemy took ", amount, " damage. Health: ", health)
	if health <= 0:
		die()

func die():
	died.emit()
	print("Enemy died!")
	drop_crystal()
	queue_free()

func drop_crystal():
	var crystal_instance = crystal_scene.instantiate()
	get_parent().add_child(crystal_instance)
	crystal_instance.global_position = global_position


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		body.player_takes_damage(1)
