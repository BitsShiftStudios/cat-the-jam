extends CharacterBody3D

@export var MOUSE_SENSITIVITY = 0.005

@export var JUMP_VELOCITY = 4.5

@export var LEANING_POSITION_OFFSET = 0.2
@export var LEANING_ROTATION_DEGREES = 6.0
var leaning_check = false

# SKIN
@export var equipped_skinpack: String = "default"

# Animation
#@onready var anim_player: AnimationPlayer = $"Node3D/ct idle/AnimationPlayer"
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
@export var SPEED_NORMAL = 5.0
@export var SPEED_RUN = 8.0
@export var SPEED_LEANING = 3.0
@export var SPEED_CROUCH = 3.0
var SPEED = SPEED_NORMAL
#Speed


@onready var buy_menu = $BuyMenu
var current_weapon : base_weapon

##Fire System
@onready var camera = $Neck/Head/CameraShaker/Camera3D


@onready var ak47 = $Neck/Head/WeaponPivot/ak47
@onready var m4a4 = $Neck/Head/WeaponPivot/m4a4

var is_trying_to_fire = false
## 0 == IDLE
## 1 == WALKING
## 2 == RUNNING
## 3 == JUMPING
## 4 == CROUCHING
## 5 == LEAN LEFT
## 6 == LEAN RIGHT
@export var player_status: int = 0

var leaning_left: bool = false
var leaning_right: bool = false

##Fire System

var collider : Object

var snip_aim = false
@onready var def_camera_fov = camera.fov


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

#region HURTBOX_VARIABLE
@onready var head_hurtbox = $"Node3D/ct idle/ct_t_pose/Skeleton3D/HeadAttachment/HeadHurtbox"
@onready var upper_boddy_hurtbox = $"Node3D/ct idle/ct_t_pose/Skeleton3D/UpperBodyAttachment/BodyHurtbox"
@onready var lower_boddy_hurtbox = $"Node3D/ct idle/ct_t_pose/Skeleton3D/LowerBodyAttachment/LowerBodyHurtbox"
@onready var left_arm_hurtbox = $"Node3D/ct idle/ct_t_pose/Skeleton3D/LeftArmAttachment/LeftArmHurtbox"
@onready var left_fore_hurtbox = $"Node3D/ct idle/ct_t_pose/Skeleton3D/LeftForeArmAttachment/LeftForeArmHurtbox"
@onready var left_hand_hurtbox = $"Node3D/ct idle/ct_t_pose/Skeleton3D/LeftHandAttachment/LeftHandHurtbox"
@onready var right_arm_hurtbox =  $"Node3D/ct idle/ct_t_pose/Skeleton3D/RightArmAttachment/RightArmHurtbox"
@onready var right_fore_arm_hurtbox = $"Node3D/ct idle/ct_t_pose/Skeleton3D/RightForeArmAttachment/RightForeArmHurtbox"
@onready var right_hand_hurtbox =  $"Node3D/ct idle/ct_t_pose/Skeleton3D/RightHandAttachment/RightHandHurtbox"
@onready var left_leg_hurtbox =  $"Node3D/ct idle/ct_t_pose/Skeleton3D/LeftLegAttachment/LeftLegHurtbox"
@onready var left_upper_leg_hurtbox =  $"Node3D/ct idle/ct_t_pose/Skeleton3D/LeftUpLegAttachment/LeftUpLegHurtbox"
@onready var left_foot_hurtbox =  $"Node3D/ct idle/ct_t_pose/Skeleton3D/LeftFootAttachment/LeftFootHurtbox"
@onready var right_leg_hurtbox =  $"Node3D/ct idle/ct_t_pose/Skeleton3D/RightLegAttachment/RightLegHurtbox"
@onready var right_upper_leg_hurtbox =  $"Node3D/ct idle/ct_t_pose/Skeleton3D/RightUpLegAttachment/RightUpLegHurtbox"
@onready var right_foot_hurtbox =  $"Node3D/ct idle/ct_t_pose/Skeleton3D/RightFootAttachment/RightFootHurtbox"
#endregion

#region SOUND_SETTINGS
@export_category("Sound Settings")
@export var weapon_sound_file: AudioStream = null
@export var walk_sound_file: AudioStream = null
var fire_sound
var walk_sound
#endregion

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
		## Kamera default olarak falsex
		## Bunu true yapmamız lazım
		$Neck/Head/CameraShaker/Camera3D.current = true
		
func _ready():
	if not is_node_ready():
		await ready
	$"Node3D/ct idle/ct_t_pose/AnimationTree".active = true
	await get_tree().process_frame 
	if is_multiplayer_authority():
		collision_layer = 2
		
		head_hurtbox.collision_layer = 8
		upper_boddy_hurtbox.collision_layer = 8 
		lower_boddy_hurtbox.collision_layer = 8 
		
		left_arm_hurtbox.collision_layer = 8 
		left_fore_hurtbox.collision_layer = 8 
		left_hand_hurtbox.collision_layer = 8 
		
		right_arm_hurtbox.collision_layer = 8 
		right_hand_hurtbox.collision_layer = 8 
		right_fore_arm_hurtbox.collision_layer = 8
		
		left_leg_hurtbox.collision_layer = 8 
		left_upper_leg_hurtbox.collision_layer = 8
		left_foot_hurtbox.collision_layer = 8 
		
		right_leg_hurtbox.collision_layer = 8 
		right_upper_leg_hurtbox.collision_layer = 8
		right_foot_hurtbox.collision_layer = 8
		
		collision_mask = 1 + 4
		
		$"Node3D/ct idle".hide()
		$Label3D.hide() # Veya $Label3D.visible = false
		$Neck/Head/CameraShaker/Camera3D.make_current()
		buy_menu.visible = false
	else:
		collision_layer = 4
		
		head_hurtbox.collision_layer = 16
		upper_boddy_hurtbox.collision_layer = 16 
		lower_boddy_hurtbox.collision_layer = 16
		
		left_arm_hurtbox.collision_layer = 16
		left_fore_hurtbox.collision_layer = 16 
		left_hand_hurtbox.collision_layer = 16
		
		right_arm_hurtbox.collision_layer = 16
		right_hand_hurtbox.collision_layer = 16 
		right_fore_arm_hurtbox.collision_layer = 16
		
		left_leg_hurtbox.collision_layer = 16
		left_upper_leg_hurtbox.collision_layer = 16
		left_foot_hurtbox.collision_layer = 16
		
		right_leg_hurtbox.collision_layer = 16
		right_upper_leg_hurtbox.collision_layer = 16
		right_foot_hurtbox.collision_layer = 16

		collision_mask = 1 + 2
		# Bu karakter ağdaki başka biriyse yazıyı açık tut
		$Label3D.show()
		if buy_menu != null:
			buy_menu.visible = false
			buy_menu.set_process(false)
	$Label3D.text = PlayerData["login"]
	switch_weapon(0)
	#print(current_weapon)
	
	neck_org_position = $Neck.position
	neck_crouched_position_y = neck_org_position.y - 0.7
	test_face_c_pos_y = test_face.y - 0.7
	
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
		
	# Skins
	if (get_multiplayer_authority() % 2 == 1):
		equipped_skinpack = "gold"
	apply_weapon_skin()
	create_audio3d_node() # Create audio nodes 
	
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if !match_controller.match_active:
		return
		
	if not is_on_floor():
		velocity += get_gravity() * delta

	if PlayerData.is_chatting:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return
	
	#region LEANING_MECHANIC
	## Character Leaning -----------
	if Input.is_action_pressed("leaning_right") and not Input.is_action_pressed("leaning_left"):
		leaning_check = true
		leaning_chracter("leaning_right", delta)
		play_leaning_animation("leaning_right") # This func play leaning animation.
	elif Input.is_action_pressed("leaning_left") and not Input.is_action_pressed("leaning_right"):
		leaning_check = true
		leaning_chracter("leaning_left", delta)
		play_leaning_animation("leaning_left") # This func play leaning animation.
	elif not Input.is_action_pressed("leaning_left") and not Input.is_action_pressed("leaning_right"):
		leaning_check = false
		leaning_chracter("default", delta)
		play_leaning_animation("default") # This func play leaning animation.
	## Character Leaning -----------
	#endregion
	
	#region ANIMATION_TREE
	var local_velocity = global_transform.basis.inverse() * velocity
	var blend_pos = Vector2(local_velocity.x, -local_velocity.z)
	var animation_tree_node = $"Node3D/ct idle/ct_t_pose/AnimationTree"
	animation_tree_node.set("parameters/Movement/blend_position", blend_pos)
	
	if Input.is_action_just_pressed("ui_accept"):
		animation_tree_node.set("parameters/Transition/transition_request", "1")
	elif not is_on_floor() and  animation_tree_node["parameters/Transition/current_state"] == "0":
		animation_tree_node.set("parameters/Transition/transition_request", "1")
		animation_tree_node.set("parameters/jump_fall_blend/blend_amount", lerp(animation_tree_node["parameters/jump_fall_blend/blend_amount"], 1.0, 20.0 * delta))
	elif is_on_floor():
		animation_tree_node.set("parameters/jump_fall_blend/blend_amount", lerp(animation_tree_node["parameters/jump_fall_blend/blend_amount"], 0.0, 20.0 * delta))
		animation_tree_node.set("parameters/Transition/transition_request", "0")
	
	#endregion ANIMATION_TREE

	#region GUN_MENU
	if Input.is_action_just_pressed("buy_menu"):
		toggle_buy_menu()
	if buy_menu.visible == true:
		snip_aim = false
		$Neck/Head/CameraShaker/Camera3D.fov = lerp($Neck/Head/CameraShaker/Camera3D.fov, def_camera_fov, 15.0 * delta)
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return
	#endregion

	#region MOVE_PHYSIC
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
	#endregion


	#region SNIPER_ZOOM
	if Input.is_action_just_pressed("aim") and current_weapon.name == "snip":
		snip_aim = !snip_aim
	if snip_aim == true:
		$Neck/Head/CameraShaker/Camera3D.fov = lerp($Neck/Head/CameraShaker/Camera3D.fov, 30.0, 15.0 * delta)
	if snip_aim == false:
		$Neck/Head/CameraShaker/Camera3D.fov = lerp($Neck/Head/CameraShaker/Camera3D.fov, def_camera_fov, 15.0 * delta)
	#endregion
	
	#region SETTINGS_MENU
	if Input.is_action_just_pressed("puase_game"):
		if mouse_capture == 1:
			mouse_capture = 0
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			mouse_capture = 1
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#endregion
	
	#region CHRACTER_CROUCH_CONTROLLER
	##This block for character_position func.
	#if True chracter crouch, if is false, character stand
	if Input.is_action_pressed("crouch"):
		check = true
	elif not $ControlUpperHead.is_colliding():
		check = false
	character_position(check, delta) #Crouch or Stand
	#endregion
	
	#region CHRACTER_SPEED_CONTROLLER
	## Chracter Speed - status
	if Input.is_action_pressed("run") and check == false and (!Input.is_action_pressed("leaning_right") and !Input.is_action_pressed("leaning_left")):
		SPEED = SPEED_RUN
	elif check == true or (Input.is_action_pressed("leaning_right") or Input.is_action_pressed("leaning_left")):
		SPEED = SPEED_CROUCH
	else:
		SPEED = SPEED_NORMAL
	## Chracter Speed - status
	#endregion
	
	
	#region WEAPON_FIRE
	##Fire Gun
	if current_weapon.is_automatic:
		is_trying_to_fire = Input.is_action_pressed("fire")
	else:
		is_trying_to_fire = Input.is_action_just_pressed("fire")
		
	if is_trying_to_fire and current_weapon.gun_is_reloading != true:
		if current_weapon.fire(delta, camera, player_status):
			$Neck/Head/CameraShaker/Camera3D.v_offset = lerp($Neck/Head/CameraShaker/Camera3D.v_offset, 0.2, 0.1)
			$Neck/Head/CameraShaker/Camera3D.h_offset = lerp($Neck/Head/CameraShaker/Camera3D.h_offset, 0.1, 0.1)
			var muzzle_node = current_weapon.get_node("AssaultRIfle_01_Cube_002/Muzzle")
			var muzzle_glob_pos = muzzle_node.global_position
			var player_id = get_parent().name
			rpc("play_fire_sound", muzzle_glob_pos, player_id)
		else:
			$Neck/Head/CameraShaker/Camera3D.v_offset = lerp($Neck/Head/CameraShaker/Camera3D.v_offset, 0.0, 0.1)
			$Neck/Head/CameraShaker/Camera3D.h_offset = lerp($Neck/Head/CameraShaker/Camera3D.h_offset, 0.0, 0.1)
	elif $Neck/Head/CameraShaker/Camera3D.v_offset != 0.0:
		$Neck/Head/CameraShaker/Camera3D.v_offset = lerp($Neck/Head/CameraShaker/Camera3D.v_offset, 0.0, 0.1)
		$Neck/Head/CameraShaker/Camera3D.h_offset = lerp($Neck/Head/CameraShaker/Camera3D.h_offset, 0.0, 0.1)
	##Fire Gun
	#endregion
	
	
	#region WEAPON_RELOAD
	##Reload
	if Input.is_action_just_pressed("reload") and current_weapon.gun_is_reloading != true:
		current_weapon.gun_is_reloading = true # Gun Reload Checker
		current_weapon.reload()
	##Reload
	#endregion
		
	#region PLAYER_CAMERA_SHAKE
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
	#endregion
	
	
	
	#print(SPEED)
	## Character Control Mechanics
	take_player_status(input_dir)
	move_and_slide()
	

func play_leaning_animation(animation_name):
	var animation_tree_node = $"Node3D/ct idle/ct_t_pose/AnimationTree"
	if animation_name == "leaning_left":
		animation_tree_node.set("parameters/Blend2/blend_amount", 0.5)
		animation_tree_node.set("parameters/Leaning/blend_position", -1.0)
	elif animation_name == "leaning_right":
		animation_tree_node.set("parameters/Blend2/blend_amount", 0.5)
		animation_tree_node.set("parameters/Leaning/blend_position", 1.0)
	elif animation_name == "default":
		animation_tree_node.set("parameters/Blend2/blend_amount", 0.0)
		animation_tree_node.set("parameters/Leaning/blend_position", 0.0)

func apply_weapon_skin() -> void:
	var ak47_mesh: MeshInstance3D = $Neck/Head/WeaponPivot/ak47/AssaultRIfle_01_Cube_002
	var m4a4_mesh: MeshInstance3D = $Neck/Head/WeaponPivot/m4a4/AssaultRifle2_1

	match equipped_skinpack:
		"gold":
			var m4a1_mat = preload("res://assets/materials/guns/M4A1/M4A1_gold.tres")
			var ak47_mat = preload("res://assets/materials/guns/M4A1/M4A1_gold.tres")
			m4a4_mesh.set_surface_override_material(0, m4a1_mat)
			ak47_mesh.set_surface_override_material(0, ak47_mat)
		_:
			ak47_mesh.set_surface_override_material(0, null)
			m4a4_mesh.set_surface_override_material(0, null)
	
func _process(delta: float) -> void:
	if is_multiplayer_authority():
		return
	
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
	refill_all_weapons()

func refill_all_weapons():
	var weapon_pivot = $Neck/Head/WeaponPivot
	
	for weapon in weapon_pivot.get_children():
		if weapon.has_method("bullet_reset"):
			weapon.bullet_reset()
		if weapon.has_method("abort_reloading"):
			weapon.abort_reloading()
	if current_weapon != null:
		current_weapon.update_hud_ammo_info()

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

func switch_weapon(weapon_index: int):
	var weapon_pivot = $Neck/Head/WeaponPivot
	if weapon_index < 0 or weapon_index >= weapon_pivot.get_child_count():
		return
	for child in weapon_pivot.get_children():
		child.visible = false
	var selected_weapon = weapon_pivot.get_child(weapon_index)
	selected_weapon.visible = true
	check_and_abort_reload()
	current_weapon = selected_weapon
	current_weapon.update_hud_ammo_info()

func check_and_abort_reload():
	if current_weapon == null:
		return
	if current_weapon.gun_is_reloading == true:
		current_weapon.abort_reloading()
	else:
		return



#region SOUND
func create_audio3d_node():
	fire_sound = AudioStreamPlayer3D.new()
	walk_sound = AudioStreamPlayer3D.new()
	
	fire_sound.name = "GunSoundPlayer3D"
	walk_sound.name = "WalkSoundPlayer3D"
	
	fire_sound.stream = weapon_sound_file
	fire_sound.top_level = true
	fire_sound.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	fire_sound.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	fire_sound.volume_db = 0.0
	fire_sound.max_polyphony = 3
	fire_sound.max_distance = 40.0
	
	walk_sound.stream = walk_sound_file
	
	add_child(fire_sound)
	add_child(walk_sound)


@rpc("any_peer", "call_local", "unreliable", 0)
func play_fire_sound(muzzle_global_pos: Vector3, player_id):
	var full_path = "/root/Node/" + player_id + "/Player/GunSoundPlayer3D"
	var player_audio_node = get_node(full_path)
	player_audio_node.global_position = muzzle_global_pos
	player_audio_node.play()
	print("--- SES TETİKLENDİ ---")
	print("Sesi Çalan Düğüm: ", player_id)
#endregion



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
	#elif leaning_left:
		#player_status = 5
	#elif leaning_right:
		#player_status = 6
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
		$Taban.scale.y = lerp($Taban.scale.y, 0.7, 15.0 * delta)
		$ShapeCast3D.position.y = neck_crouched_position_y
		var test = $CollisionShape3D.shape
		test.height = lerp(test.height, 1.4, 10.0 * delta)
		$CollisionShape3D.position.y = lerp($CollisionShape3D.position.y, 0.7, 10.0 * delta)
	else:
		$Neck.position.y = lerp($Neck.position.y, neck_org_position.y, 15.0 * delta)
		$ShapeCast3D.position.y = neck_org_position.y
		$Taban.scale.y = lerp($Taban.scale.y, 1.0, 15.0 * delta)
		var test = $CollisionShape3D.shape
		test.height = lerp(test.height, 2.0, 10.0 * delta)
		$CollisionShape3D.position.y = lerp($CollisionShape3D.position.y, 1.0, 10.0 * delta)
		
		
func leaning_chracter(pressed_key_name, delta):
	if not is_multiplayer_authority():
		return

	if pressed_key_name == "leaning_right":
		leaning_left = false
		leaning_right = true
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
		leaning_left = true
		leaning_right = false
		$ShapeCast3D.target_position.x = -5.0
		var shape_value = $ShapeCast3D.get_closest_collision_safe_fraction()
		if shape_value > LEANING_POSITION_OFFSET:
			$Neck.position.x = lerp($Neck.position.x, -LEANING_POSITION_OFFSET, 17.0 * delta) # value must be -(negative)
			$Neck.rotation_degrees.z = lerp($Neck.rotation_degrees.z, LEANING_ROTATION_DEGREES, 10.0 * delta) #value must be +(positive)
		else:
			$Neck.position.x = lerp($Neck.position.x, -shape_value, 17.0 * delta) # value must be -(negative)
			$Neck.rotation_degrees.z = lerp($Neck.rotation_degrees.z, LEANING_ROTATION_DEGREES, 10.0 * delta) #value must be +(positive)
	else:
		leaning_left = false
		leaning_right = false
		$Neck.position.x = lerp($Neck.position.x, 0.0, 17.0 * delta)
		$Neck.rotation_degrees.z = lerp($Neck.rotation_degrees.z, 0.0, 10.0 * delta)


func _input(event):
	if not is_multiplayer_authority() or buy_menu.visible == true:
		return
	if !match_controller.match_active:
		return
	if !match_controller.match_active:
		return


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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# ESC tuşuna (ui_cancel) basılırsa fareyi serbest bırak ve görünür yap
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Mouse in viewport coordinates.


func _on_m_4a_4_pressed() -> void:
	switch_weapon(1)
	toggle_buy_menu()

func _on_ak_47_pressed() -> void:
	switch_weapon(0)
	toggle_buy_menu()

func _on_snip_pressed() -> void:
	switch_weapon(2)
	toggle_buy_menu()
