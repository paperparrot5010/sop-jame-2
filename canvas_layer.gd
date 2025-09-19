extends CanvasLayer

@export var time_left = 7
@onready var label: Label = $Label
var shake_tween: Tween
var is_shaking: bool = false
var original_label_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = str(time_left)
	original_label_position = label.position # Store the original position
	
	shake_tween = create_tween()
	shake_tween.set_loops() # Make the tween loop
	# Define the shake animation: move to random position relative to original, then back to original
	shake_tween.tween_property(label, "position", original_label_position + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_property(label, "position", original_label_position, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.stop() # Initially stop the tween, so it doesn't play until needed

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

func _on_timer_fortime_left_timeout() -> void:
	time_left = max(0, time_left - 1) # Clamp time_left at 0
	label.text = str(time_left)
