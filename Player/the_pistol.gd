extends Area2D

var bullet_path = preload("res://Player/bullet2.tscn")

@onready var pivot = get_parent()  # Get reference to the pivot node

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("shoot"):
		fire()

func fire():
	var bullet = bullet_path.instantiate()
	
	# Use the pivot's rotation which is already looking at the mouse
	bullet.direction = pivot.global_rotation
	bullet.start_position = $Node2D.global_position
	get_parent().add_child(bullet)
