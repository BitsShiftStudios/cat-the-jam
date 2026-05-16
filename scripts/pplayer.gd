extends CharacterBody3D

@export var MOUSE_SENSITIVITY = 0.005

@export var JUMP_VELOCITY = 4.5

@export var LEANING_POSITION_OFFSET = 0.4
@export var LEANING_ROTATION_DEGREES = 6.0

#Speed
@export_group("Speed settings")
var SPEED
@export var SPEED_NORMAL = 5.0
@export var SPEED_RUN = 8.0
@export var SPEED_LEANING = 3.0
@export var SPEED_CROUCH = 3.0
#Speed


##Fire System
@onready var camera = $Neck/Head/CameraShaker/Camera3D
@onready var ak47 = $Neck/Head/WeaponPivot/ak47
@onready var hud_node = $hud
## 0 == IDLE
## 1 == WALKING
## 2 == RUNNING
## 3 == JUMPING
## 4 == CROUCHING
var player_status = 0

##Fire System

var collider : Object

var neck_org_position : Vector3
var test_face : Vector3
var test_face_c_pos_y
var neck_crouched_position_y

#Crouch
var check
#Crouch

#Camera Shake
var t = 0.0
var wave_rate = 0.0

var mouse_capture = 1

func _enter_tree():
	var player_id = get_parent().name.to_int()
	print("Player ID: ", player_id)
	set_multiplayer_authority(player_id)
	$MultiplayerSynchronizer.set_multiplayer_authority(player_id)
	
	if not is_multiplayer_authority():
		$Neck/Head/CameraShaker/Camera3D.current = false
		set_process_input(false)
		set_physics_process(false)
	else:
		## Kamera default olarak false
		## Bunu true yapmamız lazım
		$Neck/Head/CameraShaker/Camera3D.current = true

func _ready():
	if not is_multiplayer_authority():
		return

	neck_org_position = $Neck.position
	neck_crouched_position_y = neck_org_position.y - 0.7
	test_face = $testface.position
	test_face_c_pos_y = test_face.y - 0.7
	
	
	SPEED = SPEED_NORMAL
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	
	$ShapeCast3D.add_exception(self)	# Cast'in içinde olduğu node daki hiç bir nesneye sinyal almamaya yarıyor
	$ControlUpperHead.add_exception(self)
	
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
			
	## Character Control Mechanics
	
	if Input.is_action_just_pressed("puase_game"):
		if mouse_capture == 1:
			mouse_capture = 0
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			mouse_capture = 1
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	## Character Leaning -----------
	if Input.is_action_pressed("leaning_right"):
		leaning_chracter("leaning_right", delta)
	elif Input.is_action_pressed("leaning_left"):
		leaning_chracter("leaning_left", delta)
	else:
		leaning_chracter("default", delta)
	## Character Leaning -----------
	
		
	##This block for character_position func.
	#if True chracter crouch, if is false, character stand
	if Input.is_action_pressed("crouch"):
		check = true
	elif not $ControlUpperHead.is_colliding():
		check = false
	character_position(check, delta) #Crouch or Stand
	
	## Chracter Speed - status
	if Input.is_action_pressed("run") and check == false and (!Input.is_action_pressed("leaning_right") and !Input.is_action_pressed("leaning_left")):
		SPEED = SPEED_RUN
	elif check == true or (Input.is_action_pressed("leaning_right") or Input.is_action_pressed("leaning_left")):
		SPEED = SPEED_CROUCH
	else:
		SPEED = SPEED_NORMAL
	## Chracter Speed - status
	
	##Fire Gun
	
	if Input.is_action_pressed("fire"):
		if ak47.fire(delta, hud_node, camera, player_status):
			$Neck/Head/CameraShaker/Camera3D.v_offset = lerp($Neck/Head/CameraShaker/Camera3D.v_offset, 0.2, 0.1)
			$Neck/Head/CameraShaker/Camera3D.h_offset = lerp($Neck/Head/CameraShaker/Camera3D.h_offset, 0.1, 0.1)
		else:
			$Neck/Head/CameraShaker/Camera3D.v_offset = lerp($Neck/Head/CameraShaker/Camera3D.v_offset, 0.0, 0.1)
			$Neck/Head/CameraShaker/Camera3D.h_offset = lerp($Neck/Head/CameraShaker/Camera3D.h_offset, 0.0, 0.1)
	elif $Neck/Head/CameraShaker/Camera3D.v_offset != 0.0:
		$Neck/Head/CameraShaker/Camera3D.v_offset = lerp($Neck/Head/CameraShaker/Camera3D.v_offset, 0.0, 0.1)
		$Neck/Head/CameraShaker/Camera3D.h_offset = lerp($Neck/Head/CameraShaker/Camera3D.h_offset, 0.0, 0.1)
	##Fire Gun
	
	##Reload
	if Input.is_action_just_pressed("reload"):
		ak47.reload()
	##Reload
		
	#Camera Shake
	var target_wave_rate = 0.0
	if (!direction):
		target_wave_rate = 0.01
		t = t + (delta * 1.0)
	else:
		target_wave_rate = 0.05
		t = t + (delta * Vector2(velocity.x, velocity.z).length())	
	wave_rate = lerp(wave_rate, target_wave_rate, 10.0 * delta)
	$Neck/Head/CameraShaker/Camera3D.position.y = wave_rate * sin(2.0 * t)
	$Neck/Head/CameraShaker/Camera3D.position.x = wave_rate * cos(1.0 * t)
	#Camera Shake
	
	#print(SPEED)
	## Character Control Mechanics
	take_player_status(input_dir)
	move_and_slide()

func take_player_status(input_dir):
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		player_status = 3
	elif SPEED == SPEED_RUN:
		player_status = 2
	elif SPEED == SPEED_CROUCH:
		player_status = 4
	elif SPEED == SPEED_NORMAL and input_dir:
		player_status = 1
	elif !input_dir:
		player_status = 0

func character_position(check, delta):
	if not is_multiplayer_authority():
		return

	if check:
		$Neck.position.y = lerp($Neck.position.y, neck_crouched_position_y, 15.0 * delta)
		$testface.position.y = lerp($testface.position.y, test_face_c_pos_y, 15.0 * delta)
		$Taban.scale.y = lerp($Taban.scale.y, 0.7, 15.0 * delta)
		$ShapeCast3D.position.y = neck_crouched_position_y
		var test = $CollisionShape3D.shape
		test.height = lerp(test.height, 1.4, 10.0 * delta)
		$CollisionShape3D.position.y = lerp($CollisionShape3D.position.y, 0.7, 10.0 * delta)
	else:
		$Neck.position.y = lerp($Neck.position.y, neck_org_position.y, 15.0 * delta)
		$ShapeCast3D.position.y = neck_org_position.y
		$testface.position.y = lerp($testface.position.y, test_face.y, 15.0 * delta)
		$Taban.scale.y = lerp($Taban.scale.y, 1.0, 15.0 * delta)
		var test = $CollisionShape3D.shape
		test.height = lerp(test.height, 2.0, 10.0 * delta)
		$CollisionShape3D.position.y = lerp($CollisionShape3D.position.y, 1.0, 10.0 * delta)
		
		
func leaning_chracter(pressed_key_name, delta):
	if not is_multiplayer_authority():
		return

	if pressed_key_name == "leaning_right":
		$ShapeCast3D.target_position.x = 5.0
		$ShapeCast3D.force_shapecast_update()
		var shape_value = $ShapeCast3D.get_closest_collision_safe_fraction()
		if shape_value > LEANING_POSITION_OFFSET:
			$Neck.position.x = lerp($Neck.position.x, LEANING_POSITION_OFFSET, 17.0 * delta) # value must be -(negative)
			$Neck.rotation_degrees.z = lerp($Neck.rotation_degrees.z, -LEANING_ROTATION_DEGREES, 10.0 * delta) #value must be +(positive)
		else:
			$Neck.position.x = lerp($Neck.position.x, shape_value, 17.0 * delta)
			$Neck.rotation_degrees.z = lerp($Neck.rotation_degrees.z, -LEANING_ROTATION_DEGREES, 10.0 * delta) #value must be +(positive)
	elif pressed_key_name == "leaning_left":
		$ShapeCast3D.target_position.x = -5.0
		var shape_value = $ShapeCast3D.get_closest_collision_safe_fraction()
		if shape_value > LEANING_POSITION_OFFSET:
			$Neck.position.x = lerp($Neck.position.x, -LEANING_POSITION_OFFSET, 17.0 * delta) # value must be -(negative)
			$Neck.rotation_degrees.z = lerp($Neck.rotation_degrees.z, LEANING_ROTATION_DEGREES, 10.0 * delta) #value must be +(positive)
		else:
			$Neck.position.x = lerp($Neck.position.x, -shape_value, 17.0 * delta) # value must be -(negative)
			$Neck.rotation_degrees.z = lerp($Neck.rotation_degrees.z, LEANING_ROTATION_DEGREES, 10.0 * delta) #value must be +(positive)
	else:
		$Neck.position.x = lerp($Neck.position.x, 0.0, 17.0 * delta)
		$Neck.rotation_degrees.z = lerp($Neck.rotation_degrees.z, 0.0, 10.0 * delta)

func _input(event):
	if not is_multiplayer_authority():
		return

	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		pass
	elif event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		if $Neck/Head.rotation_degrees.x < 90 and $Neck/Head.rotation_degrees.x > -90:
			$Neck/Head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		if $Neck/Head.rotation_degrees.x >= 90 and event.relative.y > 0:
			$Neck/Head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		if $Neck/Head.rotation_degrees.x <= -90 and event.relative.y < 0:
			$Neck/Head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	# Print the size of the viewport.
