extends StaticBody2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var keyboard_letters_and_symbols: Sprite2D = $KeyboardLettersAndSymbols
@export var control_node: Node
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var stability = 100
@onready var timer: Timer = $Timer

# A variable to track if the player is in the zone
var player_in_zone = false

func _ready() -> void:
	timer.start()
	control_node = get_tree().get_first_node_in_group("ControlGroup")
	keyboard_letters_and_symbols.hide()
	animated_sprite_2d.play("Opening")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("Working")

func _process(delta: float) -> void:
	# Check for input every frame, ONLY if the player is in the zone
	if player_in_zone and Input.is_action_just_pressed("Interact"):
		print(11)

# This function runs when the player enters the zone
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		keyboard_letters_and_symbols.show()
		animation_player.play("normal")
		player_in_zone = true # Set the flag to true

# This function runs when the player leaves the zone
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		animation_player.play("vanish")
		player_in_zone = false # Set the flag to false


func _on_timer_timeout() -> void:
	stability -= 1
	print(stability)
