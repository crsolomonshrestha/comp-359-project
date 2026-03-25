class_name SpatialHashGridFast3D
extends Node

var cell_size: float
var _cells: Dictionary = {}

func _init(_cell_size: float):
	cell_size = _cell_size

func _cell_key(x: int, y: int, z: int) -> Vector3i:
	return Vector3i(x, y, z)

func _get_cell_coords(pos: Vector3) -> Vector3i:
	return Vector3i(
		floor(pos.x / cell_size),
		floor(pos.y / cell_size),
		floor(pos.z / cell_size)
	)

func insert(client: SpatialClientFast3D):
	var cell_coords = _get_cell_coords(client.position)
	if not _cells.has(cell_coords):
		_cells[cell_coords] = []
	_cells[cell_coords].append(client)

func remove(client: SpatialClientFast3D):
	var cell_coords = _get_cell_coords(client.position)
	if _cells.has(cell_coords):
		_cells[cell_coords].erase(client)
		if _cells[cell_coords].is_empty():
			_cells.erase(cell_coords)

func update(client: SpatialClientFast3D, old_position: Vector3) -> void:
	var old_cell_coords = _get_cell_coords(old_position)
	var new_cell_coords = _get_cell_coords(client.position)
	if old_cell_coords != new_cell_coords:
		remove(client)
		insert(client)

func clear() -> void:
	_cells.clear()

func _find_nearby(pos: Vector3, radius: float) -> Array:
	var results: Array = []
	var min_coords = _get_cell_coords(pos - Vector3(radius, 100, radius))
	var max_coords = _get_cell_coords(pos + Vector3(radius, 100, radius))
	for x in range(min_coords.x, max_coords.x + 1):
		for y in range(min_coords.y, max_coords.y + 1):
			for z in range(min_coords.z, max_coords.z + 1):
				var cell_key = _cell_key(x, y, z)
				if _cells.has(cell_key):
					results.append_array(_cells[cell_key])
	return results
