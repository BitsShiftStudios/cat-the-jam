# ServerCamera.gd — Camera3D'ye bağla
extends Camera3D

@export var speed: float = 10.0
@export var fast_speed: float = 30.0
@export var sensitivity: float = 0.003

var _active: bool = false

func _ready():
	call_deferred("_setup")

func _setup():
	if not multiplayer.is_server():
		return
	current = true
	_active = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var game_ui = $/root/Node/GameUI
	if game_ui:
		game_ui.visible = false

func _input(event):
	if not _active:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		rotate_object_local(Vector3.RIGHT, -event.relative.y * sensitivity)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if \
			Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
			else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if not _active or not multiplayer.is_server():
		return
	var move_speed = fast_speed if Input.is_key_pressed(KEY_SHIFT) else speed
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S): dir += global_transform.basis.z
	if Input.is_key_pressed(KEY_A): dir -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D): dir += global_transform.basis.x
	if Input.is_key_pressed(KEY_E): dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q): dir -= Vector3.DOWN
	global_position += dir.normalized() * move_speed * delta
