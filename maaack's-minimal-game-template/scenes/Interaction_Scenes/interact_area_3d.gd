class_name InteractionArea3D
extends Area3D
 
@export var action_name: String = "interact"
 
var interact: Callable = func() -> void:
	pass
 
 
func _ready() -> void:
	# Safe even if the signals were also connected in the editor.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
 
 
func _exit_tree() -> void:
	# Areas freed by a scene change never emit body_exited.
	InteractionManager3d.unregister_area(self)
 
 
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		InteractionManager3d.register_area(self)
 
 
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		InteractionManager3d.unregister_area(self)
 
