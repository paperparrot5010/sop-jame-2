extends Sprite2D
var bullet_path = preload("res://Player/bullet2.tscn")

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())

	if Input.is_action_just_pressed("shoot"):
		fire()

# Called when the node enters the scene tree for the first time.
func fire():
	var bullet = bullet_path.instantiate()
	bullet.dir=rotation
	bullet.pos=$Node2D.global_position
	bullet.rota=global_rotation
	get_parent().add_child(bullet)
	
