extends MeshInstance3D

var speed: float = 25.0

#func _ready():
	#var mesh = BoxMesh.new()
	#mesh.size = Vector3(10, 100, 10)  # tall column, 8x8 on XZ
	#set_mesh(mesh)
	#var mat = StandardMaterial3D.new()
	#mat.albedo_color = Color(1, 1, 0, 0.2)  # transparent yellow
	#mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # visible from inside
	#set_surface_override_material(0, mat)

func _process(delta):
	if Input.is_key_pressed(KEY_LEFT): position.x -= speed * delta
	if Input.is_key_pressed(KEY_RIGHT): position.x += speed * delta
	if Input.is_key_pressed(KEY_UP): position.z -= speed * delta
	if Input.is_key_pressed(KEY_DOWN): position.z += speed * delta
	position = position.clamp(Vector3(-50, 0, -50), Vector3(50, 0, 50))
