extends Node
@onready var rich_text_label: RichTextLabel = $"../CanvasLayer(wave no)/RichTextLabel"
@onready var animation_player: AnimationPlayer = $"../CanvasLayer(wave no)/AnimationPlayer"
@onready var timer: Timer = $"../CanvasLayer(wave no)/Timer"
# Removed var no_of_wave = 1
@export var enemy_scene: PackedScene
@export var spawn_points: Array[Node2D]
@export var ghost_scene: PackedScene
@export var worm_scene: PackedScene
# Preload the losing menu scene for efficiency
var losing_menu_scene = preload("res://texts/losing_menu.tscn")
# Preload the winning scene for efficiency
var winning_scene = preload("res://Win folder/winning.tscn")

var current_wave: int = 0
var enemies_spawned_in_wave: int = 0
var enemies_remaining_in_wave: int = 0
var wave_active: bool = false
var break_active: bool = false
var wave_ended_by_timeout: bool = false  # Track if wave ended by timeout

# Add signals for wave events
signal wave_started(wave_duration)
signal wave_time_updated(remaining_time)
signal wave_ended

# Wave data for 10 waves - all waves last exactly 30 seconds with continuous enemy spawning
var wave_data = [
	{"wave_number": 1, "enemy_count": 5, "spawn_interval": 1.0, "break_duration": 5.0, "wave_duration": 30.0},
	{"wave_number": 2, "enemy_count": 10, "spawn_interval": 0.8, "break_duration": 5.0, "wave_duration": 30.0},
	{"wave_number": 3, "enemy_count": 15, "spawn_interval": 0.6, "break_duration": 5.0, "wave_duration": 30.0},
	{"wave_number": 4, "enemy_count": 20, "spawn_interval": 0.5, "break_duration": 5.0, "wave_duration": 30.0},
	{"wave_number": 5, "enemy_count": 25, "spawn_interval": 0.4, "break_duration": 5.0, "wave_duration": 30.0},
	{"wave_number": 6, "enemy_count": 30, "spawn_interval": 0.4, "break_duration": 5.0, "wave_duration": 30.0},
	{"wave_number": 7, "enemy_count": 35, "spawn_interval": 0.35, "break_duration": 5.0, "wave_duration": 30.0},
	{"wave_number": 8, "enemy_count": 40, "spawn_interval": 0.35, "break_duration": 5.0, "wave_duration": 30.0},
	{"wave_number": 9, "enemy_count": 45, "spawn_interval": 0.3, "break_duration": 5.0, "wave_duration": 30.0},
	{"wave_number": 10, "enemy_count": 50, "spawn_interval": 0.3, "break_duration": 5.0, "wave_duration": 30.0}
]

@onready var spawn_timer: Timer = Timer.new()
@onready var break_timer: Timer = Timer.new()
@onready var wave_timer: Timer = Timer.new()  # New timer for wave duration

var player_node: Node2D = null
var ghost_spawn_count: int = 0  # Track how many ghosts have been spawned in this wave
var max_ghosts_per_wave: int = 0  # Maximum ghosts allowed per wave

# Worm spawning variables (starting from wave 6)
var worm_spawn_count: int = 0  # Track how many worms have been spawned in this wave
var max_worms_per_wave: int = 0  # Maximum worms allowed per wave (max 3)
var worm_spawn_positions: Array[Vector2] = []  # Track worm spawn positions to prevent overlap

func _ready() -> void:
	# Add to group so UI can find it
	add_to_group("WaveManagerGroup")
	
	add_child(spawn_timer)
	add_child(break_timer)
	add_child(wave_timer)  # Add the wave timer
	
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	break_timer.timeout.connect(_on_break_timer_timeout)
	wave_timer.timeout.connect(_on_wave_timer_timeout)  # Connect wave timer

	await get_tree().create_timer(0.01).timeout
	player_node = get_tree().get_first_node_in_group("PlayerGroup")
	if is_instance_valid(player_node):
		player_node.player_died.connect(_on_player_died)
	else:
		print("WaveManager Error: Player not found in \"PlayerGroup\".")

	start_next_wave()

func start_next_wave() -> void:
	# Reset the timeout flag at the start of each wave
	wave_ended_by_timeout = false
	ghost_spawn_count = 0  # Reset ghost counter each wave
	worm_spawn_count = 0  # Reset worm counter each wave
	worm_spawn_positions.clear()  # Clear worm spawn positions
	
	current_wave += 1 # Increment current_wave at the beginning of the function

	if current_wave > wave_data.size():
		print("All 10 waves completed! Player wins!")
		load_winning_scene()
		return
		
	# Calculate maximum ghosts for this wave (30% of total enemies, starting from wave 3)
	if current_wave >= 3:
		max_ghosts_per_wave = int(wave_data[current_wave - 1]["enemy_count"] * 0.3)
	else:
		max_ghosts_per_wave = 0
	
	# Calculate maximum worms for this wave (max 3, starting from wave 6)
	if current_wave >= 6:
		max_worms_per_wave = 3  # Always max 3 worms per wave
	else:
		max_worms_per_wave = 0
		
	print("Wave ", current_wave, ": Max ghosts allowed: ", max_ghosts_per_wave, ", Max worms allowed: ", max_worms_per_wave)
		
	# Display the correct wave number
	rich_text_label.text = "Wave: " + str(current_wave)
	timer.start()
	animation_player.play("Fade_to_normal")
	await timer.timeout
	animation_player.play("Fade_to_vanish")

	var wave_info = wave_data[current_wave - 1]
	enemies_spawned_in_wave = 0
	enemies_remaining_in_wave = wave_info["enemy_count"]
	wave_active = true
	break_active = false

	print("Starting Wave ", current_wave)
	
	# Increase player max health for new wave (except wave 1 which starts at 10)
	if current_wave > 1 and is_instance_valid(player_node) and player_node.has_method("increase_max_health_for_new_wave"):
		player_node.increase_max_health_for_new_wave()
	
	spawn_timer.wait_time = wave_info["spawn_interval"]
	spawn_timer.start()
	
	# Start the wave timer with original duration
	wave_timer.wait_time = wave_info["wave_duration"]
	wave_timer.start()
	print("Wave will end in ", wave_timer.wait_time, " seconds.")
	
	# Emit signal for UI with the original duration
	wave_started.emit(wave_info["wave_duration"])
	

func _on_spawn_timer_timeout() -> void:
	# Keep spawning enemies continuously while the wave is active
	if wave_active:
		spawn_enemy()
		enemies_spawned_in_wave += 1

func spawn_enemy() -> void:
	if enemy_scene == null or spawn_points.is_empty():
		return

	# Determine which enemy to spawn
	var enemy_to_spawn = enemy_scene
	var spawn_position: Vector2
	var is_worm = false
	var is_ghost = false
	
	# Calculate how many enemies we can still spawn in this wave
	var remaining_enemies = wave_data[current_wave - 1]["enemy_count"] - enemies_spawned_in_wave
	
	# Priority: Worms first (from wave 6), then ghosts (from wave 3), then regular enemies
	if current_wave >= 6 and worm_scene != null and worm_spawn_count < max_worms_per_wave:
		# 30% chance to spawn worm instead of other enemies
		if randf() < 0.3:
			enemy_to_spawn = worm_scene
			is_worm = true
			worm_spawn_count += 1
			print("Spawning worm (", worm_spawn_count, "/", max_worms_per_wave, ")")
	
	# If not spawning a worm, check for ghost spawning
	if not is_worm and current_wave >= 3 and ghost_scene != null and ghost_spawn_count < max_ghosts_per_wave:
		# Calculate how many ghosts we can still spawn
		var remaining_ghosts = max_ghosts_per_wave - ghost_spawn_count
		
		# Ensure we don't exceed the ghost limit and have enough remaining enemies
		if remaining_ghosts > 0 and remaining_enemies > 0:
			# Calculate probability based on remaining ghosts and enemies
			var ghost_probability = float(remaining_ghosts) / float(remaining_enemies)
			ghost_probability = min(ghost_probability, 0.8)  # Cap at 80% to avoid always spawning ghosts
			
			if randf() < ghost_probability:
				enemy_to_spawn = ghost_scene
				is_ghost = true
				ghost_spawn_count += 1
				print("Spawning ghost (", ghost_spawn_count, "/", max_ghosts_per_wave, ")")
	
	# Handle worm spawn position (prevent overlapping)
	if is_worm:
		spawn_position = get_non_overlapping_spawn_position()
	else:
		# Regular spawn for non-worm enemies
		var random_spawn_point = spawn_points[randi() % spawn_points.size()]
		spawn_position = random_spawn_point.global_position

	var enemy_instance = enemy_to_spawn.instantiate()
	get_parent().add_child(enemy_instance)
	enemy_instance.global_position = spawn_position
	
	# Track worm positions
	if is_worm:
		worm_spawn_positions.append(spawn_position)

	if enemy_instance.has_signal("died"):
		enemy_instance.died.connect(_on_enemy_died)
	
	# Store a reference to the wave manager in the enemy
	enemy_instance.set_meta("wave_manager", self)

func _on_enemy_died() -> void:
	enemies_remaining_in_wave -= 1
	# NOTE: Waves now only end when the timer expires, not when all enemies are killed
	# This allows continuous enemy spawning for the full 30 seconds

func _on_wave_timer_timeout() -> void:
	if wave_active:
		print("Wave ", current_wave, " completed after 30 seconds!")
		# Set the flag to indicate wave ended by timeout
		wave_ended_by_timeout = true
		
		# Stop spawning new enemies
		spawn_timer.stop()
		
		# Kill all remaining enemies when wave timer expires
		kill_all_enemies()
		
		wave_timer.stop()
		start_break()
		wave_ended.emit() # Emit wave ended signal here as well

# New function to kill all enemies instantly
func kill_all_enemies():
	var enemies = get_tree().get_nodes_in_group("EnemyGroup")
	for enemy in enemies:
		if enemy.has_method("die_without_crystal"):
			enemy.die_without_crystal()
		else:
			enemy.queue_free()

func start_break() -> void:
	wave_active = false
	break_active = true
	var wave_info = wave_data[current_wave - 1]
	break_timer.wait_time = wave_info["break_duration"]
	break_timer.start()
	print("Starting break for ", break_timer.wait_time, " seconds.")
	
	# Restore player health after completing the wave
	if is_instance_valid(player_node) and player_node.has_method("restore_health_after_wave"):
		player_node.restore_health_after_wave()
	
	# Emit wave ended signal
	wave_ended.emit()

func _on_break_timer_timeout() -> void:
	break_timer.stop()
	print("Break over. Preparing for next wave.")
	start_next_wave()

func _on_player_died() -> void:
	var menu_instance = losing_menu_scene.instantiate()
	add_child(menu_instance)
	# Stop all spawning
	spawn_timer.stop()
	break_timer.stop()
	wave_timer.stop()  # Also stop the wave timer
	wave_active = false
	break_active = false

	# Remove all existing enemies
	get_tree().call_group("EnemyGroup", "queue_free")

	# Wait a very short moment to ensure everything is processed,
	# then add the losing menu.
	await get_tree().create_timer(0.5).timeout

# Helper function to check if wave ended by timeout
func did_wave_end_by_timeout() -> bool:
	return wave_ended_by_timeout

# Function to get a spawn position that doesn't overlap with existing worms
func get_non_overlapping_spawn_position() -> Vector2:
	var min_distance = 100.0  # Minimum distance between worms
	var max_attempts = 20  # Maximum attempts to find a valid position
	var attempts = 0
	
	while attempts < max_attempts:
		# Pick a random spawn point
		var random_spawn_point = spawn_points[randi() % spawn_points.size()]
		var potential_position = random_spawn_point.global_position
		
		# Check if this position is far enough from existing worms
		var valid_position = true
		for worm_pos in worm_spawn_positions:
			if potential_position.distance_to(worm_pos) < min_distance:
				valid_position = false
				break
		
		if valid_position:
			return potential_position
		
		attempts += 1
	
	# If no valid position found after max attempts, just use a random spawn point
	var fallback_spawn_point = spawn_points[randi() % spawn_points.size()]
	print("Warning: Could not find non-overlapping spawn position for worm, using fallback")
	return fallback_spawn_point.global_position

# Function to load the winning scene
func load_winning_scene() -> void:
	# Stop all timers
	spawn_timer.stop()
	break_timer.stop()
	wave_timer.stop()
	wave_active = false
	break_active = false
	
	# Remove all existing enemies
	get_tree().call_group("EnemyGroup", "queue_free")
	
	# Change to winning scene immediately
	get_tree().change_scene_to_packed(winning_scene)

# Update the wave timer UI in real-time
func _process(delta: float) -> void:
	if wave_active:
		# Emit signal with remaining time, even if it's 0
		if wave_timer.time_left >= 0:
			wave_time_updated.emit(wave_timer.time_left)
		
		# Check if time is up and kill enemies instantly
		if wave_timer.time_left <= 0.0:
			print("Wave ", current_wave, " completed after 30 seconds! Stopping enemy spawning.")
			wave_ended_by_timeout = true
			# Stop spawning new enemies
			spawn_timer.stop()
			kill_all_enemies()
			wave_timer.stop()
			start_break()
			wave_ended.emit() # Ensure wave_ended is emitted here as well
