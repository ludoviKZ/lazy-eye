extends Node3D
@onready var interaction_area: InteractionArea3D = $InteractionArea3D

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	SceneLoader.load_scene("res://scenes/maps/wearhouse.tscn")
