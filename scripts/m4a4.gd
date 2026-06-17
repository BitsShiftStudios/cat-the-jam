extends base_weapon

#Base_weapon Tüm silahlar için gerekli şeyleri getiriyor.

@onready var total_ammo = total_ammo_ui
@onready var total_ammo_in_magazine = total_ammo_in_magazine_ui
@onready var game_ui = $/root/Node/GameUI

@onready var gun_is_reloading = false
@export_category("Reload time settings")
@export var timer_node : Timer
@export var timer_wait_time : float
@export var timer_one_shot : bool
# Diğer mermiyi atana kadar geçecek süreyi hesaplayan değişken.
var fire_timer = 0.0


func _ready() -> void:
	timer_node.one_shot = timer_one_shot
	timer_node.wait_time = timer_wait_time


func _process(delta):
	# Sarsıntıyı otomatık olarak move toward ile düzelten fonksiyon
	restore_bullet_spread(delta)
	
	
	# Silah sürekli olarak kendi mermi bekleme süresini doldurur
	if fire_timer <= gun_fire_speed:
		fire_timer += delta
		
		
## Returns 1 or 0
## If returns 1, Gun fired
## if returns 0, gun was not fired 
func fire(delta, camera, player_status) -> int:
	if fire_timer >= gun_fire_speed and total_ammo_in_magazine > 0:
		total_ammo_in_magazine -= 1
		$AudioStreamPlayer3D.play()
		bullet_spread(player_status)
		fire_base_weapon(weapon_range, delta, camera)
		fire_timer = 0.0
		game_ui.update_ammo_display(total_ammo_in_magazine, total_ammo)
		#hud_node.change_current_ammo_info(total_ammo, total_ammo_in_magazine)
		return 1
	else:
		return 0

func reload():
	var difference_ammo_magazine = total_ammo_in_magazine_ui - total_ammo_in_magazine
	var reload_ammo_count = total_ammo - difference_ammo_magazine
	
	if gun_is_reloading == true:
		print("RELOADİNG")
		$ReloadTimer.start()
		return
	if reload_ammo_count >= 0:
		total_ammo_in_magazine += difference_ammo_magazine
		total_ammo = reload_ammo_count
	else:
		total_ammo_in_magazine += total_ammo
		total_ammo = 0
	
	game_ui.update_ammo_display(total_ammo_in_magazine, total_ammo)

## 

func bullet_reset():
	total_ammo = total_ammo_ui
	total_ammo_in_magazine = total_ammo_in_magazine_ui
	game_ui.update_ammo_display(total_ammo_in_magazine, total_ammo)

func bullet_spread(player_status):
	if player_status == 0: #Idle
		set_bullet_spread(default_bullet_spread_increase_rate)
	elif player_status == 1: #Walk
		set_bullet_spread(default_bullet_spread_increase_rate)
	elif player_status == 2: #Run
		set_bullet_spread(running_bullet_spread_increase_rate)
	elif player_status == 3: #Jump
		if default_max_bullet_spread_rate > default_bullet_spread_rate:
			default_bullet_spread_rate += 3.0
		set_bullet_spread(jump_bullet_spread_increase_rate)
	elif player_status == 4: #Crouch
		set_bullet_spread(crouch_bullet_spread_increase_rate)

func abort_reloading():
	print("ABORT RELOAD")
	timer_node.stop()
	timer_node.wait_time = timer_wait_time
	gun_is_reloading = false

func update_hud_ammo_info():
	game_ui.update_ammo_display(total_ammo_in_magazine, total_ammo)

func _on_reload_timer_timeout() -> void:
	print("RELOADING FİNİSH")
	gun_is_reloading = false
	reload()
