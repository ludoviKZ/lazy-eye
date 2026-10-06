extends Area3D

@onready var light = $OmniLight3D

func _on_body_entered(body):
	if body.name == "Player":
		light.visible = true
