extends Node3D
@onready var interaction_area: InteractionArea3D = $InteractionArea3D

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	$"../SceneElements/StaticBody3D".global_position.y -= 11
	$"../SceneElements/Wood Stairs".global_position.y -= 11
	$InteractionArea3D.monitoring = false
	$AudioStreamPlayer3D.play()
