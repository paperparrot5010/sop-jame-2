extends Button

var target_position: Vector2
var is_moving: bool = false
@export var move_speed = 5.0


func _process(delta):
	if is_moving : #if is_moving == true
		position = position.lerp(target_position, move_speed * delta)


func change_place():
	var screen_size = get_viewport().get_visible_rect().size
	#print(screen_size.x)
	var button_size = size
	
	var min_x = 0
	var max_x = screen_size.x - button_size.x
	var min_y = 0
	var max_y = screen_size.y - button_size.y
	
	var random_x = randf_range(min_x, max_x)
	var random_y = randf_range(min_y, max_y)
	
	target_position = Vector2(random_x,random_y)
	is_moving = true


func _on_mouse_entered() -> void:
	change_place()
