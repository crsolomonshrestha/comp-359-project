extends Node3D

@export var ball_scene: PackedScene
@export var detect_radius: float = 8.0
@export var neighbour_radius: float = 16.0

var balls: Array = []
var clients: Array = []
var grid: SpatialHashGridFast3D

func _ready():
	grid = SpatialHashGridFast3D.new(5.0)  # no world size needed anymore
	add_child(grid)
	for i in range(100):
		var b = ball_scene.instantiate()
		# add randf_range(-50, 50) insted of 0 for y, if you want to see the 3d
		b.position = Vector3(randf_range(-50, 50), 0, randf_range(-50, 50))
		add_child(b)
		balls.append(b)
		var client = SpatialClientFast3D.new()
		client.position = b.position
		client.data = b
		grid.insert(client)
		clients.append(client)

func _process(delta):
	for i in clients.size():
		var old_pos = clients[i].position
		clients[i].position = balls[i].position
		grid.update(clients[i], old_pos)
	var detector = $Detector
	var nearby = grid._find_nearby(detector.position, neighbour_radius)
	for b in balls:
		b.set_color(Color.WHITE)
	for client in nearby:
		var dist = client.position.distance_to(detector.position)
		if dist < detect_radius:
			client.data.set_color(Color.RED)
		elif dist < neighbour_radius:
			client.data.set_color(Color.YELLOW)
