extends MeshInstance3D

var velocity: Vector3
var _mat: StandardMaterial3D

func _ready():
	velocity = Vector3(randf_range(-1,1), 0.0, randf_range(-1,1)).normalized() * 10.0
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color.WHITE
	set_surface_override_material(0, _mat)

func _process(delta):
	position += velocity * delta
	if position.x > 50 or position.x < -50: velocity.x *= -1
	if position.z > 50 or position.z < -50: velocity.z *= -1
	if position.y > 50 or position.y < 20: velocity.y *= -1
	

func set_color(color: Color):
	_mat.albedo_color = color
