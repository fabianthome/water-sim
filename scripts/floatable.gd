extends RigidBody3D

@export_group("Wave Parameters")
# match with shader params
@export var direction: Vector2 = Vector2(1.0, 0.0)
@export var amplitude: float = 0.5
@export var wavelength: float = 4.0
@export var speed: float = 0.7

@export_group("Buoyancy Settings")
@export var float_force: float = 5.0 # strength of upward push
@export var water_drag: float = 0.98 # slow down movement when submerged
@export var water_angular_drag: float = 0.95 # slow down rotation when submerged

var time: float = 0.0

func _physics_process(delta: float) -> void:
    time += delta
    
    # get horizontal position
    var pos = global_position
    
    # replicate shader math
    var k = 2.0 * PI / wavelength
    var d = direction.normalized()
    
    # phase = k * (d dot xz) - (speed * TIME)
    var phase = k * (d.dot(Vector2(pos.x, pos.z)) - (speed * time))
    
    var water_height = amplitude * sin(phase)
    
    # apply forces
    if pos.y < water_height:
        # calculate how deep the object is
        var depth = water_height - pos.y
        var displacement = clamp(depth, 0.0, 1.0)
        
        # archimedes force: applying upward force based on depth
        # keep it consistent with physics engine (gravity)
        var force = Vector3.UP * displacement * float_force * abs(PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY))
        apply_central_force(force)
        
        # simulate water resistance (viscosity)
        linear_velocity *= water_drag
        angular_velocity *= water_angular_drag
