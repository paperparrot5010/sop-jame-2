extends CanvasLayer
@onready var crystal_label: Label = $Crystal_label

@export var time_left = 0
@onready var label: Label = $Label
var shake_tween: Tween
var is_shaking: bool = false
var original_label_position: Vector2
@onready var label_2: Label = $Label2
var crystals = 0
# Reference to the wave manager
var wave_manager: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to the global signal
	GlobalSignals.crystal_collected.connect(_on_crystal_collected)
	
	# Set up health display first
	var player_node = get_tree().get_first_node_in_group("PlayerGroup")
	if player_node:
		player_node.health_changed.connect(_on_player_health_changed)
		# Show current/max health format
		var current_health = player_node.get_current_health() if player_node.has_method("get_current_health") else player_node.health
		var max_health = player_node.get_max_health() if player_node.has_method("get_max_health") else player_node.health
		label_2.text = "Health: " + str(current_health) + "/" + str(max_health)
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
		# Connect to wave_ended signal to ensure 0 is displayed
		if wave_manager.has_signal("wave_ended"):
			wave_manager.wave_ended.connect(_on_wave_ended)
	else:
		print("WaveTimerUI: Wave manager not found, trying again...")
		# Try again after a short delay
		await get_tree().create_timer(0.5).timeout
		find_wave_manager()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if time_left <= 5 and time_left > 0:
		# Change text color to red
		label.add_theme_color_override("font_color", Color.RED)
		
		# Start shake animation if not already playing
		if not is_shaking:
			shake_tween.play()
			is_shaking = true
	else:
		# Reset color if time goes above 5 (e.g., if time_left is reset) or is 0
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
	time_left = int(ceil(remaining_time)) # Convert to int to remove decimal
	label.text = str(time_left)

# Called when the wave ends (either by enemies defeated or timer timeout)
func _on_wave_ended() -> void:
	time_left = 0
	label.text = str(time_left)

func _on_player_health_changed(new_health: int) -> void:
	# Get the player's max health to show current/max format
	var player_node = get_tree().get_first_node_in_group("PlayerGroup")
	if player_node and player_node.has_method("get_max_health"):
		var max_health = player_node.get_max_health()
		label_2.text = "Health: " + str(new_health) + "/" + str(max_health)
	else:
		label_2.text = "Health: " + str(new_health)

func add_crystal():
	crystals += 1
	crystal_label.text = str(crystals) + "X"
	
func _on_crystal_collected():
	print("CCCCCCCCCCCCCCCCCCCCCCCCccCCCCCCCC")
	add_crystal()

func consume_crystals(amount: int) -> bool:
	if crystals >= amount:
		crystals -= amount
		crystal_label.text = str(crystals) + "X"
		return true
	return false

func get_crystals() -> int:
	return crystals
