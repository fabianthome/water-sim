extends RigidBody3D

@export var max_engine_force: float = 150.0
@export var turn_force: float = 80.0
@export var water_drag: float = 0.98
@export var turn_drag: float = 0.95

var current_engine_force: float = 0.0
var is_accelerating: bool = false

var initial_transform = Vector3(0, 0, 0)

func _ready():
    initial_transform = transform

func _physics_process(delta: float) -> void:
    if position.y <= 0:
        position.y = 0

    handle_input()
    apply_movement_forces()
    apply_drag_forces()

func handle_input() -> void:
    if Input.is_action_pressed("reset_ship"):
        transform = initial_transform

    is_accelerating = Input.is_action_pressed("move_ship")
    
    if is_accelerating:
        current_engine_force = max_engine_force
    else:
        current_engine_force = 0.0

func apply_movement_forces() -> void:
    # Apply forward force
    if current_engine_force > 0:
        var forward_force = transform.basis.z * current_engine_force
        apply_central_force(forward_force)
        
        # Only allow turning when there's forward momentum
        var current_speed = linear_velocity.length()
        if current_speed > 0.5: # Minimum speed threshold for turning
            var turn_input: float = 0.0
            
            if Input.is_action_pressed("turn_ship_left"):
                turn_input = 1.0
            elif Input.is_action_pressed("turn_ship_right"):
                turn_input = -1.0
            
            if turn_input != 0.0:
                # Apply turning torque, scaled by current speed for realistic boat physics
                var speed_factor = min(current_speed / 10.0, 1.0) # Cap the speed factor
                var turning_torque = Vector3(0, turn_input * turn_force * speed_factor, 0)
                apply_torque(turning_torque)

func apply_drag_forces() -> void:
    # Apply water drag to linear velocity (gradual stopping)
    linear_velocity *= water_drag
    
    # Apply drag to angular velocity (stop turning gradually)
    angular_velocity *= turn_drag
