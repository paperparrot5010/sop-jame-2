extends CanvasLayer

@export var time_left = 0
@onready var label: Label = $Label
var shake_tween: Tween
var is_shaking: bool = false
var original_label_position: Vector2
@onready var label_2: Label = $Label2

# Reference to the wave manager
var wave_manager: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set up health display first
	var player_node = get_tree().get_first_node_in_group("PlayerGroup")
	if player_node:
		player_node.health_changed.connect(_on_player_health_changed)
		label_2.text = "Health: " + str(player_node.health)
	else:
		label_2.text = "Health: N/A"
	
	original_label_position = label.position # Store the original position
	
	shake_tween = create_tween()
	shake_tween.set_loops() # Make the tween loop
	# Define the shake animation: move to random position relative to original, then back to original
	shake_tween.tween_property(label, "position", original_label_position + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_property(label, "position", original_label_position, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.stop() # Initially stop the tween, so it doesn't play until needed
	
	# Try to find the wave manager - it might not be ready yet
	find_wave_manager()

# Try to find the wave manager
func find_wave_manager():
	wave_manager = get_tree().get_first_node_in_group("WaveManagerGroup")
	
	if wave_manager:
		print("WaveTimerUI: Wave manager found")
		# Connect to the wave manager's signals
		if wave_manager.has_signal("wave_started"):
			wave_manager.wave_started.connect(_on_wave_started)
		if wave_manager.has_signal("wave_time_updated"):
			wave_manager.wave_time_updated.connect(_on_wave_time_updated)
	else:
		print("WaveTimerUI: Wave manager not found, trying again...")
		# Try again after a short delay
		await get_tree().create_timer(0.5).timeout
		find_wave_manager()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if time_left <= 5:
		# Change text color to red
		label.add_theme_color_override("font_color", Color.RED)
		
		# Start shake animation if not already playing
		if not is_shaking:
			shake_tween.play()
			is_shaking = true
	else:
		# Reset color if time goes above 5 (e.g., if time_left is reset)
		label.remove_theme_color_override("font_color")
		# Stop shake animation if playing
		if is_shaking:
			shake_tween.stop() # Stop the tween
			label.position = original_label_position # Reset position to original
			is_shaking = false

# Called when a new wave starts
func _on_wave_started(wave_duration: float) -> void:
	time_left = int(wave_duration)
	label.text = str(time_left)

# Called when the wave time updates
func _on_wave_time_updated(remaining_time: float) -> void:
	time_left = int(remaining_time)
	label.text = str(time_left)

func _on_player_health_changed(new_health: int) -> void:
	label_2.text = "Health: " + str(new_health)
