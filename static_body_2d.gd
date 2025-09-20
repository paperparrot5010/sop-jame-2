extends StaticBody2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var keyboard_letters_and_symbols: Sprite2D = $KeyboardLettersAndSymbols
@export var control_node: Node
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var stability = 100
@onready var timer: Timer = $Timer
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
@onready var stability_label: Label = $Label  # Add this line - adjust node name if different

# A variable to track if the player is in the zone
var player_in_zone = false

func _ready() -> void:
	print("Machine _ready() called")
	timer.start()
	control_node = get_tree().get_first_node_in_group("ControlGroup")
	keyboard_letters_and_symbols.hide()
	animated_sprite_2d.play("Opening")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("Working")
	
	# Initialize TextureProgressBar and Label
	if texture_progress_bar:
		texture_progress_bar.min_value = 0
		texture_progress_bar.max_value = stability
		texture_progress_bar.value = stability
	
	if stability_label:
		stability_label.text = "Stability: 100%"  # Set initial text
		print("Label initialized")
	else:
		print("ERROR: stability_label is null!")

# ... your existing functions ...

func _on_timer_timeout() -> void:
	stability -= 1
	print("Timer timeout! Stability now: ", stability)
	
	if texture_progress_bar:
		texture_progress_bar.value = stability
		texture_progress_bar.queue_redraw()
	
	# Update the label text with percentage
	if stability_label:
		var percentage = int((float(stability) / 100.0) * 100)  # Calculate percentage
		stability_label.text = "Stability: " + str(percentage) + "%"
		print("Label updated to: ", stability_label.text)
	
	print("Progress bar updated to: ", stability)
