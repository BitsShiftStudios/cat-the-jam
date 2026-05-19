class_name base_weapon
extends Node3D

@export var muzzle_flash : Sprite3D

@export_category("Gun Options")
@export var gun_fire_speed : float 
@export var weapon_range : float
@export var weapon_damage : int
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

func fire_at_player(target_collider) -> void:
	var name = target_collider.get_parent().name
	if name.is_valid_int():
		var target_network_id = name.to_int()
		var owner_player = get_owner().get_child(0)	
		if owner_player:
			owner_player.request_damage_from_player(target_network_id, weapon_damage)

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
