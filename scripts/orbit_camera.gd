extends Camera3D
@export var scroll_speed: float = 5.0
@export var speed: float = 20.0
@export var mouse_sensitivity: float = 0.002

var yaw := 0.0
var pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)
		
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:  # global_position: position of camera in the world
			global_position -= transform.basis.z * scroll_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			global_position += transform.basis.z * scroll_speed
			
			
func _process(delta):
	# Rotation
	rotation = Vector3(pitch, yaw, 0)

	# Movement
	var dir = Vector3.ZERO

	
	if Input.is_key_pressed(KEY_A): dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D): dir += transform.basis.x
	if Input.is_key_pressed(KEY_Q): dir += transform.basis.y
	if Input.is_key_pressed(KEY_E): dir -= transform.basis.y

	if dir != Vector3.ZERO:
		translate(dir.normalized() * speed * delta)
