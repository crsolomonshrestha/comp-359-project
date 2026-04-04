extends Node3D

@export var entity_count: int = 100
@export var world_size: float = 40.0
@export var cell_size: float = 2
@export var collision_radius: float = 1
@export var entity_speed: float = 8.0
@export var sphere_radius: float = 0.45
var show_grid: bool = false
var grid_im_mesh: ImmediateMesh
var grid_mesh_instance: MeshInstance3D
var grid_toggle_button: CheckButton
var candidates: Array = []

const BASE_COLOR := Color(0.2, 0.5, 1.0)
const COLLISION_COLOR := Color(1.0, 0.35, 0.1)

var grid_fast: SpatialHashGridOptimized
var grid: SpatialHashGrid
var naive := Naive.new()

var clients: Array[SpatialClient] = []
var velocities: Array[Vector3] = []
var collision_flags: Array[bool] = []

var shared_mesh: SphereMesh
var multi_mesh: MultiMesh
var multi_mesh_instance: MultiMeshInstance3D
var fps_label: Label
var info_label: Label

var collision_pair_count: int = 0
var broadphase_candidate_count: int = 0
var query_time_ms: float = 0.0
var print_timer := 0.0
var print_interval := 5.0

var mode := 0

func _ready() -> void:
    randomize()
    _setup_environment()
    _setup_ui()
    _setup_shared_mesh()
    _setup_simulation()
    _setup_grid_visual()

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        mode = (mode + 1) % 3
        _rebuild_grid()
        print("Mode switched — ", ["Naive", "Spatial", "SpatialFast"][mode])

    grid_toggle_button.disabled = (mode == 0)
    if mode == 0:
        show_grid = false
        grid_toggle_button.button_pressed = false

    _move_entities(delta)
    _detect_collisions()
    _update_visuals()
    _update_ui()
    _update_grid_visual()

    print_timer += delta
    if print_timer >= print_interval:
        print_timer = 0.0
        print(
            "Entities: ", entity_count,
            " | Mode: ", ["Naive", "Spatial", "SpatialFast"][mode],
            " | Query(ms): ", query_time_ms,
            " | Candidates: ", broadphase_candidate_count,
            " | Collisions: ", collision_pair_count
        )

func _setup_grid_visual() -> void:
    grid_im_mesh = ImmediateMesh.new()
    grid_mesh_instance = MeshInstance3D.new()
    grid_mesh_instance.mesh = grid_im_mesh

    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(0.1, 1.0, 0.55, 0.6)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    grid_mesh_instance.material_override = mat
    add_child(grid_mesh_instance)

func _update_grid_visual() -> void:
    grid_im_mesh.clear_surfaces()
    if not show_grid or mode == 0:
        return

    var occupied := {}

    if mode == 1:
        for key in grid._cells.keys():
            occupied[key] = true
    else: # mode == 2
        var ics := grid_fast._inv_cell_size
        for c in clients:
            var p: Vector3 = c.position
            occupied[Vector3i(floori(p.x * ics), floori(p.y * ics), floori(p.z * ics))] = true

    grid_im_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    for key: Vector3i in occupied.keys():
        var o := Vector3(key.x, key.y, key.z) * cell_size
        var s := cell_size

        var v := [
            o, o + Vector3(s, 0, 0),
            o + Vector3(s, s, 0), o + Vector3(0, s, 0),
            o + Vector3(0, 0, s), o + Vector3(s, 0, s),
            o + Vector3(s, s, s), o + Vector3(0, s, s),
        ]

        for edge in [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]]:
            grid_im_mesh.surface_add_vertex(v[edge[0]])
            grid_im_mesh.surface_add_vertex(v[edge[1]])
    grid_im_mesh.surface_end()
    
func _setup_simulation() -> void:
    var world_min := Vector3(-world_size, -world_size, -world_size)
    var world_max := Vector3(world_size, world_size, world_size)

    grid_fast = SpatialHashGridOptimized.new(cell_size, world_min, world_max)
    grid = SpatialHashGrid.new(cell_size, world_min, world_max)

    clients.resize(entity_count)
    velocities.resize(entity_count)
    collision_flags.resize(entity_count)

    for i in range(entity_count):
        var pos := Vector3(
            randf_range(-world_size, world_size),
            randf_range(-world_size, world_size),
            randf_range(-world_size, world_size)
        )

        multi_mesh.set_instance_transform(i, Transform3D(Basis(), pos))
        multi_mesh.set_instance_color(i, BASE_COLOR)

        var client := SpatialClient.new(pos, null)
        client.index = i

        var velocity := Vector3(
            randf_range(-1.0, 1.0),
            randf_range(-1.0, 1.0),
            randf_range(-1.0, 1.0)
        )

        if velocity.length_squared() < 0.0001:
            velocity = Vector3.RIGHT

        velocity = velocity.normalized() * entity_speed

        clients[i] = client
        velocities[i] = velocity
        collision_flags[i] = false

        grid_fast.insert(client)
        grid.insert(client)

func _rebuild_grid() -> void:
    var world_min := Vector3(-world_size, -world_size, -world_size)
    var world_max := Vector3(world_size, world_size, world_size)

    if mode == 1:
        grid = SpatialHashGrid.new(cell_size, world_min, world_max)
        for c in clients:
            grid.insert(c)
    elif mode == 2:
        grid_fast = SpatialHashGridOptimized.new(cell_size, world_min, world_max)
        for c in clients:
            grid_fast.insert(c)

func _setup_shared_mesh() -> void:
    shared_mesh = SphereMesh.new()
    shared_mesh.radius = sphere_radius
    shared_mesh.height = sphere_radius * 2.0
    shared_mesh.radial_segments = 12
    shared_mesh.rings = 6

    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.emission_enabled = true
    material.emission_energy_multiplier = 0.35
    shared_mesh.material = material

    multi_mesh = MultiMesh.new()
    multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
    multi_mesh.use_colors = true
    multi_mesh.mesh = shared_mesh
    multi_mesh.instance_count = entity_count

    multi_mesh_instance = MultiMeshInstance3D.new()
    multi_mesh_instance.multimesh = multi_mesh
    add_child(multi_mesh_instance)

    var camera = Camera3D.new()
    camera.set_script(preload("res://scripts/orbit_camera.gd"))
    add_child(camera)
    camera.current = true

func _setup_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.05, 0.06, 0.1)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.35, 0.35, 0.4)
    environment.ambient_light_energy = 0.8
    world_environment.environment = environment
    add_child(world_environment)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45.0, 25.0, 0.0)
    light.light_energy = 1.5
    add_child(light)

func _setup_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    var panel := VBoxContainer.new()
    panel.position = Vector2(12, 12)
    canvas.add_child(panel)

    fps_label = Label.new()
    fps_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(fps_label)

    info_label = Label.new()
    info_label.add_theme_font_size_override("font_size", 16)
    panel.add_child(info_label)

    grid_toggle_button = CheckButton.new()
    grid_toggle_button.text = "Show Grid"
    grid_toggle_button.add_theme_font_size_override("font_size", 16)
    grid_toggle_button.disabled = true # off in Naive mode (mode 0)
    grid_toggle_button.toggled.connect(func(on): show_grid = on)
    panel.add_child(grid_toggle_button)

func _move_entities(delta: float) -> void:
    for i in range(entity_count):
        var client := clients[i]
        var old_position := client.position
        var velocity := velocities[i]
        var new_position := old_position + velocity * delta

        if new_position.x > world_size:
            new_position.x = world_size
            velocity.x *= -1.0
        elif new_position.x < -world_size:
            new_position.x = - world_size
            velocity.x *= -1.0

        if new_position.y > world_size:
            new_position.y = world_size
            velocity.y *= -1.0
        elif new_position.y < -world_size:
            new_position.y = - world_size
            velocity.y *= -1.0

        if new_position.z > world_size:
            new_position.z = world_size
            velocity.z *= -1.0
        elif new_position.z < -world_size:
            new_position.z = - world_size
            velocity.z *= -1.0

        client.position = new_position
        velocities[i] = velocity

        if mode == 1:
            grid.update(client, old_position)
        elif mode == 2:
            grid_fast.update(client, old_position)

func _detect_collisions() -> void:
    var start_time = Time.get_ticks_usec()
    var radius_sq = collision_radius * collision_radius

    collision_pair_count = 0
    broadphase_candidate_count = 0

    for i in range(entity_count):
        collision_flags[i] = false

    for i in range(entity_count):
        var client = clients[i]

        if mode == 0:
            candidates = naive.get_nearby(client, collision_radius, clients)
            broadphase_candidate_count += candidates.size()
            for other in candidates:
                if other == client:
                    continue
                var other_client = other as SpatialClient
                var j = other_client.index
                if j <= i:
                    continue
                if client.position.distance_squared_to(other_client.position) <= radius_sq:
                    collision_flags[i] = true
                    collision_flags[j] = true
                    collision_pair_count += 1

        elif mode == 1:
            grid.find_nearby(client.position, collision_radius, candidates)
            broadphase_candidate_count += candidates.size()
            for other in candidates:
                if other == client:
                    continue
                var other_client = other as SpatialClient
                var j = other_client.index
                if j <= i:
                    continue
                if client.position.distance_squared_to(other_client.position) <= radius_sq:
                    collision_flags[i] = true
                    collision_flags[j] = true
                    collision_pair_count += 1

        else:
            grid_fast.find_nearby(client.position, collision_radius)
            broadphase_candidate_count += grid_fast.query_size
            for k in range(grid_fast.query_size):
                var j: int = grid_fast.query_ids[k]
                if j <= i:
                    continue
                if client.position.distance_squared_to(clients[j].position) <= radius_sq:
                    collision_flags[i] = true
                    collision_flags[j] = true
                    collision_pair_count += 1

    query_time_ms = (Time.get_ticks_usec() - start_time) / 1000.0
func _update_ui() -> void:
    fps_label.text = "FPS: %.1f" % Engine.get_frames_per_second()
    info_label.text = "Entities: %d\nCollisions: %d\nCandidates: %d\nQuery Time: %.2f ms\nMode: %s" % [
        entity_count,
        collision_pair_count,
        broadphase_candidate_count,
        query_time_ms,
        ["Naive", "Spatial", "SpatialFast"][mode]
    ]

func _update_visuals() -> void:
    for i in range(entity_count):
        var client := clients[i]
        multi_mesh.set_instance_transform(i, Transform3D(Basis(), client.position))

        if collision_flags[i]:
            multi_mesh.set_instance_color(i, COLLISION_COLOR)
        else:
            multi_mesh.set_instance_color(i, BASE_COLOR)
