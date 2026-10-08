extends Node3D
@onready var interaction_area: InteractionArea3D = $InteractionArea3D

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	$"../SceneElements/window_metal_bars_single2".global_position.z += 8
	$InteractionArea3D.monitoring = false
	$AudioStreamPlayer3D.play()
