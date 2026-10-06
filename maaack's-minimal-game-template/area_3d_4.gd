extends Area3D

@onready var light = $OmniLight3D4

func _on_body_entered(body):
	if body.name == "Player":
		light.visible = true
