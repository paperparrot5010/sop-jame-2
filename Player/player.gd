
extends CharacterBody2D

@onready var stabilizing_the_machine: CanvasLayer = $"stabilizing the machine"
@onready var button: Button = $"stabilizing the machine/Panel/Button"

signal player_died # Signal to announce the player's death
signal health_changed(new_health: int) # Signal to announce health changes in player health

var bullet_path = preload("res://Player/bullet2.tscn")
var speed = 200
@export var health = 10
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Animation variables
var original_scale = Vector2(0.087, 0.087)
var idle_animation_speed = 1.0
var moving_animation_speed = 5.0
var current_animation_time = 0.0
var animation_duration = 1.0

# Flash effect variables
var is_flashing: bool = false
var flash_duration: float = 0.15
var flash_count: int = 3
var original_modulate: Color

# Machine interaction variables
var is_near_machine: bool = false
var machine_ui_visible: bool = false
var current_machine_area: Area2D = null

func _ready():
	print("Player script loaded")
	animated_sprite_2d.scale = original_scale
	original_modulate = animated_sprite_2d.modulate
	
	# Hide the machine UI initially
	if stabilizing_the_machine:
		stabilizing_the_machine.hide()
		print("Machine UI found and hidden")
	else:
		print("ERROR: Machine UI not found at path: stabilizing the machine")

	if button:
		button.disabled = true
		print("Button found and disabled")
	else:
		print("ERROR: Button not found at path: stabilizing the machine/Panel/Button")
	
	# Try to connect area signals programmatically if not connected in editor
	var area_node = $Area2D
	if area_node:
		if not area_node.area_entered.is_connected(_on_area_2d_area_entered):
			area_node.area_entered.connect(_on_area_2d_area_entered)
		if not area_node.area_exited.is_connected(_on_area_2d_area_exited):
			area_node.area_exited.connect(_on_area_2d_area_exited)
		print("Area2D signals connected")
	else:
		print("ERROR: Area2D node not found")

func _physics_process(delta: float) -> void:
	# Stop all processing if the player is dead
	if health <= 0:
		return

	var input_direction = Vector2.ZERO

	if Input.is_action_pressed("right"):
		input_direction.x += 1
		animated_sprite_2d.flip_h = false
	if Input.is_action_pressed("left"):
		input_direction.x -= 1
		animated_sprite_2d.flip_h = true

	if Input.is_action_pressed("down"):
		input_direction.y += 1
	if Input.is_action_pressed("up"):
		input_direction.y -= 1

	velocity = input_direction.normalized() * speed
	move_and_slide()

	# Handle machine interaction - check for both "Interact" and "ui_accept" (E key)
	if is_near_machine:
		if Input.is_action_just_pressed("Interact") :
			if machine_ui_visible:
				close_machine_ui()
			else:
				open_machine_ui()
		elif Input.is_action_just_pressed("ui_cancel"):  # ESC key to close
			close_machine_ui()

	# Animation logic...
	if velocity.length() == 0:
		current_animation_time += delta * idle_animation_speed
		var t = fmod(current_animation_time, animation_duration) / animation_duration
		var scale_x_factor = 1.0 + sin(t * PI * 2) * 0.05
		var scale_y_factor = 1.0 - sin(t * PI * 2) * 0.05
		animated_sprite_2d.scale.x = original_scale.x * scale_x_factor
		animated_sprite_2d.scale.y = original_scale.y * scale_y_factor
	else:
		current_animation_time += delta * moving_animation_speed
		var t = fmod(current_animation_time, animation_duration) / animation_duration
		var target_scale_x = original_scale.x * (1.0 + sin(t * PI * 2) * 0.05)
		var target_scale_y = original_scale.y * (1.0 - sin(t * PI * 2) * 0.05)
		var target_scale = Vector2(target_scale_x, target_scale_y)
		animated_sprite_2d.scale = animated_sprite_2d.scale.lerp(target_scale, 0.5)

func _input(event: InputEvent) -> void:
	# This function runs even when _physics_process is disabled
	if machine_ui_visible:
		if event.is_action_pressed("Interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			close_machine_ui()

func open_machine_ui():
	if stabilizing_the_machine:
		stabilizing_the_machine.show()
		machine_ui_visible = true
		# Disable player movement while UI is open
		set_physics_process(false)
		# Enable buttons
		if button:
			button.disabled = false
		print("Machine UI opened")
		
		# Set input as handled to prevent other processing
		get_viewport().set_input_as_handled()
	else:
		print("ERROR: Cannot open machine UI - stabilizing_the_machine is null")

func close_machine_ui():
	if stabilizing_the_machine:
		stabilizing_the_machine.hide()
		machine_ui_visible = false
		# Re-enable player movement
		set_physics_process(true)
		# Disable buttons
		if button:
			button.disabled = true
		print("Machine UI closed")
	else:
		print("ERROR: Cannot close machine UI - stabilizing_the_machine is null")

func fire():
	if health <= 0:
		return
	var bullet = bullet_path.instantiate()
	bullet.dir = rotation
	bullet.pos = $Node2D.global_position
	bullet.rota = global_rotation
	get_parent().add_child(bullet)

func player_takes_damage(amount):
	if health <= 0 or is_flashing: # Don't take more damage if already dead or currently flashing
		return
	
	health -= amount
	emit_signal("health_changed", health)
	print("Player health: ", health)
	
	# Start flash effect
	start_flash_effect()
	
	if health <= 0:
		player_death()

func start_flash_effect():
	if is_flashing:
		return
	
	is_flashing = true
	# Create a tween for the flash effect
	var tween = create_tween()
	tween.set_parallel(true) # Run color and scale tweens in parallel
	
	# Flash color effect (red to white)
	tween.tween_method(_flash_color_effect, 0.0, 1.0, flash_duration * flash_count * 2)
	
	# Scale effect (slight pulse)
	tween.tween_method(_flash_scale_effect, 0.0, 1.0, flash_duration * flash_count * 2)
	
	# Wait for the flash to complete
	await get_tree().create_timer(flash_duration * flash_count * 2).timeout
	
	# Reset to normal
	animated_sprite_2d.modulate = original_modulate
	animated_sprite_2d.scale = original_scale
	is_flashing = false

func _flash_color_effect(progress: float):
	var cycle = fmod(progress * flash_count * 2, 2.0)
	if cycle < 1.0:
		# Fade to red
		animated_sprite_2d.modulate = original_modulate.lerp(Color.RED, cycle)
	else:
		# Fade back to normal
		animated_sprite_2d.modulate = Color.RED.lerp(original_modulate, cycle - 1.0)

func _flash_scale_effect(progress: float):
	var cycle = fmod(progress * flash_count * 2, 2.0)
	if cycle < 1.0:
		# Scale up slightly
		var scale_factor = 1.0 + 0.2 * cycle
		animated_sprite_2d.scale = original_scale * scale_factor
	else:
		# Scale back to normal
		var scale_factor = 1.2 - 0.2 * (cycle - 1.0)
		animated_sprite_2d.scale = original_scale * scale_factor

func player_death():
	emit_signal("player_died") # Announce death to other nodes
	queue_free() # Remove the player from the scene

func _on_area_2d_area_entered(area: Area2D) -> void:
	print("Area entered: ", area.name)
	if area.is_in_group("MachineGroup"):
		
		is_near_machine = true
		current_machine_area = area
		print("Player near machine - Press E to interact")
	else:
		print("Area is not in MachineGroup. Groups: ", area.get_groups())

func _on_area_2d_area_exited(area: Area2D) -> void:
	print("Area exited: ", area.name)
	if area == current_machine_area:
		
		is_near_machine = false
		current_machine_area = null
		# Auto-close UI if player moves away
		if machine_ui_visible:
			close_machine_ui()
		print("Player left machine area")
		
		


func _on_button_pressed() -> void:
	pass # Replace with function body.
