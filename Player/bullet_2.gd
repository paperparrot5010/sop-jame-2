extends CharacterBody2D
@export var crystal_scene: PackedScene
var start_position:Vector2
var direction:float
var speed = 2000

func _ready() -> void:
	global_position = start_position
	global_rotation = direction
	velocity = Vector2(speed, 0).rotated(direction)

func _physics_process(_delta: float) -> void:
	# REMOVE THIS LINE: look_at(get_global_mouse_position())
	# This line was making the bullet follow the mouse after being fired
	move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("EnemyGroup"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
	elif body.is_in_group("MachineGroup"):
		queue_free()
