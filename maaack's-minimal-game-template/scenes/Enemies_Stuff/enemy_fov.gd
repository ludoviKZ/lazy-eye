@tool
class_name EnemyFOV
extends Area3D
## A visible field-of-view cone. Add as a child of an enemy/camera and it
## follows its parent. The cone points along the node's local -Z axis
## (Godot's "forward"), so rotate the EnemyFOV node to aim it.
## Walls (physics bodies on `occlusion_mask`) clip the cone and block detection.
## NOTE: clipping only happens in game; the editor always shows the full cone.

signal player_entered(player: Node3D)
signal player_exited(player: Node3D)

@export_group("Shape")
## Horizontal field of view in degrees.
@export_range(1.0, 179.0, 0.5) var horizontal_fov: float = 90.0:
	set(value):
		horizontal_fov = value
		_rebuild()
## Vertical field of view in degrees.
@export_range(1.0, 179.0, 0.5) var vertical_fov: float = 60.0:
	set(value):
		vertical_fov = value
		_rebuild()
## How far the enemy can see.
@export_range(0.5, 100.0, 0.1, "or_greater") var view_distance: float = 10.0:
	set(value):
		view_distance = value
		_rebuild()
## Smoothness of the cone (more segments = rounder, but more raycasts).
@export_range(4, 64) var segments: int = 24:
	set(value):
		segments = value
		_rebuild()

@export_group("Occlusion")
## If true, walls clip the cone and block line of sight to the player.
@export var blocked_by_walls: bool = true:
	set(value):
		blocked_by_walls = value
		_rebuild()
## How many rings of rays are cast across the cone. More = walls in the
## middle of the cone are detected more accurately. Total rays per frame
## is about segments * occlusion_rings.
@export_range(1, 8) var occlusion_rings: int = 3:
	set(value):
		occlusion_rings = value
		_rebuild()
## Physics layers that count as walls. Keep the player's layer OUT of this
## if possible (the script also ignores hits on anything in the "player" group).
@export_flags_3d_physics var occlusion_mask: int = 1
## Height above the player's origin to aim the line-of-sight ray at
## (use ~1.0 if the player's origin is at its feet).
@export var target_height_offset: float = 1.0

@export_group("Visuals")
@export var show_cone: bool = true:
	set(value):
		show_cone = value
		if _mesh_instance:
			_mesh_instance.visible = value
## Draw the cone on top of geometry. Leave off with walls enabled for a
## natural look; the cone is already clipped by the raycasts.
@export var visible_through_walls: bool = false:
	set(value):
		visible_through_walls = value
		if _material:
			_material.no_depth_test = value
## Which 3D render layers the cone is drawn on (must overlap the camera's cull mask).
@export_flags_3d_render var visual_layers: int = 1:
	set(value):
		visual_layers = value
		if _mesh_instance:
			_mesh_instance.layers = value
@export var idle_color: Color = Color(1.0, 1.0, 0.2, 0.25):
	set(value):
		idle_color = value
		_update_color()
@export var alert_color: Color = Color(1.0, 0.1, 0.1, 0.35):
	set(value):
		alert_color = value
		_update_color()

var _collision_shape: CollisionShape3D
var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
# Ray targets in local space at full distance. Layout:
# index 0 = center ray, then `occlusion_rings` rings of `segments` points each
# (innermost ring first, outermost ring last).
var _grid: Array[Vector3] = []
var _candidates: Array[Node3D] = []    # players inside the cone volume
var _seen_players: Array[Node3D] = []  # players inside AND in line of sight


func _ready() -> void:
	# Created in code (not saved into the scene), so the .tscn stays trivial.
	_collision_shape = CollisionShape3D.new()
	add_child(_collision_shape)

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.visible = show_cone
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh_instance)

	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.no_depth_test = visible_through_walls
	_material.render_priority = 10
	_mesh_instance.layers = visual_layers
	_mesh_instance.material_override = _material

	_rebuild()
	_update_color()

	if Engine.is_editor_hint():
		return

	# Only detect, never be detected.
	collision_layer = 0
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or _mesh_instance == null:
		return
	if blocked_by_walls and show_cone:
		_update_clipped_mesh()
	_update_line_of_sight()


## True while at least one player is inside the cone with a clear line of sight.
func is_player_inside() -> bool:
	return not _seen_players.is_empty()


# --- Detection ---------------------------------------------------------------

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not _candidates.has(body):
		_candidates.append(body)


func _on_body_exited(body: Node3D) -> void:
	_candidates.erase(body)
	_set_seen(body, false)


func _update_line_of_sight() -> void:
	for body in _candidates:
		_set_seen(body, _has_line_of_sight(body))


func _set_seen(body: Node3D, seen: bool) -> void:
	var was_seen := _seen_players.has(body)
	if seen and not was_seen:
		_seen_players.append(body)
		_update_color()
		player_entered.emit(body)
	elif not seen and was_seen:
		_seen_players.erase(body)
		_update_color()
		player_exited.emit(body)


func _has_line_of_sight(target: Node3D) -> bool:
	if not blocked_by_walls:
		return true
	var hit := _raycast(global_position, target.global_position + Vector3.UP * target_height_offset)
	return _is_clear(hit)


func _is_clear(hit: Dictionary) -> bool:
	if hit.is_empty():
		return true
	var collider := hit.collider as Node
	return collider != null and collider.is_in_group("player")


func _raycast(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, occlusion_mask)
	var parent := get_parent()
	if parent is CollisionObject3D:
		query.exclude = [parent.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)


# --- Visuals -----------------------------------------------------------------

func _update_color() -> void:
	if _material == null:
		return
	_material.albedo_color = alert_color if is_player_inside() else idle_color


func _rebuild() -> void:
	# Setters can fire before _ready() has created the child nodes.
	if _collision_shape == null or _mesh_instance == null:
		return

	var half_w := tan(deg_to_rad(horizontal_fov) * 0.5) * view_distance
	var half_h := tan(deg_to_rad(vertical_fov) * 0.5) * view_distance

	_grid.clear()
	_grid.append(Vector3(0, 0, -view_distance))  # center ray

	# Collision hull = apex + outermost ring.
	var hull := PackedVector3Array([Vector3.ZERO])

	for r in range(1, occlusion_rings + 1):
		var f := float(r) / float(occlusion_rings)
		for i in segments:
			var a := TAU * float(i) / float(segments)
			var p := Vector3(cos(a) * half_w * f, sin(a) * half_h * f, -view_distance)
			_grid.append(p)
			if r == occlusion_rings:
				hull.append(p)

	# Collision: the full, unclipped cone. Walls are handled by raycasts.
	var shape := ConvexPolygonShape3D.new()
	shape.points = hull
	_collision_shape.shape = shape

	_mesh_instance.mesh = _build_mesh(_grid)


func _update_clipped_mesh() -> void:
	var clipped: Array[Vector3] = []
	var origin := global_position
	for local_point in _grid:
		var world_point := to_global(local_point)
		var hit := _raycast(origin, world_point)
		if _is_clear(hit):
			clipped.append(local_point)
		else:
			# Nudge off the wall slightly to avoid z-fighting.
			clipped.append(to_local(hit.position + hit.normal * 0.02))
	_mesh_instance.mesh = _build_mesh(clipped)


## Builds the far surface of the cone from a grid of points, plus the side
## skirt from the apex to the outermost ring.
func _build_mesh(grid: Array[Vector3]) -> ArrayMesh:
	var n := segments
	var rings := occlusion_rings
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Center -> first ring.
	for i in n:
		var j := (i + 1) % n
		_add_tri(st, grid[0], grid[1 + i], grid[1 + j])

	# Bands between consecutive rings.
	for r in range(rings - 1):
		var base_a := 1 + r * n
		var base_b := 1 + (r + 1) * n
		for i in n:
			var j := (i + 1) % n
			_add_tri(st, grid[base_a + i], grid[base_b + i], grid[base_a + j])
			_add_tri(st, grid[base_a + j], grid[base_b + i], grid[base_b + j])

	# Side skirt: apex -> outermost ring.
	var outer := 1 + (rings - 1) * n
	for i in n:
		var j := (i + 1) % n
		_add_tri(st, Vector3.ZERO, grid[outer + i], grid[outer + j])

	return st.commit()


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
