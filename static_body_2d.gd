extends StaticBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite_2d.play("Opening")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("Working")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerGroup"):
		if Input.is_action_just_pressed("Interact"):
			print(1)
