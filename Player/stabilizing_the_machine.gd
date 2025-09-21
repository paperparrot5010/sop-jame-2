extends CanvasLayer

@export var crystal_cost_per_use: int = 1
@export var stability_increase_per_use: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	# Get reference to the canvas layer (UI) to check crystal count
	var canvas_layer = get_tree().get_first_node_in_group("CanvasLayerGroup")
	if not canvas_layer:
		# Try to find canvas layer by name if group doesn't exist
		canvas_layer = get_tree().get_nodes_in_group("CanvasLayer")
		if canvas_layer.size() > 0:
			canvas_layer = canvas_layer[0]
		else:
			# Try to find it by searching for the crystal label
			var all_canvas_layers = get_tree().get_nodes_in_group("CanvasLayer")
			for layer in all_canvas_layers:
				if layer.has_method("get_crystals"):
					canvas_layer = layer
					break
			
			# If still not found, search by traversing the scene tree
			if not canvas_layer:
				var root = get_tree().current_scene
				canvas_layer = find_canvas_layer_with_crystals(root)
	
	if not canvas_layer:
		print("ERROR: Could not find canvas layer with crystal functionality")
		return
	
	# Check if player has enough crystals
	if not canvas_layer.has_method("get_crystals") or not canvas_layer.has_method("consume_crystals"):
		print("ERROR: Canvas layer doesn't have crystal methods")
		return
	
	var current_crystals = canvas_layer.get_crystals()
	if current_crystals < crystal_cost_per_use:
		print("Not enough crystals! Need at least ", crystal_cost_per_use, " but have ", current_crystals)
		return
	
	# Use ALL crystals at once instead of just one
	var total_stability_increase = current_crystals * stability_increase_per_use
	var crystals_consumed = canvas_layer.consume_crystals(current_crystals)
	if crystals_consumed:
		# Emit signal to increase machine stability by all crystals
		GlobalSignals.machine_stabilized.emit(total_stability_increase)
		print("Used ALL ", current_crystals, " crystal(s) to increase machine stability by ", total_stability_increase)
	else:
		print("ERROR: Failed to consume crystals")

# Helper function to find canvas layer with crystal functionality
func find_canvas_layer_with_crystals(node: Node) -> Node:
	if node.has_method("get_crystals") and node.has_method("consume_crystals"):
		return node
	
	for child in node.get_children():
		var result = find_canvas_layer_with_crystals(child)
		if result:
			return result
	
	return null
