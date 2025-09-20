extends CharacterBody2D

# Health properties
var max_health = 2
var current_health = max_health

# Navigation properties
var navigation_agent: NavigationAgent2D
var player_target: CharacterBody2D = null
var chase_player = false

# Movement properties
var speed = 150

# References
@onready var health_bar: TextureProgressBar = $TextureProgressBar
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var detection_area = $DetectionArea
@onready var navigation_timer = $"Navigaion Timer"

func _ready():
	print("Enemy ready - setting up navigation")
	
	# Initialize health
	current_health = max_health
	
	# Get navigation agent
	navigation_agent = $NavigationAgent2D
	if navigation_agent:
		print("NavigationAgent2D found")
		# Set navigation parameters like the working script
		navigation_agent.path_desired_distance = 4.0
		navigation_agent.target_desired_distance = 4.0
		# Connect navigation agent signals
		navigation_agent.velocity_computed.connect(_on_velocity_computed)
	else:
		print("ERROR: NavigationAgent2D not found!")
	
	# Setup TextureProgressBar for health
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false
	else:
		print("Health bar not found!")
	
	# Connect detection area signals manually if not connected in editor
	if detection_area:
		if not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
			detection_area.body_entered.connect(_on_detection_area_body_entered)
		if not detection_area.body_exited.is_connected(_on_detection_area_body_exited):
			detection_area.body_exited.connect(_on_detection_area_body_exited)
		print("Detection area signals connected")
	else:
		print("ERROR: DetectionArea not found!")
	
	# Find player using the same method as working script
	player_target = get_tree().get_first_node_in_group("PlayerGroup")
	if player_target == null:
		print("Enemy AI: Error: Player node not found in \"PlayerGroup\".")
	else:
		print("Enemy AI: Player node found: ", player_target.name)
	
	# Connect and start the navigation timer
	if navigation_timer:
		if not navigation_timer.timeout.is_connected(_on_navigation_timer_timeout):
			navigation_timer.timeout.connect(_on_navigation_timer_timeout)
		navigation_timer.start()
		print("Navigation timer started")
	else:
		print("ERROR: Navigation Timer not found!")
	
	print("Enemy setup complete")

func _physics_process(delta):
	if not chase_player or not player_target or not navigation_agent:
		return
	
	# Set target position like the working script
	navigation_agent.target_position = player_target.global_position
	
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	
	# Get movement direction like the working script
	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	velocity = current_agent_position.direction_to(next_path_position) * speed
	
	# Use navigation agent's avoidance if enabled
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(velocity)
	else:
		move_and_slide()
	
	# Update animation based on movement
	update_animation(velocity)
	
	# Flip sprite based on player position like the working script
	if player_target.global_position.x < global_position.x:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()
	update_animation(velocity)

func update_animation(movement_vector: Vector2):
	if animation_player:
		if movement_vector.length() > 0.1:
			if animation_player.has_animation("walk"):
				animation_player.play("walk")
			elif animation_player.has_animation("move"):
				animation_player.play("move")
		else:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")

func _on_navigation_timer_timeout():
	# Periodically update the path to player
	if chase_player and player_target and navigation_agent:
		navigation_agent.target_position = player_target.global_position
		print("Timer: Updating navigation target to: ", player_target.global_position)

func take_damage(amount: int):
	print("Enemy took damage: ", amount)
	current_health -= amount
	current_health = max(0, current_health)
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = true
		
		if current_health > 0:
			var hide_timer = get_tree().create_timer(2.0)
			hide_timer.timeout.connect(_hide_health_bar)
	
	# Play hurt animation
	if animation_player and animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	
	if current_health <= 0:
		die()

func _hide_health_bar():
	if health_bar and current_health > 0:
		health_bar.visible = false

func die():
	print("Enemy died")
	velocity = Vector2.ZERO
	chase_player = false
	
	if health_bar:
		health_bar.visible = false
	
	if animation_player and animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	else:
		await get_tree().create_timer(0.1).timeout
	
	queue_free()

func _on_detection_area_body_entered(body):
	print("Body entered detection area: ", body.name, " | Groups: ", body.get_groups())
	if body.is_in_group("PlayerGroup"):
		print("Player detected! Starting chase")
		chase_player = true
		player_target = body
		if navigation_agent:
			navigation_agent.target_position = player_target.global_position
			print("Set target to player position: ", player_target.global_position)
		
		if health_bar and current_health < max_health:
			health_bar.visible = true

func _on_detection_area_body_exited(body):
	print("Body exited detection area: ", body.name)
	if body.is_in_group("PlayerGroup"):
		print("Player lost, stopping chase")
		chase_player = false
		player_target = null
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)
		
		if health_bar and current_health > 0:
			var hide_timer = get_tree().create_timer(2.0)
			hide_timer.timeout.connect(_hide_health_bar)

# Debug function to check if navigation is working
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		print("=== DEBUG INFO ===")
		print("Chase player: ", chase_player)
		print("Player target: ", player_target)
		print("Navigation agent: ", navigation_agent)
		if player_target:
			print("Player position: ", player_target.global_position)
			print("Player groups: ", player_target.get_groups())
		print("Enemy position: ", global_position)
		if navigation_agent:
			print("Navigation finished: ", navigation_agent.is_navigation_finished())
			print("Target position: ", navigation_agent.target_position)
		print("Navigation timer: ", navigation_timer)
