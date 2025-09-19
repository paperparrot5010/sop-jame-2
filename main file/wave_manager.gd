extends Node

@export var spawn_points: Array[Node2D] # <--- IMPORTANT CHANGE HERE
@export var enemy_scene:PackedScene
# ... rest of your script ...

var current_wave: int = 0
var enemies_spawned_in_wave: int = 0
var enemies_remaining_in_wave: int = 0
var wave_active: bool = false
var break_active: bool = false

var wave_data = [
	# Wave 1
	{
		"wave_number": 1,
		"enemy_count": 5,
		"spawn_interval": 1.0,
		"break_duration": 5.0 # Time before next wave starts
	},
	# Wave 2
	{
		"wave_number": 2,
		"enemy_count": 10,
		"spawn_interval": 0.8,
		"break_duration": 7.0
	},
	# Wave 3
	{
		"wave_number": 3,
		"enemy_count": 15,
		"spawn_interval": 0.6,
		"break_duration": 10.0
	}
	# Add more waves here
]

@onready var spawn_timer: Timer = Timer.new()
@onready var break_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(spawn_timer)
	add_child(break_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	break_timer.timeout.connect(_on_break_timer_timeout)
	
	start_next_wave()

func start_next_wave() -> void:
	current_wave += 1
	if current_wave > wave_data.size():
		print("All waves completed!")
		return

	var wave_info = wave_data[current_wave - 1]
	enemies_spawned_in_wave = 0
	enemies_remaining_in_wave = wave_info["enemy_count"]
	wave_active = true
	break_active = false

	print("Starting Wave ", current_wave, ": Spawning ", enemies_remaining_in_wave, " enemies.")

	spawn_timer.wait_time = wave_info["spawn_interval"]
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if enemies_spawned_in_wave < wave_data[current_wave - 1]["enemy_count"]:
		spawn_enemy()
		enemies_spawned_in_wave += 1
	else:
		spawn_timer.stop()
		print("Finished spawning for Wave ", current_wave)
		# Now wait for all enemies to be defeated or a break to start
		# For now, we\'ll just start the break after spawning is done
		start_break()

func spawn_enemy() -> void:
	if enemy_scene == null:
		print("Error: Enemy scene not assigned!")
		return
	if spawn_points.is_empty():
		print("Error: No spawn points assigned!")
		return

	var enemy_instance = enemy_scene.instantiate()
	var random_spawn_point = spawn_points[randi() % spawn_points.size()]
	get_parent().add_child(enemy_instance)
	enemy_instance.global_position = random_spawn_point.global_position
	
	# Connect enemy\'s death signal to decrement enemies_remaining_in_wave
	# Assuming your enemy has a \'died\' signal
	if enemy_instance.has_signal("died"):
		enemy_instance.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_remaining_in_wave -= 1
	if enemies_remaining_in_wave <= 0 and not break_active:
		print("All enemies defeated in Wave ", current_wave)
		start_break()

func start_break() -> void:
	wave_active = false
	break_active = true
	var wave_info = wave_data[current_wave - 1]
	print("Starting break for ", wave_info["break_duration"], " seconds.")
	break_timer.wait_time = wave_info["break_duration"]
	break_timer.start()

func _on_break_timer_timeout() -> void:
	break_timer.stop()
	print("Break over. Preparing for next wave.")
	start_next_wave()
