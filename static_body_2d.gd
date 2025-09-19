extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# A variable to track if the player is in the zone
var player_in_zone = false

func _ready() -> void:
	animated_sprite_2d.play("Opening")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("Working")

func _process(delta: float) -> void:
	# Check for input every frame, ONLY if the player is in the zone
	if player_in_zone and Input.is_action_just_pressed("Interact"):
		print(1)

# This function runs when the player enters the zone
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		player_in_zone = true # Set the flag to true

# This function runs when the player leaves the zone
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		player_in_zone = false # Set the flag to false
