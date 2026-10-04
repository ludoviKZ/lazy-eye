@tool
class_name EnemyFOV
extends Area3D
## A visible field-of-view cone. Add as a child of an enemy/camera and it
## follows its parent. The cone points along the node's local -Z axis
## (Godot's "forward"), so rotate the EnemyFOV node to aim it.

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
## Smoothness of the cone (more segments = rounder).
@export_range(4, 64) var segments: int = 24:
	set(value):
		segments = value
		_rebuild()

@export_group("Visuals")
@export var show_cone: bool = true:
	set(value):
		show_cone = value
		if _mesh_instance:
			_mesh_instance.visible = value
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
var _players_inside: Array[Node3D] = []


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


## True while at least one player is inside the cone.
func is_player_inside() -> bool:
	return not _players_inside.is_empty()


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_players_inside.append(body)
	_update_color()
	player_entered.emit(body)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_players_inside.erase(body)
	_update_color()
	player_exited.emit(body)


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
	var apex := Vector3.ZERO
	var center := Vector3(0, 0, -view_distance)

	# Elliptical ring at the far end of the cone.
	var ring: Array[Vector3] = []
	for i in segments:
		var a := TAU * float(i) / float(segments)
		ring.append(Vector3(cos(a) * half_w, sin(a) * half_h, -view_distance))

	# Collision: convex hull of apex + ring.
	var points := PackedVector3Array([apex])
	points.append_array(ring)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	_collision_shape.shape = shape

	# Visual mesh: side triangles + far cap.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var p1 := ring[i]
		var p2 := ring[(i + 1) % segments]
		st.add_vertex(apex)
		st.add_vertex(p1)
		st.add_vertex(p2)
		st.add_vertex(center)
		st.add_vertex(p2)
		st.add_vertex(p1)
	_mesh_instance.mesh = st.commit()
