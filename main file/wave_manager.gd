extends Node
@onready var rich_text_label: RichTextLabel = $"../CanvasLayer(wave no)/RichTextLabel"
@onready var animation_player: AnimationPlayer = $"../CanvasLayer(wave no)/AnimationPlayer"
@onready var timer: Timer = $"../CanvasLayer(wave no)/Timer"
var no_of_wave = 1
@export var enemy_scene: PackedScene
@export var spawn_points: Array[Node2D]

# Preload the losing menu scene for efficiency
var losing_menu_scene = preload("res://texts/losing_menu.tscn")

var current_wave: int = 0
var enemies_spawned_in_wave: int = 0
var enemies_remaining_in_wave: int = 0
var wave_active: bool = false
var break_active: bool = false

var wave_data = [
	{"wave_number": 1, "enemy_count": 5, "spawn_interval": 1.0, "break_duration": 5.0},
	{"wave_number": 2, "enemy_count": 10, "spawn_interval": 0.8, "break_duration": 7.0},
	{"wave_number": 3, "enemy_count": 15, "spawn_interval": 0.6, "break_duration": 10.0}
]

@onready var spawn_timer: Timer = Timer.new()
@onready var break_timer: Timer = Timer.new()

var player_node: Node2D = null

func _ready() -> void:
	add_child(spawn_timer)
	add_child(break_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	break_timer.timeout.connect(_on_break_timer_timeout)

	await get_tree().create_timer(0.01).timeout
	player_node = get_tree().get_first_node_in_group("PlayerGroup")
	if is_instance_valid(player_node):
		player_node.player_died.connect(_on_player_died)
	else:
		print("WaveManager Error: Player not found in \"PlayerGroup\".")

	start_next_wave()

func start_next_wave() -> void:
	rich_text_label.text = "Wave: " + str(no_of_wave)
	timer.start()
	animation_player.play("Fade_to_normal")
	await timer.timeout
	animation_player.play("Fade_to_vanish")
	current_wave += 1
	if current_wave > wave_data.size():
		print("All waves completed!")
		return
		

	var wave_info = wave_data[current_wave - 1]
	enemies_spawned_in_wave = 0
	enemies_remaining_in_wave = wave_info["enemy_count"]
	wave_active = true
	break_active = false

	print("Starting Wave ", current_wave)
	spawn_timer.wait_time = wave_info["spawn_interval"]
	spawn_timer.start()
	no_of_wave += 1

func _on_spawn_timer_timeout() -> void:
	if enemies_spawned_in_wave < wave_data[current_wave - 1]["enemy_count"]:
		spawn_enemy()
		enemies_spawned_in_wave += 1
	else:
		spawn_timer.stop()

func spawn_enemy() -> void:
	if enemy_scene == null or spawn_points.is_empty():
		return

	var enemy_instance = enemy_scene.instantiate()
	var random_spawn_point = spawn_points[randi() % spawn_points.size()]
	get_parent().add_child(enemy_instance)
	enemy_instance.global_position = random_spawn_point.global_position

	if enemy_instance.has_signal("died"):
		enemy_instance.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_remaining_in_wave -= 1
	if enemies_remaining_in_wave <= 0 and wave_active:
		print("All enemies defeated in Wave ", current_wave)
		start_break()

func start_break() -> void:
	wave_active = false
	break_active = true
	var wave_info = wave_data[current_wave - 1]
	break_timer.wait_time = wave_info["break_duration"]
	break_timer.start()
	print("Starting break for ", break_timer.wait_time, " seconds.")

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
	wave_active = false
	break_active = false

	# Remove all existing enemies
	get_tree().call_group("EnemyGroup", "queue_free")

	# --- NEW CODE TO SHOW LOSING MENU ---
	# Wait a very short moment to ensure everything is processed,
	# then add the losing menu.
	await get_tree().create_timer(0.5).timeout

	# --- END OF NEW CODE ---
