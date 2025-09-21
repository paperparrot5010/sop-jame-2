extends Sprite2D

# Animation variables
var original_scale = Vector2(0.1, 0.1) # User-specified original scale
var animation_speed = 1.5 # Speed of the squish/stretch animation
var animation_intensity = 0.15 # Intensity of the squish/stretch effect
var current_animation_time = 0.0
var animation_duration = 1.0 # Duration of one full squish/stretch cycle

func _ready():
	scale = original_scale

func _process(delta: float) -> void:
	# Continuous squish and stretch animation
	current_animation_time += delta * animation_speed
	var t = fmod(current_animation_time, animation_duration) / animation_duration

	# Simple sine wave for squish and stretch
	var scale_x_factor = 1.0 + sin(t * PI * 2) * animation_intensity
	var scale_y_factor = 1.0 - sin(t * PI * 2) * animation_intensity

	scale.x = original_scale.x * scale_x_factor
	scale.y = original_scale.y * scale_y_factor
