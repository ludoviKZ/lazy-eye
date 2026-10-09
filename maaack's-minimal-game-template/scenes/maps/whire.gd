extends Node3D
@onready var interaction_area: InteractionArea3D = $InteractionArea3D

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	$"../SceneElements/CSGCylinder3D3".global_position.x += 100
	$"../SceneElements/RigidBody3D".gravity_scale = 1
	await get_tree().create_timer(1.6).timeout
	$AudioStreamPlayer3D.play()
	$"../beholder".die = true
