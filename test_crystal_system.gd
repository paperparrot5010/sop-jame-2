extends Node

# This is a test script to verify the crystal-to-stability system works correctly
# You can run this in the Godot debugger to test the functionality

func test_crystal_system():
	print("=== Testing Crystal to Stability System ===")
	
	# Test GlobalSignals exist
	if GlobalSignals.has_signal("crystal_collected"):
		print("✓ GlobalSignals.crystal_collected exists")
	else:
		print("✗ GlobalSignals.crystal_collected missing")
	
	if GlobalSignals.has_signal("machine_stabilized"):
		print("✓ GlobalSignals.machine_stabilized exists")
	else:
		print("✗ GlobalSignals.machine_stabilized missing")
	
	# Test Canvas Layer functionality
	var canvas_layer = get_tree().get_first_node_in_group("CanvasLayerGroup")
	if not canvas_layer:
		# Try alternative search methods
		var all_nodes = get_tree().get_nodes_in_group("CanvasLayer")
		if all_nodes.size() > 0:
			canvas_layer = all_nodes[0]
	
	if canvas_layer and canvas_layer.has_method("get_crystals"):
		print("✓ Canvas Layer with crystal functionality found")
		print("  Current crystals: ", canvas_layer.get_crystals())
		
		# Test crystal consumption
		if canvas_layer.has_method("consume_crystals"):
			var initial_crystals = canvas_layer.get_crystals()
			if initial_crystals > 0:
				var consumed = canvas_layer.consume_crystals(1)
				if consumed:
					print("✓ Crystal consumption works")
					print("  Crystals after consumption: ", canvas_layer.get_crystals())
				else:
					print("✗ Crystal consumption failed")
			else:
				print("! No crystals to test consumption")
	else:
		print("✗ Canvas Layer with crystal functionality not found")
	
	# Test Machine stability functionality
	var machine = get_tree().get_first_node_in_group("MachineGroup")
	if machine and machine.has_method("_on_machine_stabilized"):
		print("✓ Machine with stabilization functionality found")
		print("  Current stability: ", machine.stability if machine.has_property("stability") else "N/A")
	else:
		print("✗ Machine with stabilization functionality not found")
	
	print("=== Test Complete ===")

func _ready():
	# Wait a moment for scene to initialize
	await get_tree().process_frame
	test_crystal_system()