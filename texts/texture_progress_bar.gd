extends TextureProgressBar

var player_node: Node

func _ready():
	# Find the actual player instance in the scene using the correct group name
	player_node = get_tree().get_first_node_in_group("PlayerGroup")
	
	if player_node:
		# Connect to the health_changed signal
		player_node.health_changed.connect(update_health)
		
		# Set up the progress bar with initial values
		update_health_bar()
		print("Health bar connected to player successfully!")
	else:
		print("Player node not found in PlayerGroup!")

func update_health(new_health: int):
	# Update both current value and max value in case max health changed
	update_health_bar()
	print("Health bar updated to: ", new_health)

func update_health_bar():
	if player_node:
		# Get current and max health from player
		var current_health = player_node.get_current_health() if player_node.has_method("get_current_health") else player_node.health
		var player_max_health = player_node.get_max_health() if player_node.has_method("get_max_health") else player_node.health
		
		# Update progress bar values
		max_value = player_max_health
		value = current_health
		
		print("Health bar: ", current_health, "/", player_max_health)
