# To run this script, it must be attached to any Node in a scene.
# Each test prints PASS or FAIL to the output panel.
extends Node

# Creates a standard grid for testing: cell size 4, world bounds from -20 to +20
func make_grid() -> SpatialHashGridFast:
	return SpatialHashGridFast.new(
		4.0,
		Vector3(-20, -20, -20),
		Vector3(20, 20, 20)
	)

# Creates a client at a given position
func make_client(pos: Vector3) -> SpatialClient:
	var c = SpatialClient.new(pos, null)
	return c

# Checks a condition and prints PASS or FAIL with a message
func check(condition: bool, msg: String) -> void:
	if condition:
		print("PASS:  " + msg)
	else:
		print("FAIL:  " + msg)

# Test: after inserting a client, it should be found nearby
func test_insert() -> void:
	var grid = make_grid()
	var c = make_client(Vector3(0, 0, 0))
	grid.insert(c)

	var results = grid.find_nearby(Vector3(0, 0, 0), 1.0)
	check(results.has(c), "inserted client should be found")

# Test: After removing a client, it should no longer be found
func test_remove() -> void:
	var grid = make_grid()
	var c = make_client(Vector3(0, 0, 0))
	grid.insert(c)
	grid.remove(c)

	var results = grid.find_nearby(Vector3(0, 0, 0), 1.0)
	check(not results.has(c), "removed client should not be found")

# Test: moving a client to a new cell should update its position in the grid
func test_update_moves_cell() -> void:
	var grid = make_grid()
	var c = make_client(Vector3(0, 0, 0))
	grid.insert(c)

	var old_pos = c.position
	c.position = Vector3(10, 10, 10)
	grid.update(c, old_pos)

	var at_old = grid.find_nearby(old_pos, 0.5)
	var at_new = grid.find_nearby(Vector3(10, 10, 10), 0.5)

	check(at_old.is_empty(), "client should not be at old position")
	check(at_new.has(c), "client should be at new position")

# Test: Small movement within the same cell should still keep the client findable
func test_update_same_cell() -> void:
	var grid = make_grid()
	var c = make_client(Vector3(0, 0, 0))
	grid.insert(c)

	var old_pos = c.position
	c.position = Vector3(0.1, 0.1, 0.1)
	grid.update(c, old_pos)

	var results = grid.find_nearby(Vector3(0.1, 0.1, 0.1), 1.0)
	check(results.has(c), "client should still be found after small move")

# Test: Only near client should be found
func test_find_nearby() -> void:
	var grid = make_grid()
	var near = make_client(Vector3(1, 0, 0))
	var far = make_client(Vector3(15, 0, 0))
	grid.insert(near)
	grid.insert(far)

	var results = grid.find_nearby(Vector3(0, 0, 0), 3.0)
	check(results.has(near), "close client should be found")
	check(not results.has(far), "distant client should not be found")

# Test: Radius spanning multiple cells should include clients from all relevant cells
func test_multi_cell_radius() -> void:
	var grid = make_grid()
	var a = make_client(Vector3(-4, 0, 0))
	var b = make_client(Vector3(4, 0, 0))
	grid.insert(a)
	grid.insert(b)

	var results = grid.find_nearby(Vector3(0, 0, 0), 6.0)
	check(results.has(a), "left cell client should be found with wide radius")
	check(results.has(b), "right cell client should be found with wide radius")

# Test: Multiple clients in the same cell should all be returned
func test_multiple_in_same_cell() -> void:
	var grid = make_grid()
	var a = make_client(Vector3(0.0, 0, 0))
	var b = make_client(Vector3(0.1, 0, 0))
	var c = make_client(Vector3(0.2, 0, 0))
	grid.insert(a)
	grid.insert(b)
	grid.insert(c)

	var results = grid.find_nearby(Vector3(0, 0, 0), 1.0)
	check(results.has(a), "client a should be found")
	check(results.has(b), "client b should be found")
	check(results.has(c), "client c should be found")

# Test: Reinserting the same client should not create duplicates
func test_reinsert_no_duplicate() -> void:
	var grid = make_grid()
	var c = make_client(Vector3(0, 0, 0))
	grid.insert(c)
	grid.insert(c)

	var results = grid.find_nearby(Vector3(0, 0, 0), 1.0)
	var count = 0
	for r in results:
		if r == c:
			count += 1
	check(count == 1, "client should only appear once after double insert")

# Test: Removing the head node should not affect other clients in the same cell
func test_remove_head_node() -> void:
	var grid = make_grid()
	var a = make_client(Vector3(0.0, 0, 0))
	var b = make_client(Vector3(0.1, 0, 0))
	var head = make_client(Vector3(0.2, 0, 0))

	grid.insert(a)
	grid.insert(b)
	grid.insert(head) # last inserted becomes head

	grid.remove(head)

	var results = grid.find_nearby(Vector3(0, 0, 0), 1.0)
	check(not results.has(head), "removed head should not be found")
	check(results.has(a), "remaining client a should still be found")
	check(results.has(b), "remaining client b should still be found")

# Test: Removing a client that does not exist should not crash
func test_remove_nonexistent() -> void:
	var grid = make_grid()
	var c = make_client(Vector3(0, 0, 0))

	grid.remove(c)
	check(true, "removing a nonexistent client should not crash")

# Test: After clearing the grid, no clients should be found
func test_clear() -> void:
	var grid = make_grid()

	grid.insert(make_client(Vector3(0, 0, 0)))
	grid.insert(make_client(Vector3(5, 0, 0)))
	grid.insert(make_client(Vector3(10, 0, 0)))

	grid.clear()

	var results = grid.find_nearby(Vector3(0, 0, 0), 50.0)
	check(results.is_empty(), "grid should be empty after clear")

# Tester
func _ready() -> void:
	print("\n======== SpatialHashGridFast Tests ========\n")

	test_insert()
	test_remove()
	test_update_moves_cell()
	test_update_same_cell()
	test_find_nearby()
	test_multi_cell_radius()
	test_multiple_in_same_cell()
	test_reinsert_no_duplicate()
	test_remove_head_node()
	test_remove_nonexistent()
	test_clear()

	print("\n======== Done ========")
