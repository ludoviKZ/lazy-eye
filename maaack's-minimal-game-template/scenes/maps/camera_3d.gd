
extends Camera3D

@export var orbit_point: Vector3 = Vector3(0, 1, 0)
@export var orbit_speed: float = 0.12
@export var orbit_width: float = 0.4
@export var look_right_offset: float = 0.5

var start_position: Vector3
var start_angle: float
var radius: float
var elapsed: float = 0.0

func _ready() -> void:
	start_position = global_position
	var offset := start_position - orbit_point
	radius = Vector2(offset.x, offset.z).length()
	start_angle = atan2(offset.x, offset.z)
	

func _process(delta: float) -> void:
	elapsed += delta

	# Smoothly orbit within a narrower range
	var angle := start_angle + sin(-elapsed * orbit_speed) * orbit_width

	global_position = Vector3(
		orbit_point.x + sin(angle) * radius,
		start_position.y,
		orbit_point.z + cos(angle) * radius
	)

	var target := orbit_point + global_basis.x * 2
	look_at(target, Vector3.UP)
