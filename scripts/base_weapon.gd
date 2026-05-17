class_name base_weapon
extends Node3D

@export var muzzle_flash : Sprite3D

@export_category("Gun Bullet Spread Values")
@export var default_bullet_spread_rate = 0.0
@export var default_bullet_spread_increase_rate = 0.5
@export var default_max_bullet_spread_rate = 4.0
@export var running_bullet_spread_increase_rate = 1.5
@export var crouch_bullet_spread_increase_rate = 0.1
@export var jump_bullet_spread_increase_rate = 1.9

@onready var decal = preload("res://scenes/bullet_hole.tscn")

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
		var hole = decal.instantiate()
		var hole_node = hole.get_node("hole")
		#var particle = hole.get_node("GPUParticles3D")
		
		
		hole.scale = Vector3(0.5, 0.5, 0.5)
		target_collider.add_child(hole)
		hole.global_position = target_position
#		particle.global_position = target_position
		hole.look_at(target_position + target_normal, Vector3.DOWN)
		hole.rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
		
		

func set_bullet_spread(bullet_spread_increase_rate):
	if default_max_bullet_spread_rate > default_bullet_spread_rate:
		default_bullet_spread_rate += bullet_spread_increase_rate

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

func restore_bullet_spread(delta):
	if default_bullet_spread_rate != 0.0:
		default_bullet_spread_rate = move_toward(default_bullet_spread_rate, 0.0, 3.0 * delta)
