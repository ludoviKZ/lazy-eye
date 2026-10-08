extends Node3D
## Autoload. Shows "[E] to <action>" above the closest InteractionArea3D the
## player is standing in, and runs its `interact` callback when the
## "interact" input action is pressed.
## Scene: Node3D (this script) with a Label3D child named "Label3D".

const BASE_TEXT := "[E] to "
## How far above the area the label floats, in meters.
const LABEL_HEIGHT := 1.0

@onready var label: Label3D = $Label3D

var can_interact: bool = true
var active_areas: Array = []
var _player: Node3D


func _ready() -> void:
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # always faces the camera
	label.no_depth_test = true                          # visible through walls
	label.hide()


func register_area(area: InteractionArea3D) -> void:
	if not active_areas.has(area):
		active_areas.append(area)


func unregister_area(area: InteractionArea3D) -> void:
	active_areas.erase(area)


func _process(_delta: float) -> void:
	_prune_invalid_areas()

	if active_areas.is_empty() or not can_interact:
		label.hide()
		return

	active_areas.sort_custom(_is_closer)

	var target := active_areas[0] as InteractionArea3D
	label.text = BASE_TEXT + target.action_name
	label.global_position = target.global_position + Vector3.UP * LABEL_HEIGHT
	label.show()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if not can_interact or active_areas.is_empty():
		return

	can_interact = false
	label.hide()

	var area := active_areas[0] as InteractionArea3D
	await area.interact.call()
	can_interact = true


func _get_player() -> Node3D:
	# Looked up lazily: this autoload is ready before the level and the player
	# exist, and the player node changes whenever a scene is reloaded.
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player


func _is_closer(a: Node3D, b: Node3D) -> bool:
	var player := _get_player()
	if player == null:
		return false
	return player.global_position.distance_squared_to(a.global_position) \
		< player.global_position.distance_squared_to(b.global_position)


func _prune_invalid_areas() -> void:
	for i in range(active_areas.size() - 1, -1, -1):
		if not is_instance_valid(active_areas[i]):
			active_areas.remove_at(i)
