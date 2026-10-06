extends CharacterBody3D

 
@export var speed = 5.0
@export var crouch_speed = 2.5
@export var jump_velocity = 5.0
@export var gravity = 12.0
@export var sensitivity = 0.002
@export var crouch_height = 0.5
@export var standing_height = 1.0
@export var crouch_smoothness = 8.0

@onready var camera: Camera3D = get_node("Camera3D")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)

func _physics_process(delta):
	# Gravità
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# crouch
	var current_speed = speed
	var target_height = standing_height

	if Input.is_action_pressed("crouch"):
		
		current_speed = crouch_speed
		target_height = crouch_height
		$Hitbox.shape.height = 1 + crouch_height
	else:
		$Hitbox.shape.height = 1 + target_height

	camera.position.y = lerp(
		camera.position.y,
		target_height,
		crouch_smoothness * delta
	)

	# movimento
	var input = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	var direction = transform.basis * Vector3(input.x, 0, input.y)

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	if Input.is_action_pressed("ui_text_backspace"):
		get_tree().quit()
		
	move_and_slide()
