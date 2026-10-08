extends Node3D
signal alarm_triggered(player_position: Vector3)

enum State { SWEEP, TRACK }

@export_group("Sweep")
## Total sweep width in degrees, centered on the camera's forward direction.
@export_range(10.0, 340.0, 1.0) var sweep_angle: float = 90.0
## Degrees per second.
@export var sweep_speed: float = 25.0
## Seconds the cone pauses at each end of the sweep.
@export var end_pause: float = 1.5
## Downward tilt while sweeping, in degrees (negative = looking down).
@export_range(-80.0, 80.0, 1.0) var idle_pitch: float = -15.0

@export_group("Tracking")
## How quickly the cone turns to follow the player.
@export var track_speed: float = 6.0
## Furthest the cone can turn from center to follow the player (each side).
@export_range(10.0, 179.0, 1.0) var max_turn_angle: float = 120.0
@export_range(-89.0, 0.0, 1.0) var min_pitch: float = -70.0
@export_range(0.0, 89.0, 1.0) var max_pitch: float = 30.0
## Keeps following the player for this long after they leave the view.
@export var lose_sight_delay: float = 1.0

@export_group("Alarm")
## Enemies within this distance are called.
@export var alert_radius: float = 30.0
## Group the patrolling enemies belong to (enemy.gd adds itself to this).
@export var enemy_group: StringName = &"patrol_enemies"
## While the player stays spotted, enemies get a fresh position this often.
@export var realert_interval: float = 1.0

@onready var fov: EnemyFOV = $EnemyFOV
@onready var meter: DetectionMeter = get_node_or_null("DetectionMeter")

var state: State = State.SWEEP

var _sweep_dir: float = 1.0
var _pause_left: float = 0.0
var _time_since_seen: float = 999.0
var _alert_timer: float = 0.0
var _alarm_active: bool = false
var _player: Node3D


func _ready() -> void:
	fov.rotation = Vector3(deg_to_rad(idle_pitch), 0.0, 0.0)


func _physics_process(delta: float) -> void:
	if fov.is_player_inside():
		_time_since_seen = 0.0
	else:
		_time_since_seen += delta

	var player := _get_player()
	if player != null and _time_since_seen < lose_sight_delay:
		state = State.TRACK
		_track(player, delta)
	else:
		state = State.SWEEP
		_alarm_active = false
		_alert_timer = 0.0
		_sweep(delta)


func _sweep(delta: float) -> void:
	# Settle back to the idle tilt (also after tracking the player).
	var settle := clampf(track_speed * 0.5 * delta, 0.0, 1.0)
	fov.rotation.x = lerp_angle(fov.rotation.x, deg_to_rad(idle_pitch), settle)

	if _pause_left > 0.0:
		_pause_left -= delta
		return

	# Move toward one end; works from wherever tracking left the cone.
	var target := deg_to_rad(sweep_angle) * 0.5 * _sweep_dir
	fov.rotation.y = move_toward(fov.rotation.y, target, deg_to_rad(sweep_speed) * delta)
	if is_equal_approx(fov.rotation.y, target):
		_sweep_dir = -_sweep_dir
		_pause_left = end_pause


func _track(player: Node3D, delta: float) -> void:
	# Aim at the same point the FOV's line-of-sight ray uses.
	var target := player.global_position + Vector3.UP * fov.target_height_offset
	var offset := to_local(target) - fov.position
	var horizontal := Vector2(offset.x, offset.z).length()

	var limit := deg_to_rad(max_turn_angle)
	var yaw := clampf(atan2(-offset.x, -offset.z), -limit, limit)
	var pitch := clampf(atan2(offset.y, horizontal), deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	var t := clampf(track_speed * delta, 0.0, 1.0)
	fov.rotation.y = lerp_angle(fov.rotation.y, yaw, t)
	fov.rotation.x = lerp_angle(fov.rotation.x, pitch, t)

	# Raise the alarm once the meter is full (immediately if there's no meter),
	# but only while the player is genuinely in view.
	var meter_full := meter == null or meter.get_progress() >= 1.0
	if meter_full and fov.is_player_inside():
		_alert_timer -= delta
		if _alert_timer <= 0.0:
			_alert_timer = realert_interval
			_raise_alarm(player.global_position)


func _raise_alarm(player_position: Vector3) -> void:
	if not _alarm_active:
		_alarm_active = true
		alarm_triggered.emit(player_position)

	for enemy in get_tree().get_nodes_in_group(enemy_group):
		var enemy_3d := enemy as Node3D
		if enemy_3d == null or not enemy.has_method("alert"):
			continue
		if global_position.distance_to(enemy_3d.global_position) <= alert_radius:
			enemy.call("alert", player_position)


func _get_player() -> Node3D:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player
