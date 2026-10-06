class_name DetectionMeter
extends Node3D
signal detected

@export var fov: EnemyFOV

@export_group("Timing")
@export var max_time: float = 2.0
@export var drain_rate: float = 0.5

@export_group("Bar")
@export var bar_size: Vector2 = Vector2(1.0, 0.12)
@export var background_color: Color = Color(0.0, 0.0, 0.0, 0.6)
@export var start_color: Color = Color(1.0, 0.9, 0.2)
@export var full_color: Color = Color(1.0, 0.1, 0.1)
@export var hide_when_empty: bool = true
@export var visible_through_walls: bool = true

var time_in_view: float = 0.0

const TEX_W := 100

var _tex_h: int = 10
var _background: Sprite3D
var _fill: Sprite3D
var _has_detected: bool = false


func _ready() -> void:
	if fov == null:
		fov = _find_fov()
	if fov == null:
		push_warning("DetectionMeter: no EnemyFOV assigned or found.")

	_tex_h = maxi(1, roundi(TEX_W * bar_size.y / bar_size.x))
	var image := Image.create(TEX_W, _tex_h, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)

	_background = _make_sprite(texture, 0)
	_background.modulate = background_color
	_fill = _make_sprite(texture, 1)

	_update_bar()


func _process(delta: float) -> void:
	if fov == null:
		return

	if fov.is_player_inside():
		time_in_view += delta
	else:
		time_in_view -= delta * drain_rate
	time_in_view = clampf(time_in_view, 0.0, max_time)

	if time_in_view >= max_time and not _has_detected:
		_has_detected = true
		detected.emit()
	elif time_in_view <= 0.0:
		_has_detected = false

	_update_bar()


func get_progress() -> float:
	return time_in_view / max_time

func reset() -> void:
	time_in_view = 0.0
	_has_detected = false
	_update_bar()


func _find_fov() -> EnemyFOV:
	var parent := get_parent()
	if parent == null:
		return null
	if parent is EnemyFOV:
		return parent
	for child in parent.get_children():
		if child is EnemyFOV:
			return child
	return null


func _make_sprite(texture: Texture2D, priority: int) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.double_sided = true
	sprite.no_depth_test = visible_through_walls
	sprite.render_priority = priority
	sprite.pixel_size = bar_size.x / TEX_W
	sprite.centered = false
	sprite.offset = Vector2(-TEX_W / 2.0, -_tex_h / 2.0)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, TEX_W, _tex_h)
	add_child(sprite)
	return sprite


func _update_bar() -> void:
	if _fill == null:
		return
	var progress := get_progress()
	visible = not hide_when_empty or time_in_view > 0.0
	_fill.visible = progress > 0.0
	if progress > 0.0:
		_fill.region_rect = Rect2(0, 0, TEX_W * progress, _tex_h)
		_fill.modulate = start_color.lerp(full_color, progress)
