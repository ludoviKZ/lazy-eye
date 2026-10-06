extends CharacterBody3D
## Patrolling enemy.
## PATROL -> WAIT (at each point) -> PATROL ...
## Player seen  -> SUSPICIOUS (stops and stares until the DetectionMeter fills)
## Meter full   -> CHASE (follows the player while in line of sight, then goes
##                 to the last place it saw them)
## Lost / gone  -> SEARCH (looks left and right) -> back to PATROL

signal player_caught(player: Node3D)

enum State { PATROL, WAIT, SUSPICIOUS, CHASE, SEARCH }

@export_group("Patrol")
## A Node3D whose children are the patrol points (PatrolPoint or any Node3D).
## Must NOT be a child of the enemy, or the points would move with it.
@export var route: Node3D
@export var patrol_speed: float = 1.5
## Wait time for points that aren't PatrolPoint nodes.
@export var default_wait_time: float = 2.0
@export var arrive_distance: float = 0.4

@export_group("Detection")
## Only used when the enemy has no DetectionMeter child: seconds it stares
## at the player before starting to chase.
@export var reaction_time: float = 1.0
## The player must be out of sight this long before the enemy treats them as
## lost. Stops rapid flip-flopping when the player is at the edge of the cone.
@export var lose_sight_delay: float = 0.5

@export_group("Chase")
@export var chase_speed: float = 3.5
@export var repath_interval: float = 0.2
## Distance at which `player_caught` is emitted (once per chase).
@export var catch_distance: float = 1.2

@export_group("Search")
@export var search_time: float = 4.0
## How far (degrees) it turns left and right while searching.
@export var look_angle: float = 70.0
## Seconds for one full left-right-left sweep.
@export var look_period: float = 2.5

@export_group("Movement")
@export var turn_speed: float = 8.0

@export_group("Animation")
@export var animation_player: AnimationPlayer
## Names must exist on the AnimationPlayer (add a library prefix if needed,
## e.g. "UAL/Idle"). Missing names are skipped silently.
@export var idle_animation: String = "Idle"
@export var walk_animation: String = "Walk"
@export var run_animation: String = "Jog_Fwd"

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var fov: EnemyFOV = $EnemyFOV
@onready var meter: DetectionMeter = get_node_or_null("DetectionMeter")

var state: State = State.PATROL

var _state_time: float = 0.0
var _points: Array[Node3D] = []
var _patrol_index: int = 0
var _last_known: Vector3
var _repath_timer: float = 0.0
var _search_base_yaw: float = 0.0
var _caught: bool = false
var _active: bool = false
var _time_since_seen: float = 999.0
var _warned_no_path: bool = false
var _anim_cache: Dictionary = {}
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	# Use the AnimationPlayer that's already inside the model.
	if animation_player == null:
		animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if route:
		for child in route.get_children():
			if child is Node3D:
				_points.append(child)
	_setup.call_deferred()


func _setup() -> void:
	# The navigation map isn't ready on the first frame.
	await get_tree().physics_frame
	_active = true
	_set_state(State.PATROL)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if fov != null and fov.is_player_inside():
		_time_since_seen = 0.0
	else:
		_time_since_seen += delta

	if _active:
		_state_time += delta
		match state:
			State.PATROL: _process_patrol(delta)
			State.WAIT: _process_wait(delta)
			State.SUSPICIOUS: _process_suspicious(delta)
			State.CHASE: _process_chase(delta)
			State.SEARCH: _process_search(delta)

	move_and_slide()
	_update_animation()


# --- States ------------------------------------------------------------------

func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	match new_state:
		State.PATROL:
			if not _points.is_empty():
				nav.target_position = _points[_patrol_index].global_position
		State.CHASE:
			_caught = false
			_repath_timer = 0.0
			var player := _get_player()
			if player:
				_last_known = player.global_position
		State.SEARCH:
			_search_base_yaw = global_rotation.y
			if meter:
				meter.reset()


func _process_patrol(delta: float) -> void:
	if _can_see_player():
		_set_state(State.SUSPICIOUS)
		return
	if _points.is_empty():
		_stop(delta)
		return
	_move_along_path(patrol_speed, delta)
	if not _warned_no_path and _state_time > 0.5 and nav.get_current_navigation_path().is_empty():
		_warned_no_path = true
		push_warning("Enemy has no navigation path to its patrol point. Is the navmesh baked, and is the level geometry a child of the NavigationRegion3D?")
	if _arrived():
		_set_state(State.WAIT)


func _process_wait(delta: float) -> void:
	_stop(delta)
	if _can_see_player():
		_set_state(State.SUSPICIOUS)
		return
	if _state_time >= _wait_time_at(_patrol_index):
		_patrol_index = (_patrol_index + 1) % _points.size()
		_set_state(State.PATROL)


func _process_suspicious(delta: float) -> void:
	_stop(delta)
	var player := _get_player()
	if player:
		_face_position(player.global_position, delta)

	if not _can_see_player():
		_set_state(State.SEARCH)  # player left before being confirmed
		return

	var confirmed: bool
	if meter:
		confirmed = meter.time_in_view >= meter.max_time
	else:
		confirmed = _state_time >= reaction_time
	if confirmed:
		_set_state(State.CHASE)


func _process_chase(delta: float) -> void:
	var player := _get_player()
	var sees_player := _can_see_player()

	if sees_player and player:
		_last_known = player.global_position
		if not _caught and global_position.distance_to(player.global_position) <= catch_distance:
			_caught = true
			player_caught.emit(player)

	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = repath_interval
		nav.target_position = _last_known

	_move_along_path(chase_speed, delta)

	# Lost sight: keep going to the last known position, then search there.
	if not sees_player and _arrived():
		_set_state(State.SEARCH)


func _process_search(delta: float) -> void:
	_stop(delta)
	global_rotation.y = _search_base_yaw + sin(_state_time * TAU / look_period) * deg_to_rad(look_angle)

	if _can_see_player():
		_set_state(State.SUSPICIOUS)
		return
	if _state_time >= search_time:
		_set_state(State.PATROL)  # resumes at the point it was heading to


# --- Helpers -----------------------------------------------------------------

func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _can_see_player() -> bool:
	# True while the player is visible, plus a short grace period after.
	return _time_since_seen < lose_sight_delay


func _wait_time_at(index: int) -> float:
	var point := _points[index]
	if point is PatrolPoint:
		return (point as PatrolPoint).wait_time
	return default_wait_time


func _arrived() -> bool:
	var offset := global_position - nav.target_position
	offset.y = 0.0
	if offset.length() <= arrive_distance:
		return true
	# Fallback for targets that can't be reached exactly.
	return _state_time > 0.3 and nav.is_navigation_finished()


func _move_along_path(speed: float, delta: float) -> void:
	var next_position := nav.get_next_path_position()
	var direction := next_position - global_position
	direction.y = 0.0
	if direction.length() < 0.05:
		_stop(delta)
		return
	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_face_direction(direction, delta)


func _stop(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)


func _face_direction(direction: Vector3, delta: float) -> void:
	# The body's forward is -Z, which is also where the EnemyFOV points.
	# Uses world rotation so a rotated parent node can't flip the enemy.
	var target_yaw := atan2(-direction.x, -direction.z)
	global_rotation.y = lerp_angle(global_rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))


func _face_position(target: Vector3, delta: float) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if direction.length() > 0.01:
		_face_direction(direction.normalized(), delta)


func _update_animation() -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var anim_name := idle_animation
	if horizontal_speed > 0.3:
		anim_name = run_animation if state == State.CHASE else walk_animation
	_play_animation(anim_name)


func _play_animation(anim_name: String) -> void:
	if animation_player == null:
		return
	var resolved := _resolve_animation(anim_name)
	if resolved.is_empty():
		return
	if animation_player.current_animation != resolved:
		animation_player.get_animation(resolved).loop_mode = Animation.LOOP_LINEAR
		animation_player.play(resolved, 0.2)


## Finds "Idle" even when it's stored as "SomeLibrary/Idle".
func _resolve_animation(anim_name: String) -> String:
	if _anim_cache.has(anim_name):
		return _anim_cache[anim_name]
	var result := ""
	if animation_player.has_animation(anim_name):
		result = anim_name
	else:
		for candidate in animation_player.get_animation_list():
			if candidate.ends_with("/" + anim_name):
				result = candidate
				break
	_anim_cache[anim_name] = result
	return result
