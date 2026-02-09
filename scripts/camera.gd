extends Camera3D

@export_group("Movement")
@export var speed: float = 10.0
@export var acceleration: float = 5.0
@export var friction: float = 10.0

@export_group("Rotation")
@export var sensitivity: float = 0.15
@export var smooth_speed: float = 15.0

var velocity := Vector3.ZERO
var look_angles := Vector2.ZERO
var is_looking := false

var barrel_toggle := true
var grow_factor := 2

@onready var solid_mesh = get_parent().get_node("SolidMesh")
@onready var sine_mesh = get_parent().get_node("SineMesh")
@onready var barrel = get_parent().get_node("Barrel")
@onready var gerstner_mesh = get_parent().get_node("GerstnerMesh")
@onready var gerstner_sum_mesh = get_parent().get_node("GerstnerSumMesh")
@onready var fbm_mesh = get_parent().get_node("FBMMesh")
@onready var fbm_27_mesh = get_parent().get_node("FBM27x27")

func _ready():
    look_angles.y = rotation_degrees.y
    look_angles.x = rotation_degrees.x


func _input(event):
    # RMB starts look event
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            is_looking = event.pressed
            if is_looking:
                Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            else:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

    # mouse motion moves head
    if event is InputEventMouseMotion and is_looking:
        look_angles.y -= event.relative.x * sensitivity
        look_angles.x -= event.relative.y * sensitivity
        look_angles.x = clamp(look_angles.x, -89, 89) # prevent camera flipping

func _process(delta):
    if Input.is_action_just_pressed("reframe"):
        position = Vector3(-7.5, 1.5, 0.0)
        rotation_degrees = Vector3(0.0, -90.0, 0.0)
        look_angles.x = 0.0
        look_angles.y = -90.0
    else:
        rotation_degrees.x = lerp(rotation_degrees.x, look_angles.x, smooth_speed * delta)
        rotation_degrees.y = lerp(rotation_degrees.y, look_angles.y, smooth_speed * delta)

    # move using WASD + QE
    var input_dir = Vector3.ZERO
    if Input.is_key_pressed(KEY_W): input_dir.z -= 1
    if Input.is_key_pressed(KEY_S): input_dir.z += 1
    if Input.is_key_pressed(KEY_A): input_dir.x -= 1
    if Input.is_key_pressed(KEY_D): input_dir.x += 1
    if Input.is_key_pressed(KEY_Q): input_dir.y -= 1
    if Input.is_key_pressed(KEY_E): input_dir.y += 1

    var direction = (transform.basis * input_dir.normalized())
    # velocity with acceleration/friction
    if input_dir.length() > 0:
        velocity = velocity.lerp(direction * speed, acceleration * delta)
    else:
        velocity = velocity.lerp(Vector3.ZERO, friction * delta)

    # move the camera
    global_position += velocity * delta

    # toggle waves to be displayed
    if Input.is_action_just_pressed("solid"):
        sine_mesh.visible = false
        barrel.visible = false
        gerstner_mesh.visible = false
        gerstner_sum_mesh.visible = false
        fbm_mesh.visible = false
        solid_mesh.visible = !solid_mesh.visible
    if Input.is_action_just_pressed("sine"):
        solid_mesh.visible = false
        gerstner_mesh.visible = false
        gerstner_sum_mesh.visible = false
        fbm_mesh.visible = false
        sine_mesh.visible = !sine_mesh.visible
        if !sine_mesh.visible: barrel.visible = false
        else: barrel.visible = !barrel_toggle
    if Input.is_action_just_pressed("barrel") and sine_mesh.visible and sine_mesh.scale.x == 1:
        barrel.visible = barrel_toggle
        barrel_toggle = !barrel_toggle
    if Input.is_action_just_pressed("gerstner"):
        solid_mesh.visible = false
        sine_mesh.visible = false
        barrel.visible = false
        gerstner_sum_mesh.visible = false
        fbm_mesh.visible = false
        gerstner_mesh.visible = !gerstner_mesh.visible
    if Input.is_action_just_pressed("gerstner_sum"):
        solid_mesh.visible = false
        sine_mesh.visible = false
        barrel.visible = false
        gerstner_mesh.visible = false
        fbm_mesh.visible = false
        gerstner_sum_mesh.visible = !gerstner_sum_mesh.visible
    if Input.is_action_just_pressed("fbm"):
        solid_mesh.visible = false
        sine_mesh.visible = false
        barrel.visible = false
        gerstner_mesh.visible = false
        gerstner_sum_mesh.visible = false
        fbm_mesh.visible = !fbm_mesh.visible
    if Input.is_action_just_pressed("hellyea"):
        solid_mesh.visible = false
        sine_mesh.visible = false
        barrel.visible = false
        gerstner_mesh.visible = false
        gerstner_sum_mesh.visible = false
        fbm_mesh.visible = true
        fbm_27_mesh.visible = !fbm_27_mesh.visible
    # alter wave size
    if Input.is_action_just_pressed("grow"):
        _hide_barrel()
        solid_mesh.scale *= grow_factor
        sine_mesh.scale *= grow_factor
        barrel.scale *= grow_factor
        gerstner_mesh.scale *= grow_factor
        gerstner_sum_mesh.scale *= grow_factor
        fbm_mesh.scale *= grow_factor
    if Input.is_action_just_pressed("shrink"):
        _hide_barrel()
        solid_mesh.scale /= grow_factor
        sine_mesh.scale /= grow_factor
        barrel.scale /= grow_factor
        gerstner_mesh.scale /= grow_factor
        gerstner_sum_mesh.scale /= grow_factor
        fbm_mesh.scale /= grow_factor
    if Input.is_action_just_pressed("rescale"):
        solid_mesh.scale = Vector3(1, 1, 1)
        sine_mesh.scale = Vector3(1, 1, 1)
        barrel.scale = Vector3(1, 1, 1)
        gerstner_mesh.scale = Vector3(1, 1, 1)
        gerstner_sum_mesh.scale = Vector3(1, 1, 1)
        fbm_mesh.scale = Vector3(1, 1, 1)

func _hide_barrel():
  barrel.visible = false
  barrel_toggle = true
