extends CharacterBody2D

var speed = 500
var direction = Vector2.RIGHT  # Default direction

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()
