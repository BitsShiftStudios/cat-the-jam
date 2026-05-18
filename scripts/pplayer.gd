extends CharacterBody3D

@export var MOUSE_SENSITIVITY = 0.005

@export var JUMP_VELOCITY = 4.5

@export var LEANING_POSITION_OFFSET = 0.4
@export var LEANING_ROTATION_DEGREES = 6.0

# Animation
@onready var left_hand_ik = $"Node3D/ct idle/ct_t_pose/Skeleton3D/LeftHandIK"
@onready var right_hand_ik = $"Node3D/ct idle/ct_t_pose/Skeleton3D/RightHandIK"
@onready var skeleton: Skeleton3D = $"Node3D/ct idle/ct_t_pose/Skeleton3D"

var spine_bone_id: int = -1

#Health system
@onready var game_ui = $/root/Node/GameUI
@onready var match_controller = $/root/Node/MatchController
@export var health:int = 100

#Speed
@export_group("Speed settings")
var SPEED
@export var SPEED_NORMAL = 5.0
@export var SPEED_RUN = 8.0
@export var SPEED_LEANING = 3.0
@export var SPEED_CROUCH = 3.0
#Speed


@onready var buy_menu = $BuyMenu
var current_weapon : base_weapon

##Fire System
@onready var camera = $Neck/Head/CameraShaker/Camera3D


@onready var ak47 = $Neck/Head/WeaponPivot/ak47
@onready var m4a4 = $Neck/Head/WeaponPivot/m4a4


@onready var hud_node = $hud
var is_trying_to_fire = false
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
	add_to_group("players")
	
	if not is_multiplayer_authority():
		$Neck/Head/CameraShaker/Camera3D.current = false
		set_process_input(false)
		set_physics_process(false)
	else:
		## Kamera default olarak false
		## Bunu true yapmamız lazım
		$Neck/Head/CameraShaker/Camera3D.current = true
	
func _ready():
	
	if is_multiplayer_authority():
		# BİZİM KARAKTERİMİZ: Bizim menümüz var olsun ama kapalı dursun
		buy_menu.visible = false
	else:
		# DÜŞMAN KARAKTERİ: Kendi ekranımızda düşmanın arayüzünü tamamen yok edelim
		if buy_menu != null:
			buy_menu.queue_free()
	
	switch_weapon(1)
	print(current_weapon)
	
	neck_org_position = $Neck.position
	neck_crouched_position_y = neck_org_position.y - 0.7
	test_face = $testface.position
	test_face_c_pos_y = test_face.y - 0.7
	
	SPEED = SPEED_NORMAL
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	$ShapeCast3D.add_exception(self)	# Cast'in içinde olduğu node daki hiç bir nesneye sinyal almamaya yarıyor
	$ControlUpperHead.add_exception(self)
	
	game_ui.update_health_value(health)
	game_ui.update_health_display()
	
	# Animation
	left_hand_ik.start()
	right_hand_ik.start()
	if skeleton:
		spine_bone_id = skeleton.find_bone("mixamorig_Spine")
	
func _process(delta: float) -> void:
	if is_multiplayer_authority():
		return
	if skeleton and spine_bone_id != -1:
		tilt_torso()
	
func tilt_torso() -> void:
	var target_rotation = Quaternion(Vector3(1, 0, 0), $Neck/Head.rotation_degrees.x / -90.0)
	skeleton.set_bone_pose_rotation(spine_bone_id, target_rotation)
	
func add_health(amount: int, attacker_id: int) -> void:
	if not multiplayer.is_server():
		return
	if !match_controller.match_active:
		return

	health += amount
	var our_id = get_multiplayer_authority()
	rpc_id(our_id, "update_health_local", health)

	if health <= 0:
		match_controller.record_kill_death(attacker_id, our_id)		
		trigger_server_respawn()
	
func get_spawn_point() -> Vector3:
	var groups = get_tree().get_nodes_in_group("spawn_containers")
	
	if (groups.size() > 0):
		var spawn_container = groups[0]
		var spawn_points = spawn_container.get_children()
		
		if spawn_points.size() > 0:
			var rand = randi() % spawn_points.size()
			var random_spawn = spawn_points[rand]
			return random_spawn.global_position
			
	return Vector3(0, 3, 0)
	
func trigger_server_respawn() -> void:
	if not multiplayer.is_server():
		return		
		
	health = 100
	
	var owner_id = get_multiplayer_authority()
	rpc_id(owner_id, "update_health_local", health)
	var new_spawn_pos = get_spawn_point()
	rpc_id(owner_id, "teleport_client_to_spawn", new_spawn_pos)

@rpc("any_peer", "reliable")
func teleport_client_to_spawn(target_global_position: Vector3) -> void:
	velocity = Vector3.ZERO
	global_position = target_global_position
	reset_physics_interpolation() 
		
func request_damage_from_player(target_network_id: int, damage: int):
	rpc_id(1, "damage_request", target_network_id, damage)

@rpc("any_peer", "reliable")
func damage_request(victim_id: int, damage_amount: int):
	if not multiplayer.is_server():
		return
	if !match_controller.match_active:
		return
	
	var name = str(victim_id)
	var attacker_id = multiplayer.get_remote_sender_id()
	var victim_node = get_parent().get_parent().get_node_or_null(name).get_child(0)
	
	if victim_node:
		victim_node.add_health(-damage_amount, attacker_id)
		
@rpc("any_peer", "reliable")
func update_health_local(new_health_value: int):
	health = new_health_value
	game_ui.update_health_value(health)
	game_ui.update_health_display()
	
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if !match_controller.match_active:
		return	
	if Input.is_action_just_pressed("buy_menu"):
		toggle_buy_menu()
	if buy_menu.visible == true:
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
	if current_weapon.is_automatic:
		is_trying_to_fire = Input.is_action_pressed("fire")
	else:
		is_trying_to_fire = Input.is_action_just_pressed("fire")
	
	
	
	if is_trying_to_fire:
		if current_weapon.fire(delta, hud_node, camera, player_status):
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
		current_weapon.reload()
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


func switch_weapon(weapon_index: int):
	var weapon_pivot = $Neck/Head/WeaponPivot
	if weapon_index < 0 or weapon_index >= weapon_pivot.get_child_count():
		return
	for child in weapon_pivot.get_children():
		child.visible = false
	var selected_weapon = weapon_pivot.get_child(weapon_index)
	selected_weapon.visible = true
	current_weapon = selected_weapon

func toggle_buy_menu():
	buy_menu.visible = !buy_menu.visible
	
	if buy_menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	if not is_multiplayer_authority() or buy_menu.visible == true:
		return
	if !match_controller.match_active:
		return
	if !match_controller.match_active:
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


func _on_ak_47_pressed() -> void:
	switch_weapon(0)
	print(current_weapon)


func _on_m_4a_4_pressed() -> void:
	switch_weapon(1)
	print(current_weapon)
