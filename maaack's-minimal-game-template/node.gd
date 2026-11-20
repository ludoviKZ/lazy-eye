extends Node
## Shader warm-up for web (Compatibility renderer) builds.
##
## Add this as a plain Node child of your level, as the LAST child so
## everything else is already ready. While a black screen covers the game,
## a temporary camera looks around so shaders compile now instead of the
## first time the player sees each thing.
##
## The player and every enemy (group "patrol_enemies") are visited
## automatically. For rooms with different props or lights, add Marker3D
## nodes to the group "warmup_point" and place them in those rooms.
 
@export var views_per_point: int = 8
@export var frames_per_view: int = 2
## Camera height above the player/enemy origin.
@export var eye_height: float = 1.6
@export var loading_text: String = "Loading..."
 
 
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var overlay := _make_overlay()  # covers the screen before the first frame
	_run(overlay)
	
 
 
func _run(overlay: CanvasLayer) -> void:
	get_tree().paused = true  # enemies and cameras must not react while hidden
 
	var old_camera := get_viewport().get_camera_3d()
	var camera := Camera3D.new()
	add_child(camera)
	camera.make_current()
 
	for point in _collect_points():
		camera.global_position = point
		for i in views_per_point:
			var yaw := TAU * float(i) / float(views_per_point)
			camera.global_rotation = Vector3(deg_to_rad(-5.0), yaw, 0.0)
			for f in frames_per_view:
				await get_tree().process_frame
 
	if is_instance_valid(old_camera):
		old_camera.make_current()
	camera.queue_free()
	overlay.queue_free()
	get_tree().paused = false
	queue_free()
 
 
func _collect_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
 
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		points.append(player.global_position + Vector3.UP * eye_height)
 
	for node in get_tree().get_nodes_in_group("patrol_enemies"):
		var enemy := node as Node3D
		if enemy:
			points.append(enemy.global_position + Vector3.UP * eye_height)
 
	for node in get_tree().get_nodes_in_group("warmup_point"):
		var marker := node as Node3D
		if marker:
			points.append(marker.global_position)
 
	return points
 
 
func _make_overlay() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 100
 
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)
 
	var label := Label.new()
	label.text = loading_text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layer.add_child(label)
 
	add_child(layer)
	return layer
 
