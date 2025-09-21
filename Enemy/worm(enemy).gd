extends CharacterBody2D
@onready var health_bar: TextureProgressBar = $TextureProgressBar
@onready var flash_animation_player: AnimationPlayer = $Flash_AnimationPlayer

# Health and basic properties
@export var health: int = 3
@export var damage_amount: int = 2

# Particle effects
@export var purple_death_particles: PackedScene = preload("res://particles/purple_explosion.tscn")

# Crystal dropping
var crystal_scene = preload("res://Collectabel objects/crystal.tscn")

# Laser attack system
var worm_laser_scene = preload("res://Enemy/worm_lazer.tscn")
var laser_timer: Timer
var laser_attack_interval: float = 3.0  # Fire laser every 3 seconds

# Player tracking
var player_node: Node2D = null

# Movement (worms move slowly or stay stationary)
@export var speed: float = 20.0  # Very slow movement
var original_position: Vector2
var wander_radius: float = 50.0  # Small area to wander in
var wander_target: Vector2
var wander_timer: Timer

# Signals
signal died

func _ready():
	print("Worm enemy spawned")
	
	# Store original position for wandering
	original_position = global_position
	wander_target = global_position
	
	# Find player
	player_node = get_tree().get_first_node_in_group("PlayerGroup")
	if not player_node:
		print("Worm Error: Player not found in PlayerGroup")
	
	# Setup laser attack timer
	laser_timer = Timer.new()
	laser_timer.wait_time = laser_attack_interval
	laser_timer.one_shot = false
	laser_timer.timeout.connect(_on_laser_timer_timeout)
	add_child(laser_timer)
	laser_timer.start()
	
	# Setup wander timer
	wander_timer = Timer.new()
	wander_timer.wait_time = 2.0  # Change wander target every 2 seconds
	wander_timer.one_shot = false
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	add_child(wander_timer)
	wander_timer.start()
	
	print("Worm will fire lasers every ", laser_attack_interval, " seconds")

func _physics_process(delta: float) -> void:
	if not player_node or health <= 0:
		return
	
	# Simple wandering movement (worms don't chase aggressively)
	var direction = (wander_target - global_position).normalized()
	if global_position.distance_to(wander_target) > 10.0:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _on_laser_timer_timeout():
	# Fire laser toward player
	if player_node and is_instance_valid(player_node) and health > 0:
		fire_laser_at_player()

func _on_wander_timer_timeout():
	# Choose new random position within wander radius
	var angle = randf() * 2 * PI
	var distance = randf() * wander_radius
	wander_target = original_position + Vector2(cos(angle), sin(angle)) * distance

func fire_laser_at_player():
	if not worm_laser_scene or not player_node:
		return
	
	# Create laser instance
	var laser_instance = worm_laser_scene.instantiate()
	get_tree().current_scene.add_child(laser_instance)
	
	# Initialize the laser with start position and target
	laser_instance.initialize(global_position, player_node.global_position)
	
	print("Worm fired laser at player!")

func take_damage(amount: int):
	flash_animation_player.play("flash-anim")
	health -= amount
	print("Worm took ", amount, " damage. Health: ", health)
	
	# EMIT GLOBAL SIGNAL FOR DAMAGE
	if GlobalSignals.has_signal("enemy_damaged"):
		GlobalSignals.enemy_damaged.emit()
	
	if health <= 0:
		die()

func die():
	print("Worm died!")
	
	# Stop timers
	if laser_timer:
		laser_timer.stop()
	if wander_timer:
		wander_timer.stop()
	
	# Create purple explosion particles
	if purple_death_particles:
		var particle_instance = purple_death_particles.instantiate()
		get_tree().current_scene.add_child(particle_instance)
		particle_instance.global_position = global_position
		
		# Handle different particle types and configure for one shot
		if particle_instance is CPUParticles2D:
			particle_instance.one_shot = true
			particle_instance.emitting = true
			get_tree().create_timer(1.0).timeout.connect(func(): particle_instance.queue_free())
			print("CPUParticles2D worm death effect created (one shot)")
		elif particle_instance is GPUParticles2D:
			particle_instance.one_shot = true
			particle_instance.emitting = true
			get_tree().create_timer(1.0).timeout.connect(func(): particle_instance.queue_free())
			print("GPUParticles2D worm death effect created (one shot)")
		else:
			get_tree().create_timer(1.0).timeout.connect(func(): particle_instance.queue_free())
	else:
		print("ERROR: purple_death_particles not loaded for worm!")
	
	# Emit died signal for wave manager
	died.emit()
	
	# EMIT GLOBAL SIGNAL FOR DEATH
	if GlobalSignals.has_signal("enemy_killed"):
		GlobalSignals.enemy_killed.emit()
	
	# Drop crystal (check if wave ended by timeout like other enemies)
	var wave_manager = get_meta("wave_manager", null)
	if wave_manager == null or not wave_manager.did_wave_end_by_timeout():
		drop_crystal()
	
	queue_free()

func drop_crystal():
	var crystal_instance = crystal_scene.instantiate()
	get_parent().add_child(crystal_instance)
	crystal_instance.global_position = global_position
