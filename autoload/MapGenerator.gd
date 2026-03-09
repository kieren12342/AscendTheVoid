extends Node
# MapGenerator — procedurally generates a branching Act 1 map.
# Seeded by GameManager.run_seed for deterministic runs.

const FLOORS := 15         # number of floors in Act 1
const MAX_PATHS := 3       # maximum branching paths per floor
const NODE_TYPES := ["BATTLE", "BATTLE", "BATTLE", "ELITE", "EVENT", "REST", "SHOP"]
# BATTLE appears 3× to weight it more common

var map_data: Dictionary = {}

func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())

	# map_data.floors = Array of floors, each floor is Array of node Dicts
	# node Dict: { "type": String, "floor": int, "col": int, "connections": Array[int] }
	var floors := []
	for f in range(FLOORS):
		var num_nodes := rng.randi_range(1, MAX_PATHS)
		if f == 0 or f == FLOORS - 1:
			num_nodes = 1   # first and last floor always single node
		var floor_nodes := []
		for c in range(num_nodes):
			var ntype: String
			if f == FLOORS - 1:
				ntype = "BOSS"
			elif f == 0:
				ntype = "BATTLE"
			else:
				ntype = NODE_TYPES[rng.randi_range(0, NODE_TYPES.size() - 1)]
			floor_nodes.append({
				"type": ntype,
				"floor": f,
				"col": c,
				"connections": [],
				"visited": false,
				"available": false
			})
		floors.append(floor_nodes)

	# Connect floors: each node connects to 1–2 nodes on the next floor
	for f in range(FLOORS - 1):
		var cur_floor: Array = floors[f]
		var next_floor: Array = floors[f + 1]
		for node in cur_floor:
			var num_connections := rng.randi_range(1, min(2, next_floor.size()))
			var connected := []
			while connected.size() < num_connections:
				var target := rng.randi_range(0, next_floor.size() - 1)
				if not connected.has(target):
					connected.append(target)
			node["connections"] = connected

	# Mark floor 0 as available
	for node in floors[0]:
		node["available"] = true

	map_data = {"floors": floors, "current_floor": -1, "seed": seed_value}
	EventBus.map_generated.emit(map_data)
	return map_data

func select_node(floor_idx: int, col_idx: int) -> void:
	if floor_idx < 0 or floor_idx >= map_data.floors.size():
		return
	var node: Dictionary = map_data.floors[floor_idx][col_idx]
	if not node.get("available", false):
		return
	node["visited"] = true
	map_data["current_floor"] = floor_idx
	# Mark next floor connections as available
	if floor_idx + 1 < map_data.floors.size():
		for next_col in node.get("connections", []):
			map_data.floors[floor_idx + 1][next_col]["available"] = true
	EventBus.map_node_selected.emit(node)
