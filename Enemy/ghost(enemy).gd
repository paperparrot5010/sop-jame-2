extends CharacterBody2D
@onready var ghost: Sprite2D = $Ghost
var damage_amount = 2
@onready var flash_animation_player: AnimationPlayer = $Flash_AnimationPlayer

# Particle effects
@export var green_death_particles: PackedScene = preload("res://particles/green_explosion.tscn")

# Crystal dropping
var crystal_scene = preload("res://Collectabel objects/crystal.tscn")

# Signals
signal died

# Health properties
var max_health = 2
var current_health = max_health

# Navigation properties
var navigation_agent: NavigationAgent2D
var player_target: CharacterBody2D = null

# Movement properties
var speed = 70

# Attack properties
var can_move: bool = true
var is_attacking: bool = false
var attack_timer: Timer
var attack_cooldown: float = 0.5  # Time between attacks
var stop_duration: float = 0.7    # Time to stop moving when player enters area

# References
@onready var health_bar: TextureProgressBar = $TextureProgressBar
@onready var animation_player = $AnimationPlayer
@onready var navigation_timer = $"Navigaion Timer"
@onready var detection_area = $DetectionArea

func _ready():
	print("Enemy ready - setting up navigation")
	
	# Initialize health
	current_health = max_health
	
	# Get navigation agent
	navigation_agent = $NavigationAgent2D
	if navigation_agent:
		print("NavigationAgent2D found")
		# Set navigation parameters like the working script
		navigation_agent.path_desired_distance = 4.0
		navigation_agent.target_desired_distance = 4.0
		# Connect navigation agent signals
		navigation_agent.velocity_computed.connect(_on_velocity_computed)
	else:
		print("ERROR: NavigationAgent2D not found!")
	
	# Setup TextureProgressBar for health
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false
	else:
		print("Health bar not found!")
	
	# Find player using the same method as working script
	player_target = get_tree().get_first_node_in_group("PlayerGroup")
	if player_target == null:
		print("Enemy AI: Error: Player node not found in \"PlayerGroup\".")
	else:
		print("Enemy AI: Player node found: ", player_target.name)
	
	# Connect and start the navigation timer
	if navigation_timer:
		if not navigation_timer.timeout.is_connected(_on_navigation_timer_timeout):
			navigation_timer.timeout.connect(_on_navigation_timer_timeout)
		navigation_timer.start()
		print("Navigation timer started")
	else:
		print("ERROR: Navigation Timer not found!")
	
	# Setup attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	# Connect detection area signals
	if detection_area:
		if not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
			detection_area.body_entered.connect(_on_detection_area_body_entered)
		if not detection_area.body_exited.is_connected(_on_detection_area_body_exited):
			detection_area.body_exited.connect(_on_detection_area_body_exited)
		print("Detection area signals connected")
	else:
		print("ERROR: DetectionArea not found!")
	
	print("Enemy setup complete")

func _physics_process(delta):
	if not player_target or not navigation_agent or not can_move:
		return
	
	# Set target position like the working script
	navigation_agent.target_position = player_target.global_position
	
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	
	# Get movement direction like the working script
	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	velocity = current_agent_position.direction_to(next_path_position) * speed
	
	# Use navigation agent's avoidance if enabled
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(velocity)
	else:
		move_and_slide()
	
	# Update animation based on movement
	update_animation(velocity)
	
	# Flip sprite based on player position like the working script
	if player_target.global_position.x < global_position.x:
		ghost.flip_h = false
	else:
		ghost.flip_h = true

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()
	update_animation(velocity)

func update_animation(movement_vector: Vector2):
	if animation_player:
		if is_attacking:
			# Play attack animation if available
			if animation_player.has_animation("attack"):
				animation_player.play("attack")
			elif animation_player.has_animation("hurt"):
				animation_player.play("hurt")
		elif movement_vector.length() > 0.1:
			if animation_player.has_animation("walk"):
				animation_player.play("walk")
			elif animation_player.has_animation("move"):
				animation_player.play("move")
		else:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")

func _on_navigation_timer_timeout():
	# Periodically update the path to player
	if player_target and navigation_agent and can_move:
		navigation_agent.target_position = player_target.global_position
		print("Timer: Updating navigation target to: ", player_target.global_position)

func take_damage(amount: int):
	flash_animation_player.play("flash-anim")
	print("Enemy took damage: ", amount)
	current_health -= amount
	current_health = max(0, current_health)
	
	# EMIT GLOBAL SIGNAL FOR DAMAGE
	if GlobalSignals.has_signal("enemy_damaged"):
		GlobalSignals.enemy_damaged.emit()
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = true
		
		if current_health > 0:
			var hide_timer = get_tree().create_timer(2.0)
			hide_timer.timeout.connect(_hide_health_bar)
	
	# Play hurt animation
	if animation_player and animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	
	if current_health <= 0:
		die()

func die():
	print("Ghost enemy died")
	velocity = Vector2.ZERO
	can_move = false
	is_attacking = false
	attack_timer.stop()
	
	# Create purple explosion particles
	if green_death_particles:
		var particle_instance = green_death_particles.instantiate()
		particle_instance.global_position = global_position
		
		# Add to scene first
		get_tree().current_scene.add_child(particle_instance)
		
		# Handle different particle types and configure for one shot
		if particle_instance is CPUParticles2D:
			# Configure for one shot emission
			particle_instance.one_shot = true
			particle_instance.emitting = true
			# Auto-destroy after 1 second
			get_tree().create_timer(1.0).timeout.connect(func(): particle_instance.queue_free())
			print("CPUParticles2D ghost death effect created (one shot)")
		elif particle_instance is GPUParticles2D:
			# Configure for one shot emission
			particle_instance.one_shot = true
			particle_instance.emitting = true
			# Auto-destroy after 1 second
			get_tree().create_timer(1.0).timeout.connect(func(): particle_instance.queue_free())
			print("GPUParticles2D ghost death effect created (one shot)")
		else:
			print("Unknown particle type: ", particle_instance.get_class())
			# Fallback: auto-destroy after 1 second
			get_tree().create_timer(1.0).timeout.connect(func(): particle_instance.queue_free())
	else:
		print("ERROR: purple_death_particles not loaded for ghost!")
	
	# Emit died signal for wave manager
	died.emit()
	
	# EMIT GLOBAL SIGNAL FOR DEATH
	if GlobalSignals.has_signal("enemy_killed"):
		GlobalSignals.enemy_killed.emit()
	
	# Drop crystal (check if wave ended by timeout like regular enemy)
	var wave_manager = get_meta("wave_manager", null)
	if wave_manager == null or not wave_manager.did_wave_end_by_timeout():
		drop_crystal()
	
	if health_bar:
		health_bar.visible = false
	
	if animation_player and animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	else:
		await get_tree().create_timer(0.1).timeout
	
		queue_free()

func _hide_health_bar():
	if health_bar and current_health > 0:
		health_bar.visible = false

func drop_crystal():
	var crystal_instance = crystal_scene.instantiate()
	get_parent().add_child(crystal_instance)
	crystal_instance.global_position = global_position

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		print("Player entered detection area - starting attack sequence")
		# Stop moving
		can_move = false
		is_attacking = true
		velocity = Vector2.ZERO
		
		# Play attack animation
		update_animation(Vector2.ZERO)
		
		# Deal initial damage
		body.player_takes_damage(damage_amount)
		print("Initial damage dealt to player")
		
		# Start attack timer for repeated attacks
		attack_timer.start()
		
		# Start movement cooldown timer
		var move_cooldown = get_tree().create_timer(stop_duration)
		move_cooldown.timeout.connect(_on_move_cooldown_timeout)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		print("Player left detection area - stopping attacks")
		# Stop attacking and resume movement
		is_attacking = false
		can_move = true
		attack_timer.stop()
		update_animation(velocity)

func _on_attack_timer_timeout():
	if is_attacking and player_target and is_instance_valid(player_target):
		print("Dealing periodic damage to player")
		player_target.player_takes_damage(damage_amount)
		
		# Play attack animation
		if animation_player and animation_player.has_animation("attack"):
			animation_player.play("attack")

func _on_move_cooldown_timeout():
	# Allow movement again after stop duration
	if is_attacking:  # Only allow movement if still attacking (player still in area)
		can_move = true
		print("Movement cooldown ended - can move while attacking")

# Debug function to check if navigation is working
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		print("=== DEBUG INFO ===")
		print("Player target: ", player_target)
		print("Navigation agent: ", navigation_agent)
		print("Can move: ", can_move)
		print("Is attacking: ", is_attacking)
		if player_target:
			print("Player position: ", player_target.global_position)
			print("Player groups: ", player_target.get_groups())
		print("Enemy position: ", global_position)
		if navigation_agent:
			print("Navigation finished: ", navigation_agent.is_navigation_finished())
			print("Target position: ", navigation_agent.target_position)
		print("Navigation timer: ", navigation_timer)
