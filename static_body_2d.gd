extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var keyboard_letters_and_symbols: Sprite2D = $KeyboardLettersAndSymbols
@export var control_node: Node
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var stability = 100
@onready var timer: Timer = $Timer
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
@onready var stability_label: Label = $Label
#spawning
@export var Bomb_scene: PackedScene
@export var Bomb_spawn_points: Array[Node2D]
# A variable to track if the player is in the zone
var player_in_zone = false
# Bomb spawning variables
var bomb_spawn_timer: Timer
var should_spawn_bombs = false
# Track recently used spawn points to prevent overlapping bombs
var recently_used_spawn_points = {}
var spawn_cooldown = 5.0  # Seconds before a spawn point can be reused
var stabilizing_points = 0

func _ready() -> void:
	GlobalSignals.crystal_collected.connect(_on_crystal_collected)

	timer.start()
	control_node = get_tree().get_first_node_in_group("ControlGroup")
	keyboard_letters_and_symbols.hide()
	animated_sprite_2d.play("Opening")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("Working")
	
	# Initialize TextureProgressBar and Label
	if texture_progress_bar:
		texture_progress_bar.min_value = 0
		texture_progress_bar.max_value = 100  # Fixed to always be 100
		texture_progress_bar.value = stability
	
	if stability_label:
		stability_label.text = "Stability: 100%"
		print("Label initialized")
	else:
		print("ERROR: stability_label is null!")
	
	# Setup bomb spawn timer
	bomb_spawn_timer = Timer.new()
	bomb_spawn_timer.wait_time = 3.0
	bomb_spawn_timer.one_shot = false
	bomb_spawn_timer.timeout.connect(_on_bomb_spawn_timer_timeout)
	add_child(bomb_spawn_timer)

func _on_timer_timeout() -> void:
	stability -= 1
	stability = clamp(stability, 0, 100)  # ← ADD THIS LINE to clamp between 0-100
	
	print("Timer timeout! Stability now: ", stability)
	
	if texture_progress_bar:
		texture_progress_bar.value = stability
		texture_progress_bar.queue_redraw()
	
	# Update the label text with percentage
	if stability_label:
		stability_label.text = "Stability: " + str(stability) + "%"
		print("Label updated to: ", stability_label.text)
	
	print("Progress bar updated to: ", stability)
	
	# Check if we should start spawning bombs
	if stability <= 50 and not should_spawn_bombs:
		should_spawn_bombs = true
		bomb_spawn_timer.start()
	elif stability > 50 and should_spawn_bombs:
		should_spawn_bombs = false
		bomb_spawn_timer.stop()
	
	# Clean up expired spawn point cooldowns
	var current_time = Time.get_unix_time_from_system()
	for spawn_point in recently_used_spawn_points.duplicate():
		if current_time - recently_used_spawn_points[spawn_point] > spawn_cooldown:
			recently_used_spawn_points.erase(spawn_point)

func _on_bomb_spawn_timer_timeout() -> void:
	if should_spawn_bombs:
		# Spawn 3 bombs instead of 1
		for i in range(3):
			spawn_bomb()

func spawn_bomb() -> void:
	if Bomb_scene == null or Bomb_spawn_points.is_empty():
		return
	
	# Get available spawn points (not recently used)
	var current_time = Time.get_unix_time_from_system()
	var available_spawn_points = []
	
	for spawn_point in Bomb_spawn_points:
		if not recently_used_spawn_points.has(spawn_point) or \
		   (recently_used_spawn_points.has(spawn_point) and \
		   current_time - recently_used_spawn_points[spawn_point] > spawn_cooldown):
			available_spawn_points.append(spawn_point)
	
	# If no spawn points are available, use any spawn point
	if available_spawn_points.is_empty():
		available_spawn_points = Bomb_spawn_points.duplicate()
	
	# Select a random available spawn point
	var random_spawn_point = available_spawn_points[randi() % available_spawn_points.size()]
	
	# Mark this spawn point as recently used
	recently_used_spawn_points[random_spawn_point] = current_time
	
	# Spawn the bomb
	var enemy_instance = Bomb_scene.instantiate()
	get_parent().add_child(enemy_instance)
	enemy_instance.global_position = random_spawn_point.global_position




func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
		animation_player.play("normal")


func _on_crystal_collected():
	stabilizing_points += 1
	pass
