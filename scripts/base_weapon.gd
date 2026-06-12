class_name base_weapon
extends Node3D

@export var muzzle_flash : Node3D

@export_category("Gun Damage Options")
@export var body_damage : int
@export var leg_damage : int
@export var head_damage : int
@export var foot_damage : int

#region BODY_PART_ARRAY

var body_parts: Array[String] = ["LeftArmHurtbox", "LeftForeArmHurtbox", "LeftHandHurtbox", "RightArmHurtbox", "RightForeArmHurtbox", "RightHandHurtbox", "BodyHurtbox", "LowerBodyHurtbox"]
var leg_parts: Array[String] = ["LeftUpLegHurtbox", "LeftLegHurtbox", "RightUpLegHurtbox", "RightLegHurtbox"]
var head_parts: Array[String] = ["HeadHurtbox"]
var foot_parts: Array[String] = ["RightFootHurtbox", "LeftFootHurtbox"]
var all_body_parts: Array[Array] = [body_parts, leg_parts, head_parts, foot_parts]

#endregion

@export_category("Gun Options")
@export var gun_fire_speed : float 
@export var weapon_range : float
@export var is_automatic : bool

@export_category("Gun Ammo Settings")
@export var total_ammo_ui : int
@export var total_ammo_in_magazine_ui : int

@export_category("Gun Damage Options")
@export var body_damage : int
@export var leg_damage : int
@export var head_damage : int
@export var foot_damage : int

#region BODY_PART_ARRAY

var body_parts: Array[String] = ["LeftArmHurtbox", "LeftForeArmHurtbox", "LeftHandHurtbox", "RightArmHurtbox", "RightForeArmHurtbox", "RightHandHurtbox", "BodyHurtbox", "LowerBodyHurtbox"]
var leg_parts: Array[String] = ["LeftUpLegHurtbox", "LeftLegHurtbox", "RightUpLegHurtbox", "RightLegHurtbox"]
var head_parts: Array[String] = ["HeadHurtbox"]
var foot_parts: Array[String] = ["RightFootHurtbox", "LeftFootHurtbox"]
var all_body_parts: Array[Array] = [body_parts, leg_parts, head_parts, foot_parts]

#endregion

@export_category("Gun Options")
@export var gun_fire_speed : float 
@export var weapon_range : float
@export var is_automatic : bool

@export_category("Gun Ammo Settings")
@export var total_ammo_ui : int
@export var total_ammo_in_magazine_ui : int

@export_category("Gun Bullet Spread Values")
@export var default_bullet_spread_rate = 0.0
@export var default_bullet_spread_increase_rate = 0.5
@export var default_max_bullet_spread_rate = 4.0
@export var running_bullet_spread_increase_rate = 1.5
@export var crouch_bullet_spread_increase_rate = 0.1
@export var jump_bullet_spread_increase_rate = 1.9

@onready var bullet_hole_scene = preload("res://scenes/bullet_hole.tscn")

@onready var weapon_damage = 0

func fire_at_player(target_collider) -> void:
	var current_node = target_collider
	var target_network_id = 0
	
	while current_node != null:
		var node_name = current_node.name
		if node_name.is_valid_int():
			target_network_id = node_name.to_int()
			break
		current_node =  current_node.get_parent()
		
	var owner_player = self
	var found_owner: Node = null
	while owner_player != null:
		if owner_player.has_method("request_damage_from_player"):
			found_owner = owner_player
			break
		owner_player = owner_player.get_parent()
	if target_network_id > 0:
		if owner_player and owner_player.has_method("request_damage_from_player"):
			get_damage_modifier_zone(get_hit_body_part(target_collider))
			owner_player.request_damage_from_player(target_network_id, weapon_damage)
			
	#if name.is_valid_int():
		#var target_network_id = name.to_int()
		#var owner_player = get_owner().get_child(0)
		#if owner_player:
			#owner_player.request_damage_from_player(target_network_id, weapon_damage)

# Called when the node enters the scene tree for the first time.
func fire_base_weapon(weapon_range, delta, camera):
	muzzle_flash.fire_muzzle_flash()
	var result = create_raycast(camera, weapon_range)
	if !result:
		pass
	else:
		var target_collider = result.collider
		var target_normal = result.normal
		var target_position = result.position
		spawn_bullet_hole(target_collider, target_position, target_normal)
		rpc("sync_bullet_hole", target_collider.get_path(), target_position, target_normal)
		
		fire_at_player(target_collider)

@rpc("any_peer", "call_remote", "reliable")
func sync_bullet_hole(collider_path: NodePath, target_pos: Vector3, target_norm: Vector3):
	var target_collider = get_node_or_null(collider_path)
	if target_collider != null:
		spawn_bullet_hole(target_collider, target_pos, target_norm)
func spawn_bullet_hole(target_collider: Node, target_position: Vector3, target_normal: Vector3):
	if target_collider.name == "Player":
		return
	else:
		var hole = bullet_hole_scene.instantiate()
		hole.scale = Vector3(0.02, 0.02, 0.02)
		target_collider.add_child(hole)
		var safe_spawn_position = target_position + (target_normal * 0.02)
		hole.global_position = safe_spawn_position
		#hole.look_at(safe_spawn_position + target_normal, Vector3.DOWN)
		var down = Vector3.DOWN
		if target_normal.is_equal_approx(Vector3.UP) or target_normal.is_equal_approx(Vector3.DOWN):
			down = Vector3.FORWARD
		hole.look_at(safe_spawn_position + target_normal, down)
	
	# Yönünü ayarla (look_at normal pozisyonuna bakar, yani dışarıya)
	#hole.look_at(safe_spawn_position + target_normal, Vector3.DOWN)
	#hole.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
	
	
func create_raycast(camera, weapon_range) -> Dictionary:
	var viewport_center = get_viewport().get_visible_rect().size / 2.0
	var ray_origin = camera.project_ray_origin(viewport_center)
	var ray_normal = camera.project_ray_normal(viewport_center)
	var spread_x = randf_range(-0.4, 0.4) * default_bullet_spread_rate
	var spread_y = randf_range(-0.4, 0.4) * default_bullet_spread_rate
	ray_normal = ray_normal.rotated(camera.global_transform.basis.x, deg_to_rad(spread_x))
	ray_normal = ray_normal.rotated(camera.global_transform.basis.y, deg_to_rad(spread_y))
	var ray_end = ray_origin + (ray_normal * weapon_range)
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	query.collision_mask = 17
	query.collide_with_areas = true
	
	#query.exclude = [self.get_rid()]
	var space_status = get_world_3d().direct_space_state
	var result = space_status.intersect_ray(query)
	return result

func set_bullet_spread(bullet_spread_increase_rate):
	if default_max_bullet_spread_rate > default_bullet_spread_rate:
		default_bullet_spread_rate += bullet_spread_increase_rate

func restore_bullet_spread(delta):
	if default_bullet_spread_rate != 0.0:
		default_bullet_spread_rate = move_toward(default_bullet_spread_rate, 0.0, 3.0 * delta)

		
func get_hit_body_part(target_collider):
	if target_collider == null:
		return
	else:
		var hit_body_part_name = target_collider.name
		var i = 0
		var b = 0
		while i < all_body_parts.size():
			b = 0
			while b < all_body_parts[i].size():
				if all_body_parts[i][b] == hit_body_part_name:
					return i
				b += 1
			i += 1
	return -1

#region BODY_PART_NUMBER
#0 = BODY
#1 = LEG
#2 = HEAD
#3 = FOOT
#endregion
func get_damage_modifier_zone(body_part_number):
	if body_part_number == null:
		return
	else:
		match body_part_number:
			0:
				weapon_damage = body_damage
			1:
				weapon_damage = leg_damage
			2:
				weapon_damage = head_damage
			3:
				weapon_damage = foot_damage
			_:
				weapon_damage = 0
				print("Bilinmeyen Bölge - ERROR")
