extends CharacterBody2D

@onready var animation_timer: Timer = $"animation Timer"
@onready var damage_timer: Timer = $"damage timer"
@onready var slime: Sprite2D = $Slime
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal died

@export var speed = 65.0
@export var health = 1
@export var damage_amount = 1
@export var damage_delay: float = 0.5  # Delay before first damage

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var crystal_scene = preload("res://Collectabel objects/crystal.tscn")
var player_node: Node2D = null
var can_attack_anim: bool = false
var is_player_in_range: bool = false
var can_damage_player: bool = true

# Animation variables - adjusted for scale (0.2, 0.2)
var original_scale = Vector2(0.2, 0.2)
var moving_animation_speed = 0.75
var current_animation_time = 0.0
var animation_duration = 1.0

func _ready():
	player_node = get_tree().get_first_node_in_group("PlayerGroup")
	if player_node == null:
		print("Enemy AI: Error: Player node not found in \"PlayerGroup\".")
		return
	else:
		print("Enemy AI: Player node found: ", player_node.name)

	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	
	# Connect timer signals once
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	animation_timer.timeout.connect(_on_animation_timer_timeout)

func _physics_process(_delta: float) -> void:
	if player_node == null:
		return
	
	# Handle movement
	if can_attack_anim:
		velocity = Vector2.ZERO
	else:
		navigation_agent.target_position = player_node.global_position
		
		if navigation_agent.is_navigation_finished():
			velocity = Vector2.ZERO
			slime.scale = slime.scale.lerp(original_scale, 0.1)
			current_animation_time = 0.0
			return
		
		var current_agent_position: Vector2 = global_position
		var next_path_position: Vector2 = navigation_agent.get_next_path_position()
		velocity = current_agent_position.direction_to(next_path_position) * speed
		move_and_slide()
	
	# Handle sprite flipping
	if player_node.global_position.x < global_position.x:
		slime.flip_h = true
	else:
		slime.flip_h = false
	
	# Squish and stretch animation - adjusted for smaller scale
	if velocity.length() > 0:
		current_animation_time += _delta * moving_animation_speed
		var t = fmod(current_animation_time, animation_duration) / animation_duration
		var scale_x_factor = 1.0 + sin(t * PI * 2) * 0.18
		var scale_y_factor = 1.0 - sin(t * PI * 2) * 0.18
		var target_scale = Vector2(original_scale.x * scale_x_factor, original_scale.y * scale_y_factor)
		slime.scale = slime.scale.lerp(target_scale, 0.5)

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	animation_player.play("hit-Flash")
	died.emit()
	print("Enemy died!")
	
	# Check if wave ended by timeout before dropping crystal
	var wave_manager = get_meta("wave_manager", null)
	if wave_manager == null or not wave_manager.did_wave_end_by_timeout():
		drop_crystal()
	
	queue_free()

# New function to die without dropping crystal
func die_without_crystal():
	died.emit()
	print("Enemy died without dropping crystal!")
	queue_free()

func drop_crystal():
	var crystal_instance = crystal_scene.instantiate()
	get_parent().add_child(crystal_instance)
	crystal_instance.global_position = global_position

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		is_player_in_range = true
		can_attack_anim = true
		
		# Start damage timer with delay for first damage
		if can_damage_player:
			damage_timer.start(damage_delay)  # Start with initial delay

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		is_player_in_range = false
		damage_timer.stop()
		animation_timer.start()  # Give time for attack animation to finish

func _on_damage_timer_timeout():
	if is_player_in_range and player_node != null and can_damage_player:
		player_node.player_takes_damage(damage_amount)
		print("Player took damage after delay!")
		
		# After first damage, set timer to normal interval for subsequent damage
		can_damage_player = false
		damage_timer.wait_time = 1.0  # Set to your desired interval between damages
		damage_timer.start()  # Restart with new interval
	elif is_player_in_range and player_node != null:
		# Subsequent damage applications
		player_node.player_takes_damage(damage_amount)
		print("Player took periodic damage!")

func _on_animation_timer_timeout():
	if not is_player_in_range:
		can_attack_anim = false
		can_damage_player = true  # Reset damage cooldown when player leaves
		damage_timer.wait_time = damage_delay  # Reset to initial delay for next encounter
